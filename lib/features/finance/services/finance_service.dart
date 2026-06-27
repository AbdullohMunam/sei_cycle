import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/firestore_validators.dart';
import '../models/finance_record.dart';

class FinanceService {
  FinanceService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  static const _validTypes = {'income', 'expense'};

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.financeTransactions);

  Stream<List<FinanceRecord>> watchRecords() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(FinanceRecord.fromDocument).toList(),
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
    _validateSave(
      type: type,
      category: category,
      amount: amount,
      userId: userId,
    );

    final documentId = id ?? _uuid.v4();
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'id': documentId,
      'type': type,
      'category': category.trim(),
      'amount': amount,
      'date': Timestamp.fromDate(date),
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
    required String type,
    required String category,
    required double amount,
    required String userId,
  }) {
    requireOneOf(type, _validTypes, 'type');
    requireTrimmed(category, 'category');
    requirePositive(amount, 'amount');
    requireTrimmed(userId, 'userId');
  }
}
