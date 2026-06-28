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
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(LogbookEntry.fromDocument).toList(),
        );
  }

  Future<List<LogbookEntry>> getHistoryByModule(String moduleType) async {
    requireOneOf(
      moduleType,
      FarmModules.values.map((module) => module.id).toSet(),
      'moduleType',
    );
    final snapshot = await _collection
        .where('isDeleted', isEqualTo: false)
        .where('moduleType', isEqualTo: moduleType)
        .orderBy('activityDate', descending: true)
        .limit(20)
        .get();
    return snapshot.docs.map(LogbookEntry.fromDocument).toList();
  }

  Future<void> createDailyEntry({
    required String moduleType,
    required String title,
    required String activityType,
    required double? quantity,
    required String? unit,
    required String? notes,
    required Map<String, dynamic> details,
    required String userId,
  }) async {
    _validateEntry(
      moduleType: moduleType,
      title: title,
      activityType: activityType,
      userId: userId,
    );

    final documentId = _uuid.v4();
    final now = FieldValue.serverTimestamp();
    await _collection.doc(documentId).set({
      'id': documentId,
      'title': title.trim(),
      'moduleType': moduleType,
      'activityDate': Timestamp.fromDate(DateTime.now()),
      'activityType': activityType.trim(),
      'quantity': quantity,
      'unit': unit?.trim(),
      'status': 'completed',
      'notes': notes?.trim() ?? '',
      'details': details,
      'createdBy': userId,
      'updatedBy': userId,
      'createdAt': now,
      'updatedAt': now,
      'isDeleted': false,
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
    _validateEntry(
      moduleType: moduleId,
      title: activityType,
      activityType: activityType,
      userId: userId,
    );
    requirePositive(quantity, 'quantity');
    requireTrimmed(unit, 'unit');

    final documentId = id ?? _uuid.v4();
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'id': documentId,
      'title': activityType.trim(),
      'moduleType': moduleId,
      'activityDate': Timestamp.fromDate(activityDate),
      'activityType': activityType.trim(),
      'quantity': quantity,
      'unit': unit.trim(),
      'status': condition.trim().isEmpty ? 'completed' : condition.trim(),
      'notes': note.trim(),
      'details': <String, dynamic>{
        'quantity': quantity,
        'unit': unit.trim(),
        'condition': condition.trim(),
      },
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

  void _validateEntry({
    required String moduleType,
    required String title,
    required String activityType,
    required String userId,
  }) {
    requireOneOf(
      moduleType,
      FarmModules.values.map((module) => module.id).toSet(),
      'moduleType',
    );
    requireTrimmed(title, 'title');
    requireTrimmed(activityType, 'activityType');
    requireTrimmed(userId, 'userId');
  }
}
