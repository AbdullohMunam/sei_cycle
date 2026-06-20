import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/utils/firestore_dates.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAdmin => role == AppRoles.admin;
  bool get isOperator => role == AppRoles.operator;
  bool get canManageOperations => isAdmin || isOperator;

  factory AppUser.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return AppUser(
      uid: data['uid'] as String? ?? document.id,
      name: data['name'] as String? ?? 'Pengguna SeiCycle',
      email: data['email'] as String? ?? '',
      photoUrl: data['photo_url'] as String? ?? '',
      role: data['role'] as String? ?? AppRoles.mitra,
      isActive: data['is_active'] as bool? ?? true,
      createdAt: dateTimeFromFirestore(data['created_at']),
      updatedAt: dateTimeFromFirestore(data['updated_at']),
    );
  }
}
