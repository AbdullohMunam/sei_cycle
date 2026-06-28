import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/farm_modules.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/firestore_validators.dart';
import '../../inventory/services/inventory_service.dart';
import '../models/logbook_entry.dart';
import 'inventory_mapping.dart';

class LogbookService {
  LogbookService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  late final InventoryService _inventoryService = InventoryService(
    firestore: _firestore,
    uuid: _uuid,
  );

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

    await createLogbookWithInventory(
      moduleType: moduleType,
      title: title,
      activityType: activityType,
      quantity: quantity,
      unit: unit,
      notes: notes,
      details: details,
      userId: userId,
    );
  }

  Future<List<InventoryStockWarning>> previewInventoryStockWarnings({
    required String moduleType,
    required Map<String, dynamic> details,
  }) {
    final actions = mapLogbookDetailsToInventoryActions(
      moduleType: moduleType,
      details: details,
      logbookId: 'preview',
    );
    return _inventoryService.previewNegativeStockWarnings(actions: actions);
  }

  Future<void> createLogbookWithInventory({
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

    final logbookId = _uuid.v4();
    final actions = mapLogbookDetailsToInventoryActions(
      moduleType: moduleType,
      details: details,
      logbookId: logbookId,
    );
    final targets = await _inventoryService.resolveActionTargets(
      actions: actions,
      userId: userId,
    );
    final transactionIds = {
      for (final target in targets) target.action: _uuid.v4(),
    };
    final productionIds = {
      for (final target in targets)
        if (target.action.shouldCreateProductionResult)
          target.action: _uuid.v4(),
    };

    await _firestore.runTransaction((transaction) async {
      final inventorySnapshots =
          <InventoryActionTarget, DocumentSnapshot<Map<String, dynamic>>>{};
      final notificationSnapshots =
          <InventoryActionTarget, DocumentSnapshot<Map<String, dynamic>>>{};

      for (final target in targets) {
        inventorySnapshots[target] = await transaction.get(target.reference);
        notificationSnapshots[target] = await transaction.get(
          _lowStockNotificationRef(target.reference.id, userId),
        );
      }

      final now = FieldValue.serverTimestamp();
      transaction.set(_collection.doc(logbookId), {
        'id': logbookId,
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

      for (final target in targets) {
        final snapshot = inventorySnapshots[target]!;
        _inventoryService.applyInventoryActionInTransaction(
          transaction: transaction,
          target: target,
          snapshot: snapshot,
          logbookId: logbookId,
          transactionId: transactionIds[target.action]!,
          userId: userId,
        );

        final action = target.action;
        if (action.shouldCreateProductionResult) {
          final id = productionIds[action]!;
          transaction.set(
            _firestore
                .collection(FirestoreCollections.productionResults)
                .doc(id),
            {
              'id': id,
              'logbookId': logbookId,
              'moduleType': moduleType,
              'productName': action.productName ?? action.itemName,
              'quantity': action.quantity,
              'unit': action.unit,
              'qualityStatus': 'normal',
              'harvestDate': now,
              'notes': action.notes,
              'createdBy': userId,
              'createdAt': now,
            },
          );
        }

        final data = snapshot.exists ? snapshot.data() : target.existingData;
        final beforeStock = (data?['currentStock'] as num?)?.toDouble() ?? 0;
        final minStock = (data?['minStock'] as num?)?.toDouble() ?? 0;
        final afterStock = action.isOut
            ? beforeStock - action.quantity
            : beforeStock + action.quantity;
        if (afterStock <= minStock) {
          final notificationRef = _lowStockNotificationRef(
            target.reference.id,
            userId,
          );
          final notification = notificationSnapshots[target]!;
          final notificationData = notification.data();
          final shouldCreateNotification =
              !notification.exists ||
              notificationData?['isDeleted'] == true ||
              notificationData?['isRead'] == true;
          if (shouldCreateNotification) {
            transaction.set(notificationRef, {
              'id': notificationRef.id,
              'title': 'Stok ${action.itemName} rendah',
              'body':
                  'Stok ${action.itemName} menipis. Sisa ${_number(afterStock)} ${action.unit}.',
              'type': 'low_stock',
              'targetRole': 'admin',
              'userId': userId,
              'relatedCollection': FirestoreCollections.inventory,
              'relatedId': target.reference.id,
              'isRead': false,
              'createdAt': now,
              'isDeleted': false,
            }, SetOptions(merge: true));
          }
        }
      }
    });
  }

  DocumentReference<Map<String, dynamic>> _lowStockNotificationRef(
    String itemId,
    String userId,
  ) {
    return _firestore
        .collection(FirestoreCollections.notifications)
        .doc('low_stock_${userId}_$itemId');
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

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
