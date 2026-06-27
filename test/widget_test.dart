import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sei_cycle/core/constants/app_roles.dart';
import 'package:sei_cycle/core/constants/farm_modules.dart';
import 'package:sei_cycle/core/widgets/app_ui.dart';
import 'package:sei_cycle/core/widgets/async_state_widgets.dart';
import 'package:sei_cycle/core/widgets/feature_page.dart';
import 'package:sei_cycle/features/auth/screen/widgets/auth_frame.dart';
import 'package:sei_cycle/features/profile/models/app_user.dart';
import 'package:sei_cycle/theme/app_theme.dart';

void main() {
  test('five default farm modules are available', () {
    expect(FarmModules.values, hasLength(5));
    expect(FarmModules.values.map((module) => module.id), contains('lele'));
  });

  test('async snapshot errors are shown instead of loading forever', () {
    final snapshot = AsyncSnapshot<List<String>>.withError(
      ConnectionState.active,
      StateError('permission denied'),
    );

    final state = asyncSnapshotState(snapshot);

    expect(state, isA<ErrorState>());
    expect((state! as ErrorState).message, contains('permission denied'));
  });

  test('async snapshot without data shows loading state', () {
    const snapshot = AsyncSnapshot<List<String>>.nothing();

    expect(asyncSnapshotState(snapshot), isA<LoadingState>());
  });

  test('async snapshot with data leaves rendering to the caller', () {
    final snapshot = AsyncSnapshot.withData(ConnectionState.active, <String>[]);

    expect(asyncSnapshotState(snapshot), isNull);
  });

  test('async snapshot can treat an emitted null as loaded data', () {
    const snapshot = AsyncSnapshot<String?>.withData(
      ConnectionState.active,
      null,
    );

    expect(asyncSnapshotState(snapshot, allowNullData: true), isNull);
  });

  test('seicycle role capabilities match the current brief', () {
    final admin = _userWithRole(AppRoles.admin);
    final operatorLapangan = _userWithRole(AppRoles.operatorLapangan);
    final operatorKeuangan = _userWithRole(AppRoles.operatorKeuangan);

    expect(admin.canManageLogbooks, isTrue);
    expect(admin.canManageFinance, isTrue);
    expect(admin.canDeleteLogbooks, isTrue);
    expect(admin.canDeleteInventory, isTrue);
    expect(admin.canDeleteSchedules, isTrue);
    expect(admin.canDeleteFinance, isTrue);
    expect(admin.canDeleteEducation, isTrue);
    expect(_userWithRole(' Admin ').isAdmin, isTrue);
    expect(_userWithRole('ADMIN').canManageFinance, isTrue);
    expect(_userWithRole('ADMIN').canDeleteFinance, isTrue);

    for (final user in [admin, operatorLapangan, operatorKeuangan]) {
      expect(user.canViewLogbooks, isTrue);
      expect(user.canViewInventory, isTrue);
      expect(user.canViewSchedules, isTrue);
      expect(user.canViewFinance, isTrue);
    }

    expect(operatorLapangan.canManageLogbooks, isTrue);
    expect(operatorLapangan.canManageInventory, isTrue);
    expect(operatorLapangan.canManageSchedules, isTrue);
    expect(operatorLapangan.canManageFinance, isFalse);
    expect(operatorLapangan.canDeleteLogbooks, isFalse);
    expect(operatorLapangan.canDeleteInventory, isFalse);
    expect(operatorLapangan.canDeleteSchedules, isFalse);

    expect(operatorKeuangan.canManageLogbooks, isFalse);
    expect(operatorKeuangan.canManageInventory, isFalse);
    expect(operatorKeuangan.canManageSchedules, isFalse);
    expect(operatorKeuangan.canManageFinance, isTrue);
    expect(operatorKeuangan.canDeleteFinance, isFalse);
    expect(operatorKeuangan.canViewFinanceDashboard, isTrue);
  });

  test('legacy roles stay migration-safe', () {
    final legacyOperator = _userWithRole(AppRoles.legacyOperator);
    final legacyMitra = _userWithRole(AppRoles.legacyMitra);
    final pesertaEdukasi = _userWithRole(AppRoles.legacyPesertaEdukasi);

    expect(legacyOperator.effectiveRole, AppRoles.operatorLapangan);
    expect(legacyOperator.canManageLogbooks, isTrue);

    for (final user in [legacyMitra, pesertaEdukasi]) {
      expect(user.canViewDashboard, isTrue);
      expect(user.canViewEducation, isTrue);
      expect(user.canViewLogbooks, isTrue);
      expect(user.canViewInventory, isTrue);
      expect(user.canViewSchedules, isTrue);
      expect(user.canViewFinance, isTrue);
      expect(user.canManageLogbooks, isFalse);
      expect(user.canManageInventory, isFalse);
      expect(user.canManageSchedules, isFalse);
      expect(user.canManageFinance, isFalse);
      expect(user.canDeleteLogbooks, isFalse);
      expect(user.canDeleteInventory, isFalse);
      expect(user.canDeleteSchedules, isFalse);
      expect(user.canDeleteFinance, isFalse);
    }
  });

  testWidgets('auth layout fits a compact Android viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AuthFrame(
          title: 'Masuk ke SeiCycle',
          subtitle: 'Lanjutkan pencatatan operasional Kebun Sei.',
          child: Column(
            children: [
              TextField(decoration: InputDecoration(labelText: 'Email')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Password')),
              SizedBox(height: 20),
              FilledButton(onPressed: null, child: Text('Masuk')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Masuk ke SeiCycle'), findsOneWidget);
  });

  testWidgets('feature page and form row avoid overflow on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: FeaturePage(
            title: 'Logbook Operasional',
            subtitle: 'Catatan harian Kebun Sei.',
            actions: const [
              FilledButton(onPressed: null, child: Text('Tambah')),
            ],
            child: ListView(
              children: const [
                AppCard(
                  child: ResponsiveFormRow(
                    children: [
                      TextField(
                        decoration: InputDecoration(labelText: 'Jumlah'),
                      ),
                      TextField(
                        decoration: InputDecoration(labelText: 'Satuan'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Logbook Operasional'), findsOneWidget);
  });
}

AppUser _userWithRole(String role) {
  final now = DateTime(2026);
  return AppUser(
    uid: 'uid-$role',
    name: 'Pengguna $role',
    email: '$role@example.com',
    photoUrl: '',
    role: role,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}
