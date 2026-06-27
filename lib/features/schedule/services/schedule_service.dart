import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/farm_modules.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/firestore_validators.dart';
import '../models/schedule_item.dart';

class ScheduleService {
  ScheduleService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  static const _validStatuses = {'pending', 'done', 'skipped'};

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.schedules);

  Stream<List<ScheduleItem>> watchSchedules({DateTime? date}) {
    Query<Map<String, dynamic>> query = _collection.where(
      'isDeleted',
      isEqualTo: false,
    );

    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end));
    }

    return query
        .orderBy('date')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ScheduleItem.fromDocument).toList(),
        );
  }

  Future<String> save({
    String? id,
    required String title,
    required String moduleId,
    required String scheduleType,
    required DateTime scheduledAt,
    required String status,
    required String note,
    required String userId,
  }) async {
    _validateSave(
      title: title,
      moduleId: moduleId,
      scheduleType: scheduleType,
      status: status,
      userId: userId,
    );

    final documentId = id ?? _uuid.v4();
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'id': documentId,
      'title': title.trim(),
      'moduleType': moduleId,
      'type': scheduleType.trim(),
      'date': Timestamp.fromDate(scheduledAt),
      'status': status,
      'notes': note.trim(),
      'updatedBy': userId,
      'updatedAt': now,
      'isDeleted': false,
    };
    if (id == null) {
      data['createdBy'] = userId;
      data['createdAt'] = now;
    }
    await _collection.doc(documentId).set(data, SetOptions(merge: true));
    return documentId;
  }

  Future<void> updateStatus(
    String id,
    String status, {
    required String userId,
  }) {
    requireTrimmed(id, 'id');
    requireTrimmed(userId, 'userId');
    requireOneOf(status, _validStatuses, 'status');
    return _collection.doc(id).update({
      'status': status,
      'updatedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    required String moduleId,
    required String scheduleType,
    required String status,
    required String userId,
  }) {
    requireTrimmed(title, 'title');
    requireOneOf(
      moduleId,
      FarmModules.values.map((module) => module.id).toSet(),
      'moduleType',
    );
    requireTrimmed(scheduleType, 'type');
    requireOneOf(status, _validStatuses, 'status');
    requireTrimmed(userId, 'userId');
  }
}
