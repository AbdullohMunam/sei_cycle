import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_fields.dart';

class EducationContent {
  const EducationContent({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.externalUrl,
    required this.isPublished,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  final String id;
  final String title;
  final String type;
  final String content;
  final String externalUrl;
  final bool isPublished;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  factory EducationContent.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return EducationContent(
      id: stringField(data, const ['id'], fallback: document.id),
      title: stringField(data, const ['title']),
      type: stringField(data, const ['type'], fallback: 'artikel'),
      content: stringField(data, const ['content', 'description']),
      externalUrl: stringField(data, const ['externalUrl', 'external_url']),
      isPublished: boolField(data, const ['isPublished', 'is_published']),
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
      'type': type,
      'content': content,
      'externalUrl': externalUrl,
      'isPublished': isPublished,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
    };
  }
}
