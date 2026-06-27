import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/firestore_validators.dart';
import '../models/education_content.dart';

class EducationService {
  EducationService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  static const _validTypes = {'artikel', 'video', 'sop'};

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.educationContents);

  Stream<List<EducationContent>> watchContents({required bool includeDrafts}) {
    Query<Map<String, dynamic>> query = _collection.where(
      'isDeleted',
      isEqualTo: false,
    );
    if (!includeDrafts) {
      query = query.where('isPublished', isEqualTo: true);
    }

    return query
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(EducationContent.fromDocument).toList(),
        );
  }

  Future<void> save({
    String? id,
    required String title,
    required String type,
    required String content,
    required String externalUrl,
    required bool isPublished,
    required String userId,
  }) async {
    _validateSave(title: title, type: type, content: content, userId: userId);

    final documentId = id ?? _uuid.v4();
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'id': documentId,
      'title': title.trim(),
      'type': type,
      'content': content.trim(),
      'externalUrl': externalUrl.trim(),
      'isPublished': isPublished,
      'updatedBy': userId,
      'updatedAt': now,
      'isDeleted': false,
    };
    if (id == null) {
      data['createdBy'] = userId;
      data['createdAt'] = now;
    }
    await _collection.doc(documentId).set(data, SetOptions(merge: true));
  }

  Future<void> delete(String id, {required String userId}) {
    requireTrimmed(id, 'id');
    requireTrimmed(userId, 'userId');
    return _collection.doc(id).update({
      'isDeleted': true,
      'updatedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _validateSave({
    required String title,
    required String type,
    required String content,
    required String userId,
  }) {
    requireTrimmed(title, 'title');
    requireOneOf(type, _validTypes, 'type');
    requireTrimmed(content, 'content');
    requireTrimmed(userId, 'userId');
  }
}
