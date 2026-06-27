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

  String get effectiveRole => AppRoles.effectiveRole(role);
  String get roleLabel => AppRoles.label(role);

  bool get isAdmin => effectiveRole == AppRoles.admin;
  bool get isOperatorLapangan => effectiveRole == AppRoles.operatorLapangan;
  bool get isOperatorKeuangan => effectiveRole == AppRoles.operatorKeuangan;
  bool get isLegacyReadOnly => AppRoles.isLegacyReadOnly(role);

  bool get canViewDashboard => isActive;
  bool get canViewEducation => isActive;
  bool get canManageEducation => isAdmin;
  bool get canDeleteEducation => isAdmin;
  bool get canManageFarmModules => isAdmin;
  bool get canManageUsers => isAdmin;
  bool get canDeleteUsers => isAdmin;

  bool get canViewLogbooks => isActive;
  bool get canManageLogbooks => isAdmin || isOperatorLapangan;
  bool get canDeleteLogbooks => isAdmin;
  bool get canViewInventory => isActive;
  bool get canManageInventory => isAdmin || isOperatorLapangan;
  bool get canDeleteInventory => isAdmin;
  bool get canViewSchedules => isActive;
  bool get canManageSchedules => isAdmin || isOperatorLapangan;
  bool get canDeleteSchedules => isAdmin;

  bool get canViewFinance => isActive;
  bool get canManageFinance => isAdmin || isOperatorKeuangan;
  bool get canDeleteFinance => isAdmin;
  bool get canViewFinanceDashboard => canViewFinance;

  bool get canManageOperations =>
      canManageLogbooks || canManageInventory || canManageSchedules;

  factory AppUser.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return AppUser(
      uid: data['uid'] as String? ?? document.id,
      name: data['name'] as String? ?? 'Pengguna SeiCycle',
      email: data['email'] as String? ?? '',
      photoUrl: data['photo_url'] as String? ?? '',
      role: data['role'] as String? ?? AppRoles.legacyPesertaEdukasi,
      isActive: data['is_active'] as bool? ?? true,
      createdAt: dateTimeFromFirestore(data['created_at']),
      updatedAt: dateTimeFromFirestore(data['updated_at']),
    );
  }
}
