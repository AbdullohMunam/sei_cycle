import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/finance_record.dart';

class FinanceService {
  FinanceService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.financeRecords);

  Stream<List<FinanceRecord>> watchRecords() {
    return _collection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(FinanceRecord.fromDocument).toList()
            ..sort((a, b) => b.date.compareTo(a.date)),
    );
  }

  Future<void> save({
    String? id,
    required String type,
    required String category,
    required double amount,
    required DateTime date,
    required String note,
    required String userId,
  }) async {
    final documentId = id ?? _uuid.v4();
    final data = <String, dynamic>{
      'id': documentId,
      'type': type,
      'category': category.trim(),
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      data['created_by'] = userId;
      data['created_at'] = FieldValue.serverTimestamp();
    }
    await _collection.doc(documentId).set(data, SetOptions(merge: true));
  }

  Future<void> delete(String id) {
    return _collection.doc(id).delete();
  }
}
