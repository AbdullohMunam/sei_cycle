class DailyActivityPoint {
  const DailyActivityPoint({required this.date, required this.total});

  final DateTime date;
  final int total;
}

class DashboardSummary {
  const DashboardSummary({
    required this.todayLogbooks,
    required this.lowStockItems,
    required this.pendingSchedules,
    required this.totalIncome,
    required this.totalExpense,
    required this.activities,
    required this.financeVisible,
  });

  final int todayLogbooks;
  final int lowStockItems;
  final int pendingSchedules;
  final double totalIncome;
  final double totalExpense;
  final List<DailyActivityPoint> activities;
  final bool financeVisible;

  double get profitLoss => totalIncome - totalExpense;
}
