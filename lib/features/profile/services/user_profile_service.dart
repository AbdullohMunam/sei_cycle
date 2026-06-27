import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/constants/firestore_collections.dart';
import '../models/app_user.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  Future<void> ensureUserDocument(User user, {String? name}) async {
    final reference = _users.doc(user.uid);
    final snapshot = await reference.get();
    final now = FieldValue.serverTimestamp();

    if (!snapshot.exists) {
      await reference.set({
        'uid': user.uid,
        'name': name?.trim().isNotEmpty == true
            ? name!.trim()
            : (user.displayName?.trim().isNotEmpty == true
                  ? user.displayName!.trim()
                  : 'Pengguna SeiCycle'),
        'email': user.email ?? '',
        'photo_url': user.photoURL ?? '',
        'role': AppRoles.defaultRole,
        'is_active': true,
        'created_at': now,
        'updated_at': now,
      });
      return;
    }

    final resolvedName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : user.displayName?.trim();
    await reference.set({
      'uid': user.uid,
      'email': user.email ?? '',
      'photo_url': user.photoURL ?? '',
      if (resolvedName?.isNotEmpty == true) 'name': resolvedName,
      'updated_at': now,
    }, SetOptions(merge: true));
  }

  Stream<AppUser?> watchProfile(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists ? AppUser.fromDocument(snapshot) : null,
        );
  }

  Stream<List<AppUser>> watchUsers() {
    return _users.snapshots().map((snapshot) {
      final users = snapshot.docs.map(AppUser.fromDocument).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return users;
    });
  }

  Future<void> updateName(String uid, String name) {
    return _users.doc(uid).update({
      'name': name.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRole({
    required String uid,
    required String role,
    bool? isActive,
  }) {
    final assignableRole = AppRoles.assignableRole(role);
    if (!AppRoles.isAssignable(assignableRole)) {
      throw ArgumentError.value(role, 'role', 'Role tidak dapat diberikan.');
    }

    return _users.doc(uid).update({
      'role': assignableRole,
      ...(isActive == null
          ? const <String, Object?>{}
          : {'is_active': isActive}),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
