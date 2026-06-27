import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/firestore_validators.dart';
import '../models/inventory_item.dart';

class InventoryService {
  InventoryService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.inventory);

  Stream<List<InventoryItem>> watchItems() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('isLowStock', descending: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(InventoryItem.fromDocument).toList(),
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
    _validateSave(
      name: name,
      category: category,
      unit: unit,
      currentStock: currentStock,
      minStock: minStock,
      userId: userId,
    );

    final documentId = id ?? _uuid.v4();
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'id': documentId,
      'name': name.trim(),
      'category': category.trim(),
      'unit': unit.trim(),
      'currentStock': currentStock,
      'minStock': minStock,
      'isLowStock': currentStock <= minStock,
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
    required String name,
    required String category,
    required String unit,
    required double currentStock,
    required double minStock,
    required String userId,
  }) {
    requireTrimmed(name, 'name');
    requireTrimmed(category, 'category');
    requireTrimmed(unit, 'unit');
    requireNonNegative(currentStock, 'currentStock');
    requireNonNegative(minStock, 'minStock');
    requireTrimmed(userId, 'userId');
  }
}
