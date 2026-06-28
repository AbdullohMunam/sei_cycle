import 'package:flutter/material.dart';

class DashboardActivity {
  const DashboardActivity({
    required this.time,
    required this.title,
    required this.icon,
    required this.color,
    required this.done,
  });

  final String time;
  final String title;
  final IconData icon;
  final Color color;
  final bool done;
}

class RevenueBreakdownItem {
  const RevenueBreakdownItem({
    required this.label,
    required this.amount,
    required this.portion,
    required this.color,
  });

  final String label;
  final double amount;
  final double portion;
  final Color color;
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

class DashboardSummary {
  const DashboardSummary({
    required this.activeModuleCount,
    required this.todayLogCount,
    required this.todayScheduleCount,
    required this.lowStockCount,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlyProfit,
    required this.recentActivities,
    required this.revenueItems,
    required this.lowStockPreview,
    required this.financeVisible,
  });

  final int activeModuleCount;
  final int todayLogCount;
  final int todayScheduleCount;
  final int lowStockCount;
  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlyProfit;
  final List<DashboardActivity> recentActivities;
  final List<RevenueBreakdownItem> revenueItems;
  final List<LowStockDashboardItem> lowStockPreview;
  final bool financeVisible;

  bool get hasFinanceData => monthlyIncome > 0 || monthlyExpense > 0;
}
