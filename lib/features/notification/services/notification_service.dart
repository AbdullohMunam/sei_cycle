import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/firestore_validators.dart';
import '../../inventory/models/inventory_item.dart';
import '../models/app_notification.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.notifications);

  /// Streams the count of unread notifications for the given user/role.
  /// Useful for showing a badge count in navigation.
  Stream<int> watchUnreadCount({
    required String userId,
    required String role,
  }) {
    requireTrimmed(userId, 'userId');
    requireTrimmed(role, 'role');

    return _collection
        .where('isDeleted', isEqualTo: false)
        .where('isRead', isEqualTo: false)
        .where(
          Filter.or(
            Filter('userId', isEqualTo: userId),
            Filter('targetRole', whereIn: [role, 'all']),
          ),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<AppNotification>> watchNotifications({
    required String userId,
    required String role,
    String? type,
  }) {
    requireTrimmed(userId, 'userId');
    requireTrimmed(role, 'role');

    Query<Map<String, dynamic>> query = _collection
        .where('isDeleted', isEqualTo: false)
        .where(
          Filter.or(
            Filter('userId', isEqualTo: userId),
            Filter('targetRole', whereIn: [role, 'all']),
          ),
        );
    if (type != null && type.trim().isNotEmpty) {
      query = query.where('type', isEqualTo: type.trim());
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AppNotification.fromDocument).toList(),
        );
  }

  Future<void> markAsRead(String id) {
    requireTrimmed(id, 'id');
    return _collection.doc(id).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead({
    required String userId,
    required String role,
  }) async {
    final snapshot = await _collection
        .where('isDeleted', isEqualTo: false)
        .where('isRead', isEqualTo: false)
        .where(
          Filter.or(
            Filter('userId', isEqualTo: userId),
            Filter('targetRole', whereIn: [role, 'all']),
          ),
        )
        .limit(50)
        .get();

    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final document in snapshot.docs) {
      batch.update(document.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<String> create({
    String? id,
    required String title,
    required String body,
    required String type,
    String targetRole = 'all',
    String userId = '',
    String relatedCollection = '',
    String relatedId = '',
    DateTime? scheduledAt,
  }) async {
    requireTrimmed(title, 'title');
    requireTrimmed(body, 'body');
    requireTrimmed(type, 'type');

    final documentId = id ?? _uuid.v4();
    await _collection.doc(documentId).set({
      'id': documentId,
      'title': title.trim(),
      'body': body.trim(),
      'type': type.trim(),
      'targetRole': targetRole.trim().isEmpty ? 'all' : targetRole.trim(),
      'userId': userId.trim(),
      'relatedCollection': relatedCollection.trim(),
      'relatedId': relatedId.trim(),
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt),
      'isDeleted': false,
    }, SetOptions(merge: true));
    return documentId;
  }

  Future<void> createLowStockAlerts({
    required String userId,
    required String role,
    required Iterable<InventoryItem> items,
  }) async {
    for (final item in items.where((item) => item.isLowStock).take(5)) {
      await createLowStockAlert(
        userId: userId,
        role: role,
        itemId: item.id,
        name: item.name,
        currentStock: item.currentStock,
        minStock: item.minStock,
        unit: item.unit,
      );
    }
  }

  Future<void> createLowStockAlert({
    required String userId,
    required String role,
    required String itemId,
    required String name,
    required double currentStock,
    required double minStock,
    required String unit,
  }) async {
    requireTrimmed(userId, 'userId');
    requireTrimmed(role, 'role');
    requireTrimmed(itemId, 'itemId');
    requireTrimmed(name, 'name');

    final id = 'low_stock_${userId}_$itemId';
    final reference = _collection.doc(id);
    final existing = await reference.get();
    if (existing.exists && existing.data()?['isRead'] != true) return;

    await reference.set({
      'id': id,
      'title': 'Stok $name rendah',
      'body':
          'Stok $name tersisa ${_number(currentStock)} $unit, batas minimum ${_number(minStock)} $unit.',
      'type': 'low_stock',
      'targetRole': role,
      'userId': userId,
      'relatedCollection': FirestoreCollections.inventory,
      'relatedId': itemId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
    }, SetOptions(merge: true));
  }

  Future<void> createScheduleOverdueAlert({
    required String scheduleId,
    required String title,
    required String userId,
    required String role,
  }) async {
    requireTrimmed(scheduleId, 'scheduleId');
    requireTrimmed(userId, 'userId');
    requireTrimmed(role, 'role');

    final id = 'schedule_overdue_${userId}_$scheduleId';
    final reference = _collection.doc(id);
    final existing = await reference.get();
    // Guard: skip write if an unread alert already exists
    if (existing.exists && existing.data()?['isRead'] != true) return;

    await reference.set({
      'id': id,
      'title': 'Jadwal overdue',
      'body': 'Jadwal $title sudah melewati waktu dan masih pending.',
      'type': 'schedule_overdue',
      'targetRole': role,
      'userId': userId,
      'relatedCollection': FirestoreCollections.schedules,
      'relatedId': scheduleId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
    }, SetOptions(merge: true));
  }

  Future<void> createProductionReminder({
    required String scheduleId,
    required String title,
    required String userId,
    required String role,
    DateTime? scheduledAt,
  }) {
    return create(
      id: 'production_reminder_${userId}_$scheduleId',
      title: 'Pengingat produksi',
      body: title,
      type: 'production_reminder',
      targetRole: role,
      userId: userId,
      relatedCollection: FirestoreCollections.schedules,
      relatedId: scheduleId,
      scheduledAt: scheduledAt,
    );
  }

  Future<void> createSystemAlert({
    required String title,
    required String body,
    String targetRole = 'all',
  }) {
    return create(
      title: title,
      body: body,
      type: 'system',
      targetRole: targetRole,
    );
  }
}

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
