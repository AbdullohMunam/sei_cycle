import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/schedule_item.dart';

class ScheduleService {
  ScheduleService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.schedules);

  Stream<List<ScheduleItem>> watchSchedules({DateTime? date}) {
    return _collection.snapshots().map((snapshot) {
      final schedules = snapshot.docs.map(ScheduleItem.fromDocument).where((
        item,
      ) {
        if (date == null) return true;
        return item.scheduledAt.year == date.year &&
            item.scheduledAt.month == date.month &&
            item.scheduledAt.day == date.day;
      }).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return schedules;
    });
  }

  Future<void> save({
    String? id,
    required String title,
    required String moduleId,
    required String scheduleType,
    required DateTime scheduledAt,
    required String status,
    required String note,
    required String userId,
  }) async {
    final documentId = id ?? _uuid.v4();
    final data = <String, dynamic>{
      'id': documentId,
      'title': title.trim(),
      'module_id': moduleId,
      'schedule_type': scheduleType.trim(),
      'scheduled_at': Timestamp.fromDate(scheduledAt),
      'status': status,
      'note': note.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      data['created_by'] = userId;
      data['created_at'] = FieldValue.serverTimestamp();
    }
    await _collection.doc(documentId).set(data, SetOptions(merge: true));
  }

  Future<void> updateStatus(String id, String status) {
    return _collection.doc(id).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
