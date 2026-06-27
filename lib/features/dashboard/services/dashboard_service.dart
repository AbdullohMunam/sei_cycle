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

    final logbookFuture = _firestore
        .collection(FirestoreCollections.logbooks)
        .where('isDeleted', isEqualTo: false)
        .where(
          'activityDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(logbookStart),
        )
        .where('activityDate', isLessThan: Timestamp.fromDate(tomorrow))
        .orderBy('activityDate')
        .get();

    final inventoryCountFuture = _activeInventoryQuery().count().get();
    final lowStockCountFuture = _activeInventoryQuery()
        .where('isLowStock', isEqualTo: true)
        .count()
        .get();
    final lowStockPreviewFuture = _activeInventoryQuery()
        .where('isLowStock', isEqualTo: true)
        .orderBy('name')
        .limit(5)
        .get();

    final todayScheduleCountFuture = _activeSchedulesQuery()
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('date', isLessThan: Timestamp.fromDate(tomorrow))
        .count()
        .get();
    final pendingScheduleCountFuture = _activeSchedulesQuery()
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    final overdueScheduleCountFuture = _activeSchedulesQuery()
        .where('status', isEqualTo: 'pending')
        .where('date', isLessThan: Timestamp.fromDate(today))
        .count()
        .get();

    final financeFuture = includeFinance
        ? _firestore
              .collection(FirestoreCollections.financeTransactions)
              .where('isDeleted', isEqualTo: false)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
              )
              .where('date', isLessThan: Timestamp.fromDate(nextMonth))
              .orderBy('date', descending: true)
              .get()
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

    final logbookSnapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final inventoryCount = (results[1] as AggregateQuerySnapshot).count ?? 0;
    final lowStockCount = (results[2] as AggregateQuerySnapshot).count ?? 0;
    final lowStockPreviewSnapshot =
        results[3] as QuerySnapshot<Map<String, dynamic>>;
    final todayScheduleCount =
        (results[4] as AggregateQuerySnapshot).count ?? 0;
    final pendingScheduleCount =
        (results[5] as AggregateQuerySnapshot).count ?? 0;
    final overdueScheduleCount =
        (results[6] as AggregateQuerySnapshot).count ?? 0;
    final financeSnapshot = results[7] as QuerySnapshot<Map<String, dynamic>>?;

    final activityCounts = <DateTime, int>{
      for (var i = 0; i < 7; i++) chartStart.add(Duration(days: i)): 0,
    };
    final moduleCounts = <String, int>{
      for (final module in FarmModules.values) module.id: 0,
    };
    var todayLogbooks = 0;
    var weeklyLogbooks = 0;

    for (final document in logbookSnapshot.docs) {
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
    if (financeSnapshot != null) {
      for (final document in financeSnapshot.docs) {
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
        for (final document in lowStockPreviewSnapshot.docs)
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
      financeVisible: includeFinance,
    );
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
