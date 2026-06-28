import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/firestore_validators.dart';
import '../models/inventory_transaction.dart';

class InventoryTransactionService {
  InventoryTransactionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.inventoryTransactions);

  Future<List<InventoryTransaction>> getTransactionsByLogbookId(
    String logbookId,
  ) async {
    requireTrimmed(logbookId, 'logbookId');
    final snapshot = await _collection
        .where('logbookId', isEqualTo: logbookId)
        .orderBy('transactionDate', descending: true)
        .get();
    return snapshot.docs.map(InventoryTransaction.fromDocument).toList();
  }

  Future<List<InventoryTransaction>> getTransactionsByItemId(
    String itemId,
  ) async {
    requireTrimmed(itemId, 'itemId');
    final snapshot = await _collection
        .where('itemId', isEqualTo: itemId)
        .orderBy('transactionDate', descending: true)
        .get();
    return snapshot.docs.map(InventoryTransaction.fromDocument).toList();
  }

  Future<void> markTransactionsReversed(
    String logbookId, {
    required String userId,
  }) async {
    requireTrimmed(logbookId, 'logbookId');
    requireTrimmed(userId, 'userId');
    final snapshot = await _collection
        .where('logbookId', isEqualTo: logbookId)
        .where('isReversed', isEqualTo: false)
        .limit(100)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final document in snapshot.docs) {
      batch.update(document.reference, {
        'isReversed': true,
        'reversedAt': FieldValue.serverTimestamp(),
        'reversedBy': userId,
      });
    }
    await batch.commit();
  }
}
