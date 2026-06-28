import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/farm_modules.dart';
import '../../../core/constants/firestore_collections.dart';
import '../models/farm_module.dart';

class FarmModuleService {
  FarmModuleService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.farmModules);

  Stream<List<FarmModule>> watchActiveModules() {
    return _collection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(FarmModule.fromDocument).toList());
  }

  Future<void> seedDefaults() async {
    final batch = _firestore.batch();
    for (final module in FarmModules.values) {
      batch.set(_collection.doc(module.id), {
        'id': module.id,
        'name': module.name,
        'type': module.type,
        'description': module.description,
        'icon': module.icon,
        'color': module.color,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
