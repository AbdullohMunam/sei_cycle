import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_fields.dart';

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.title,
    required this.moduleId,
    required this.scheduleType,
    required this.scheduledAt,
    required this.status,
    required this.note,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  final String id;
  final String title;
  final String moduleId;
  final String scheduleType;
  final DateTime scheduledAt;
  final String status;
  final String note;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  factory ScheduleItem.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return ScheduleItem(
      id: stringField(data, const ['id'], fallback: document.id),
      title: stringField(data, const ['title']),
      moduleId: stringField(data, const ['moduleType', 'module_id']),
      scheduleType: stringField(data, const ['type', 'schedule_type']),
      scheduledAt: dateTimeField(data, const [
        'date',
        'scheduledAt',
        'scheduled_at',
      ]),
      status: stringField(data, const ['status'], fallback: 'pending'),
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
      'title': title,
      'moduleType': moduleId,
      'type': scheduleType,
      'date': Timestamp.fromDate(scheduledAt),
      'status': status,
      'notes': note,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
    };
  }
}
