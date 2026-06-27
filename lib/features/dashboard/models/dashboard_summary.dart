class DailyActivityPoint {
  const DailyActivityPoint({required this.date, required this.total});

  final DateTime date;
  final int total;
}

class ModuleActivitySummary {
  const ModuleActivitySummary({
    required this.moduleType,
    required this.label,
    required this.total,
  });

  final String moduleType;
  final String label;
  final int total;
}

class LowStockDashboardItem {
  const LowStockDashboardItem({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.minStock,
    required this.unit,
  });

  final String id;
  final String name;
  final double currentStock;
  final double minStock;
  final String unit;
}

class NutrientCycleNode {
  const NutrientCycleNode({
    required this.id,
    required this.label,
    required this.description,
    this.moduleType,
  });

  final String id;
  final String label;
  final String description;
  final String? moduleType;
}

class NutrientCycleEdge {
  const NutrientCycleEdge({
    required this.from,
    required this.to,
    required this.label,
  });

  final String from;
  final String to;
  final String label;
}

class DashboardSummary {
  const DashboardSummary({
    required this.todayLogbooks,
    required this.weeklyLogbooks,
    required this.logbooksByModule,
    required this.totalInventoryItems,
    required this.lowStockItems,
    required this.lowStockPreview,
    required this.todaySchedules,
    required this.pendingSchedules,
    required this.overdueSchedules,
    required this.totalIncome,
    required this.totalExpense,
    required this.activities,
    required this.nutrientCycleNodes,
    required this.nutrientCycleEdges,
    required this.financeVisible,
  });

  final int todayLogbooks;
  final int weeklyLogbooks;
  final List<ModuleActivitySummary> logbooksByModule;
  final int totalInventoryItems;
  final int lowStockItems;
  final List<LowStockDashboardItem> lowStockPreview;
  final int todaySchedules;
  final int pendingSchedules;
  final int overdueSchedules;
  final double totalIncome;
  final double totalExpense;
  final List<DailyActivityPoint> activities;
  final List<NutrientCycleNode> nutrientCycleNodes;
  final List<NutrientCycleEdge> nutrientCycleEdges;
  final bool financeVisible;

  double get profitLoss => totalIncome - totalExpense;
}
