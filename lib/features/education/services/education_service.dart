import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/education_content.dart';

class EducationService {
  EducationService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.educationContents);

  Stream<List<EducationContent>> watchContents({required bool includeDrafts}) {
    final query = includeDrafts
        ? _collection
        : _collection.where('is_published', isEqualTo: true);
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(EducationContent.fromDocument).toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  Future<void> save({
    String? id,
    required String title,
    required String type,
    required String content,
    required String externalUrl,
    required bool isPublished,
  }) async {
    final documentId = id ?? _uuid.v4();
    final data = <String, dynamic>{
      'id': documentId,
      'title': title.trim(),
      'type': type,
      'content': content.trim(),
      'external_url': externalUrl.trim(),
      'is_published': isPublished,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      data['created_at'] = FieldValue.serverTimestamp();
    }
    await _collection.doc(documentId).set(data, SetOptions(merge: true));
  }
}
