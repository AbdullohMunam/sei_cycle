import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_fields.dart';

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
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  final String id;
  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double minStock;
  final bool isLowStock;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  factory InventoryItem.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final currentStock = doubleField(data, const [
      'currentStock',
      'current_stock',
    ]);
    final minStock = doubleField(data, const ['minStock', 'min_stock']);
    return InventoryItem(
      id: stringField(data, const ['id'], fallback: document.id),
      name: stringField(data, const ['name']),
      category: stringField(data, const ['category']),
      unit: stringField(data, const ['unit']),
      currentStock: currentStock,
      minStock: minStock,
      isLowStock: boolField(data, const [
        'isLowStock',
        'is_low_stock',
      ], fallback: currentStock <= minStock),
      createdBy: stringField(data, const ['createdBy', 'created_by']),
      updatedBy: stringField(data, const ['updatedBy', 'updated_by']),
      createdAt: dateTimeField(data, const ['createdAt', 'created_at']),
      updatedAt: dateTimeField(data, const ['updatedAt', 'updated_at']),
      isDeleted: boolField(data, const ['isDeleted', 'is_deleted']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'currentStock': currentStock,
      'minStock': minStock,
      'isLowStock': isLowStock,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
    };
  }
}
