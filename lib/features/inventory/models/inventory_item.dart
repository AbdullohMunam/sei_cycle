import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_dates.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.minStock,
    required this.isLowStock,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double minStock;
  final bool isLowStock;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory InventoryItem.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final currentStock = (data['current_stock'] as num?)?.toDouble() ?? 0;
    final minStock = (data['min_stock'] as num?)?.toDouble() ?? 0;
    return InventoryItem(
      id: data['id'] as String? ?? document.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      unit: data['unit'] as String? ?? '',
      currentStock: currentStock,
      minStock: minStock,
      isLowStock: data['is_low_stock'] as bool? ?? currentStock <= minStock,
      createdBy: data['created_by'] as String? ?? '',
      createdAt: dateTimeFromFirestore(data['created_at']),
      updatedAt: dateTimeFromFirestore(data['updated_at']),
    );
  }
}
