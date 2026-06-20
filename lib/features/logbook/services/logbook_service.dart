import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/logbook_entry.dart';

class LogbookService {
  LogbookService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.logbooks);

  Stream<List<LogbookEntry>> watchEntries({String? moduleId, DateTime? date}) {
    return _collection.snapshots().map((snapshot) {
      final entries =
          snapshot.docs
              .map(LogbookEntry.fromDocument)
              .where((entry) => !entry.isDeleted)
              .where((entry) => moduleId == null || entry.moduleId == moduleId)
              .where((entry) {
                if (date == null) return true;
                return entry.activityDate.year == date.year &&
                    entry.activityDate.month == date.month &&
                    entry.activityDate.day == date.day;
              })
              .toList()
            ..sort((a, b) => b.activityDate.compareTo(a.activityDate));
      return entries;
    });
  }

  Future<void> save({
    String? id,
    required String moduleId,
    required String activityType,
    required DateTime activityDate,
    required double quantity,
    required String unit,
    required String condition,
    required String note,
    required String userId,
  }) async {
    final documentId = id ?? _uuid.v4();
    final data = <String, dynamic>{
      'id': documentId,
      'module_id': moduleId,
      'activity_type': activityType.trim(),
      'activity_date': Timestamp.fromDate(activityDate),
      'quantity': quantity,
      'unit': unit.trim(),
      'condition': condition.trim(),
      'note': note.trim(),
      'updated_at': FieldValue.serverTimestamp(),
      'is_deleted': false,
    };
    if (id == null) {
      data['created_by'] = userId;
      data['created_at'] = FieldValue.serverTimestamp();
    }
    await _collection.doc(documentId).set(data, SetOptions(merge: true));
  }

  Future<void> softDelete(String id) {
    return _collection.doc(id).update({
      'is_deleted': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
