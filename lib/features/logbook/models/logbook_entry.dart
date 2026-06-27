import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_fields.dart';

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
    required this.updatedBy,
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
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  factory LogbookEntry.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return LogbookEntry(
      id: stringField(data, const ['id'], fallback: document.id),
      moduleId: stringField(data, const ['moduleType', 'module_id']),
      activityType: stringField(data, const ['title', 'activity_type']),
      activityDate: dateTimeField(data, const [
        'activityDate',
        'activity_date',
      ]),
      quantity: doubleField(data, const ['quantity']),
      unit: stringField(data, const ['unit']),
      condition: stringField(data, const ['status', 'condition']),
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
      'title': activityType,
      'moduleType': moduleId,
      'activityDate': Timestamp.fromDate(activityDate),
      'quantity': quantity,
      'unit': unit,
      'status': condition,
      'notes': note,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
    };
  }
}
