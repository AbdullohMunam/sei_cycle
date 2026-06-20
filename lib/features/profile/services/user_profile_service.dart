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
        'role': AppRoles.mitra,
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

  Future<void> updateName(String uid, String name) {
    return _users.doc(uid).update({
      'name': name.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
