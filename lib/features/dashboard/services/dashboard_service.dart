import 'package:cloud_firestore/cloud_firestore.dart';

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
    final chartStart = today.subtract(const Duration(days: 6));

    final logbookFuture = _firestore
        .collection(FirestoreCollections.logbooks)
        .where('isDeleted', isEqualTo: false)
        .where(
          'activityDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(chartStart),
        )
        .where('activityDate', isLessThan: Timestamp.fromDate(tomorrow))
        .orderBy('activityDate')
        .get();
    final inventoryFuture = _firestore
        .collection(FirestoreCollections.inventory)
        .where('isDeleted', isEqualTo: false)
        .where('isLowStock', isEqualTo: true)
        .get();
    final scheduleFuture = _firestore
        .collection(FirestoreCollections.schedules)
        .where('isDeleted', isEqualTo: false)
        .where('status', isEqualTo: 'pending')
        .get();

    final results = await Future.wait([
      logbookFuture,
      inventoryFuture,
      scheduleFuture,
    ]);
    final logbooks = results[0].docs;

    final counts = <DateTime, int>{
      for (var i = 0; i < 7; i++) chartStart.add(Duration(days: i)): 0,
    };
    var todayLogbooks = 0;
    for (final document in logbooks) {
      final timestamp = document.data()['activityDate'];
      if (timestamp is! Timestamp) continue;
      final value = timestamp.toDate();
      final day = DateTime(value.year, value.month, value.day);
      if (day == today) todayLogbooks++;
      if (counts.containsKey(day)) counts[day] = counts[day]! + 1;
    }

    var totalIncome = 0.0;
    var totalExpense = 0.0;
    if (includeFinance) {
      final financeSnapshot = await _firestore
          .collection(FirestoreCollections.financeTransactions)
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .get();
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
      lowStockItems: results[1].docs.length,
      pendingSchedules: results[2].docs.length,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      activities: counts.entries
          .map(
            (entry) => DailyActivityPoint(date: entry.key, total: entry.value),
          )
          .toList(),
      financeVisible: includeFinance,
    );
  }
}
