import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/farm_modules.dart';
import '../../../core/constants/firestore_collections.dart';
import '../models/dashboard_summary.dart';

class DashboardService {
  DashboardService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<DashboardSummary> load({required bool includeFinance}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final chartStart = today.subtract(const Duration(days: 6));
    final logbookStart = weekStart.isBefore(chartStart)
        ? weekStart
        : chartStart;
    final monthStart = DateTime(today.year, today.month);
    final nextMonth = DateTime(today.year, today.month + 1);

    final logbookFuture = _loadLogbookDocs(start: logbookStart, end: tomorrow);
    final inventoryCountFuture = _loadInventoryCount();
    final lowStockCountFuture = _loadLowStockCount();
    final lowStockPreviewFuture = _loadLowStockPreviewDocs();
    final todayScheduleCountFuture = _loadTodayScheduleCount(
      today: today,
      tomorrow: tomorrow,
    );
    final pendingScheduleCountFuture = _loadPendingScheduleCount();
    final overdueScheduleCountFuture = _loadOverdueScheduleCount(today: today);

    final financeFuture = includeFinance
        ? _loadFinanceSnapshot(monthStart: monthStart, nextMonth: nextMonth)
        : Future.value(null);

    final results = await Future.wait<Object?>([
      logbookFuture,
      inventoryCountFuture,
      lowStockCountFuture,
      lowStockPreviewFuture,
      todayScheduleCountFuture,
      pendingScheduleCountFuture,
      overdueScheduleCountFuture,
      financeFuture,
    ]);

    final logbookDocs =
        results[0] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
    final inventoryCount = results[1] as int;
    final lowStockCount = results[2] as int;
    final lowStockPreviewDocs =
        results[3] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
    final todayScheduleCount = results[4] as int;
    final pendingScheduleCount = results[5] as int;
    final overdueScheduleCount = results[6] as int;
    final financeDocs =
        results[7] as List<QueryDocumentSnapshot<Map<String, dynamic>>>?;

    final activityCounts = <DateTime, int>{
      for (var i = 0; i < 7; i++) chartStart.add(Duration(days: i)): 0,
    };
    final moduleCounts = <String, int>{
      for (final module in FarmModules.values) module.id: 0,
    };
    var todayLogbooks = 0;
    var weeklyLogbooks = 0;

    for (final document in logbookDocs) {
      final data = document.data();
      final timestamp = data['activityDate'];
      if (timestamp is! Timestamp) continue;

      final value = timestamp.toDate();
      final day = DateTime(value.year, value.month, value.day);
      if (day == today) todayLogbooks++;
      if (!day.isBefore(weekStart) && day.isBefore(tomorrow)) weeklyLogbooks++;
      if (activityCounts.containsKey(day)) {
        activityCounts[day] = activityCounts[day]! + 1;
      }

      final moduleType = data['moduleType'];
      if (moduleType is String && moduleCounts.containsKey(moduleType)) {
        moduleCounts[moduleType] = moduleCounts[moduleType]! + 1;
      }
    }

    var totalIncome = 0.0;
    var totalExpense = 0.0;
    if (financeDocs != null) {
      for (final document in financeDocs) {
        final data = document.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        if (data['type'] == 'income') {
          totalIncome += amount;
        } else if (data['type'] == 'expense') {
          totalExpense += amount;
        }
      }
    }

    return DashboardSummary(
      todayLogbooks: todayLogbooks,
      weeklyLogbooks: weeklyLogbooks,
      logbooksByModule: [
        for (final entry in moduleCounts.entries)
          ModuleActivitySummary(
            moduleType: entry.key,
            label: FarmModules.nameOf(entry.key),
            total: entry.value,
          ),
      ],
      totalInventoryItems: inventoryCount,
      lowStockItems: lowStockCount,
      lowStockPreview: [
        for (final document in lowStockPreviewDocs)
          _lowStockItemFromDocument(document),
      ],
      todaySchedules: todayScheduleCount,
      pendingSchedules: pendingScheduleCount,
      overdueSchedules: overdueScheduleCount,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      activities: activityCounts.entries
          .map(
            (entry) => DailyActivityPoint(date: entry.key, total: entry.value),
          )
          .toList(),
      nutrientCycleNodes: _nutrientCycleNodes,
      nutrientCycleEdges: _nutrientCycleEdges,
      financeVisible: includeFinance && financeDocs != null,
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadLogbookDocs({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.logbooks)
          .where('isDeleted', isEqualTo: false)
          .where(
            'activityDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('activityDate', isLessThan: Timestamp.fromDate(end))
          .orderBy('activityDate')
          .get();
      return snapshot.docs;
    } on FirebaseException catch (error) {
      if (!_isIndexBuilding(error)) rethrow;
      final docs = await _loadActiveDocs(FirestoreCollections.logbooks);
      return docs.where((document) {
        final value = document.data()['activityDate'];
        if (value is! Timestamp) return false;
        final date = value.toDate();
        return !date.isBefore(start) && date.isBefore(end);
      }).toList()..sort(_compareTimestamp('activityDate'));
    }
  }

  Future<int> _loadInventoryCount() async {
    try {
      return (await _activeInventoryQuery().count().get()).count ?? 0;
    } on FirebaseException catch (error) {
      if (!_isIndexBuilding(error)) rethrow;
      return (await _loadActiveDocs(FirestoreCollections.inventory)).length;
    }
  }

  Future<int> _loadLowStockCount() async {
    try {
      return (await _activeInventoryQuery()
                  .where('isLowStock', isEqualTo: true)
                  .count()
                  .get())
              .count ??
          0;
    } on FirebaseException catch (error) {
      if (!_isIndexBuilding(error)) rethrow;
      final docs = await _loadActiveDocs(FirestoreCollections.inventory);
      return docs
          .where((document) => document.data()['isLowStock'] == true)
          .length;
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadLowStockPreviewDocs() async {
    try {
      final snapshot = await _activeInventoryQuery()
          .where('isLowStock', isEqualTo: true)
          .orderBy('name')
          .limit(5)
          .get();
      return snapshot.docs;
    } on FirebaseException catch (error) {
      if (!_isIndexBuilding(error)) rethrow;
      final docs = await _loadActiveDocs(FirestoreCollections.inventory);
      final lowStockDocs =
          docs
              .where((document) => document.data()['isLowStock'] == true)
              .toList()
            ..sort(_compareString('name'));
      return lowStockDocs.take(5).toList();
    }
  }

  Future<int> _loadTodayScheduleCount({
    required DateTime today,
    required DateTime tomorrow,
  }) async {
    try {
      return (await _activeSchedulesQuery()
                  .where(
                    'date',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(today),
                  )
                  .where('date', isLessThan: Timestamp.fromDate(tomorrow))
                  .count()
                  .get())
              .count ??
          0;
    } on FirebaseException catch (error) {
      if (!_isIndexBuilding(error)) rethrow;
      final docs = await _loadActiveDocs(FirestoreCollections.schedules);
      return docs.where((document) {
        final value = document.data()['date'];
        if (value is! Timestamp) return false;
        final date = value.toDate();
        return !date.isBefore(today) && date.isBefore(tomorrow);
      }).length;
    }
  }

  Future<int> _loadPendingScheduleCount() async {
    try {
      return (await _activeSchedulesQuery()
                  .where('status', isEqualTo: 'pending')
                  .count()
                  .get())
              .count ??
          0;
    } on FirebaseException catch (error) {
      if (!_isIndexBuilding(error)) rethrow;
      final docs = await _loadActiveDocs(FirestoreCollections.schedules);
      return docs
          .where((document) => document.data()['status'] == 'pending')
          .length;
    }
  }

  Future<int> _loadOverdueScheduleCount({required DateTime today}) async {
    try {
      return (await _activeSchedulesQuery()
                  .where('status', isEqualTo: 'pending')
                  .where('date', isLessThan: Timestamp.fromDate(today))
                  .count()
                  .get())
              .count ??
          0;
    } on FirebaseException catch (error) {
      if (!_isIndexBuilding(error)) rethrow;
      final docs = await _loadActiveDocs(FirestoreCollections.schedules);
      return docs.where((document) {
        final data = document.data();
        final value = data['date'];
        if (data['status'] != 'pending' || value is! Timestamp) return false;
        return value.toDate().isBefore(today);
      }).length;
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>?>
  _loadFinanceSnapshot({
    required DateTime monthStart,
    required DateTime nextMonth,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.financeTransactions)
          .where('isDeleted', isEqualTo: false)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('date', isLessThan: Timestamp.fromDate(nextMonth))
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return null;
      if (_isIndexBuilding(error)) {
        final docs = await _loadActiveDocs(
          FirestoreCollections.financeTransactions,
        );
        return docs.where((document) {
          final value = document.data()['date'];
          if (value is! Timestamp) return false;
          final date = value.toDate();
          return !date.isBefore(monthStart) && date.isBefore(nextMonth);
        }).toList()..sort(_compareTimestamp('date', descending: true));
      }
      rethrow;
    }
  }

  Query<Map<String, dynamic>> _activeInventoryQuery() {
    return _firestore
        .collection(FirestoreCollections.inventory)
        .where('isDeleted', isEqualTo: false);
  }

  Query<Map<String, dynamic>> _activeSchedulesQuery() {
    return _firestore
        .collection(FirestoreCollections.schedules)
        .where('isDeleted', isEqualTo: false);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadActiveDocs(
    String collection,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('isDeleted', isEqualTo: false)
          .get();
      return snapshot.docs;
    } on FirebaseException catch (error) {
      if (!_isIndexBuilding(error)) rethrow;
      final snapshot = await _firestore.collection(collection).get();
      return snapshot.docs
          .where((document) => document.data()['isDeleted'] != true)
          .toList();
    }
  }

  LowStockDashboardItem _lowStockItemFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return LowStockDashboardItem(
      id: data['id'] as String? ?? document.id,
      name: data['name'] as String? ?? 'Item tanpa nama',
      currentStock: (data['currentStock'] as num?)?.toDouble() ?? 0,
      minStock: (data['minStock'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] as String? ?? '',
    );
  }
}

bool _isIndexBuilding(FirebaseException error) {
  return error.code == 'failed-precondition' &&
      (error.message?.toLowerCase().contains('index') ?? false);
}

int Function(
  QueryDocumentSnapshot<Map<String, dynamic>>,
  QueryDocumentSnapshot<Map<String, dynamic>>,
)
_compareString(String field) {
  return (left, right) {
    final leftValue = left.data()[field];
    final rightValue = right.data()[field];
    return (leftValue is String ? leftValue : '').compareTo(
      rightValue is String ? rightValue : '',
    );
  };
}

int Function(
  QueryDocumentSnapshot<Map<String, dynamic>>,
  QueryDocumentSnapshot<Map<String, dynamic>>,
)
_compareTimestamp(String field, {bool descending = false}) {
  return (left, right) {
    final leftValue = left.data()[field];
    final rightValue = right.data()[field];
    final leftDate = leftValue is Timestamp
        ? leftValue.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
    final rightDate = rightValue is Timestamp
        ? rightValue.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
    final comparison = leftDate.compareTo(rightDate);
    return descending ? -comparison : comparison;
  };
}

const _nutrientCycleNodes = [
  NutrientCycleNode(
    id: 'ayam',
    label: 'Ayam Kampung',
    description: 'Menghasilkan telur, sisa pakan, dan kotoran organik.',
    moduleType: 'ayam_kampung',
  ),
  NutrientCycleNode(
    id: 'organik',
    label: 'Sisa Organik',
    description: 'Kotoran dan residu panen menjadi input budidaya berikutnya.',
  ),
  NutrientCycleNode(
    id: 'maggot_cacing',
    label: 'Maggot & Cacing',
    description: 'Mengurai organik menjadi biomassa pakan dan kascing.',
    moduleType: 'maggot_bsf',
  ),
  NutrientCycleNode(
    id: 'kompos',
    label: 'Kompos & Kascing',
    description: 'Media penyubur tanah dan sumber nutrisi tanaman.',
    moduleType: 'cacing_tanah',
  ),
  NutrientCycleNode(
    id: 'lele_tanaman',
    label: 'Lele & Tanaman',
    description:
        'Menerima manfaat pakan alternatif, air kaya nutrisi, dan kompos.',
    moduleType: 'lele',
  ),
];

const _nutrientCycleEdges = [
  NutrientCycleEdge(
    from: 'ayam',
    to: 'organik',
    label: 'kotoran dan sisa pakan',
  ),
  NutrientCycleEdge(
    from: 'organik',
    to: 'maggot_cacing',
    label: 'substrat budidaya',
  ),
  NutrientCycleEdge(
    from: 'maggot_cacing',
    to: 'kompos',
    label: 'kascing dan residu uraian',
  ),
  NutrientCycleEdge(
    from: 'maggot_cacing',
    to: 'lele_tanaman',
    label: 'pakan alternatif',
  ),
  NutrientCycleEdge(
    from: 'kompos',
    to: 'lele_tanaman',
    label: 'penyuburan tanaman',
  ),
  NutrientCycleEdge(
    from: 'lele_tanaman',
    to: 'organik',
    label: 'sisa panen kembali diolah',
  ),
];
