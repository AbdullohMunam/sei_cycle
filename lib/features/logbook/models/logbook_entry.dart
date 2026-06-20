import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_dates.dart';

class LogbookEntry {
  const LogbookEntry({
    required this.id,
    required this.moduleId,
    required this.activityType,
    required this.activityDate,
    required this.quantity,
    required this.unit,
    required this.condition,
    required this.note,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  final String id;
  final String moduleId;
  final String activityType;
  final DateTime activityDate;
  final double quantity;
  final String unit;
  final String condition;
  final String note;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  factory LogbookEntry.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return LogbookEntry(
      id: data['id'] as String? ?? document.id,
      moduleId: data['module_id'] as String? ?? '',
      activityType: data['activity_type'] as String? ?? '',
      activityDate: dateTimeFromFirestore(data['activity_date']),
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] as String? ?? '',
      condition: data['condition'] as String? ?? '',
      note: data['note'] as String? ?? '',
      createdBy: data['created_by'] as String? ?? '',
      createdAt: dateTimeFromFirestore(data['created_at']),
      updatedAt: dateTimeFromFirestore(data['updated_at']),
      isDeleted: data['is_deleted'] as bool? ?? false,
    );
  }
}
