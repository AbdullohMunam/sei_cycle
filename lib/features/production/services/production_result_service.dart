import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/firestore_validators.dart';
import '../../logbook/services/inventory_mapping.dart';

class ProductionResultService {
  ProductionResultService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.productionResults);

  Future<void> createProductionResultFromInventoryAction({
    required InventoryLogbookAction action,
    required String logbookId,
    required String userId,
  }) async {
    requireTrimmed(logbookId, 'logbookId');
    requireTrimmed(userId, 'userId');
    if (!action.shouldCreateProductionResult || action.quantity <= 0) return;
    final id = _uuid.v4();
    await _collection.doc(id).set({
      'id': id,
      'logbookId': logbookId,
      'moduleType': action.moduleType ?? '',
      'productName': action.productName ?? action.itemName,
      'quantity': action.quantity,
      'unit': action.unit,
      'qualityStatus': 'normal',
      'harvestDate': FieldValue.serverTimestamp(),
      'notes': action.notes,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
