import '../../finance/models/finance_record.dart';
import '../../inventory/models/inventory_item.dart';
import '../../logbook/models/logbook_entry.dart';

class AnalyticsModel {
  AnalyticsModel({
    required this.logbooks,
    required this.inventoryItems,
    required this.financeRecords,
    required this.startDate,
    required this.endDate,
  });

  final List<LogbookEntry> logbooks;
  final List<InventoryItem> inventoryItems;
  final List<FinanceRecord> financeRecords;
  final DateTime startDate;
  final DateTime endDate;

  // Analytics Helpers
  Map<String, int> get logbooksPerModule {
    final map = <String, int>{};
    for (final log in logbooks) {
      final module = log.moduleId;
      if (module.isNotEmpty) {
        map[module] = (map[module] ?? 0) + 1;
      }
    }
    return map;
  }

  List<InventoryItem> get lowStockItems {
    return inventoryItems
        .where((item) => item.currentStock <= item.minStock)
        .toList();
  }

  double get totalIncome {
    return financeRecords
        .where((record) => record.type == 'income')
        .fold(0.0, (sum, record) => sum + record.amount);
  }

  double get totalExpense {
    return financeRecords
        .where((record) => record.type == 'expense')
        .fold(0.0, (sum, record) => sum + record.amount);
  }

  double get profitLoss => totalIncome - totalExpense;
}
