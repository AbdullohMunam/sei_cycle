import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/farm_modules.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/firestore_validators.dart';
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
    Query<Map<String, dynamic>> query = _collection.where(
      'isDeleted',
      isEqualTo: false,
    );

    if (moduleId != null) {
      query = query.where('moduleType', isEqualTo: moduleId);
    }

    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .where(
            'activityDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('activityDate', isLessThan: Timestamp.fromDate(end));
    }

    return query
        .orderBy('activityDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(LogbookEntry.fromDocument).toList(),
        );
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
    _validateSave(
      moduleId: moduleId,
      activityType: activityType,
      quantity: quantity,
      unit: unit,
      condition: condition,
      userId: userId,
    );

    final documentId = id ?? _uuid.v4();
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'id': documentId,
      'title': activityType.trim(),
      'moduleType': moduleId,
      'activityDate': Timestamp.fromDate(activityDate),
      'quantity': quantity,
      'unit': unit.trim(),
      'status': condition.trim(),
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
  }

  Future<void> softDelete(String id, {required String userId}) {
    requireTrimmed(id, 'id');
    requireTrimmed(userId, 'userId');
    return _collection.doc(id).update({
      'isDeleted': true,
      'updatedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _validateSave({
    required String moduleId,
    required String activityType,
    required double quantity,
    required String unit,
    required String condition,
    required String userId,
  }) {
    requireOneOf(
      moduleId,
      FarmModules.values.map((module) => module.id).toSet(),
      'moduleType',
    );
    requireTrimmed(activityType, 'title');
    requirePositive(quantity, 'quantity');
    requireTrimmed(unit, 'unit');
    requireTrimmed(condition, 'status');
    requireTrimmed(userId, 'userId');
  }
}
