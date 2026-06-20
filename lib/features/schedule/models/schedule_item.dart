import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_dates.dart';

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
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String moduleId;
  final String scheduleType;
  final DateTime scheduledAt;
  final String status;
  final String note;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ScheduleItem.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return ScheduleItem(
      id: data['id'] as String? ?? document.id,
      title: data['title'] as String? ?? '',
      moduleId: data['module_id'] as String? ?? '',
      scheduleType: data['schedule_type'] as String? ?? '',
      scheduledAt: dateTimeFromFirestore(data['scheduled_at']),
      status: data['status'] as String? ?? 'pending',
      note: data['note'] as String? ?? '',
      createdBy: data['created_by'] as String? ?? '',
      createdAt: dateTimeFromFirestore(data['created_at']),
      updatedAt: dateTimeFromFirestore(data['updated_at']),
    );
  }
}
