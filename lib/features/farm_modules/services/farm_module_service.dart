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
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(FarmModule.fromDocument).toList()
                ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  Future<void> seedDefaults() async {
    final batch = _firestore.batch();
    for (final module in FarmModules.values) {
      batch.set(_collection.doc(module.id), {
        'module_id': module.id,
        'module_name': module.name,
        'module_type': module.type,
        'description': module.description,
        'icon': module.icon,
        'color': module.color,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
