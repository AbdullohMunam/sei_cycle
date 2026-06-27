import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/inventory_item.dart';

class InventoryService {
  InventoryService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.inventoryItems);

  Stream<List<InventoryItem>> watchItems() {
    return _collection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(InventoryItem.fromDocument).toList()..sort((a, b) {
            if (a.isLowStock != b.isLowStock) {
              return a.isLowStock ? -1 : 1;
            }
            return a.name.compareTo(b.name);
          }),
    );
  }

  Future<void> save({
    String? id,
    required String name,
    required String category,
    required String unit,
    required double currentStock,
    required double minStock,
    required String userId,
  }) async {
    final documentId = id ?? _uuid.v4();
    final data = <String, dynamic>{
      'id': documentId,
      'name': name.trim(),
      'category': category.trim(),
      'unit': unit.trim(),
      'current_stock': currentStock,
      'min_stock': minStock,
      'is_low_stock': currentStock <= minStock,
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
