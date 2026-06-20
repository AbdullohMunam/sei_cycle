import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_dates.dart';

class FinanceRecord {
  const FinanceRecord({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FinanceRecord.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return FinanceRecord(
      id: data['id'] as String? ?? document.id,
      type: data['type'] as String? ?? 'expense',
      category: data['category'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: dateTimeFromFirestore(data['date']),
      note: data['note'] as String? ?? '',
      createdBy: data['created_by'] as String? ?? '',
      createdAt: dateTimeFromFirestore(data['created_at']),
      updatedAt: dateTimeFromFirestore(data['updated_at']),
    );
  }
}
