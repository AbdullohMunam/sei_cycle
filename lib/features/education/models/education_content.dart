import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_dates.dart';

class EducationContent {
  const EducationContent({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.externalUrl,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String type;
  final String content;
  final String externalUrl;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory EducationContent.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return EducationContent(
      id: data['id'] as String? ?? document.id,
      title: data['title'] as String? ?? '',
      type: data['type'] as String? ?? 'artikel',
      content: data['content'] as String? ?? '',
      externalUrl: data['external_url'] as String? ?? '',
      isPublished: data['is_published'] as bool? ?? false,
      createdAt: dateTimeFromFirestore(data['created_at']),
      updatedAt: dateTimeFromFirestore(data['updated_at']),
    );
  }
}
