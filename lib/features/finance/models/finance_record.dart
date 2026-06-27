import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_fields.dart';

class FinanceRecord {
  const FinanceRecord({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  final String id;
  final String type;
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  factory FinanceRecord.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return FinanceRecord(
      id: stringField(data, const ['id'], fallback: document.id),
      type: stringField(data, const ['type'], fallback: 'expense'),
      category: stringField(data, const ['category', 'title']),
      amount: doubleField(data, const ['amount']),
      date: dateTimeField(data, const ['date']),
      note: stringField(data, const ['notes', 'note']),
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
      'type': type,
      'category': category,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': note,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
    };
  }
}
