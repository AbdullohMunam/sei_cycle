import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sei_cycle/core/constants/farm_modules.dart';
import 'package:sei_cycle/core/widgets/app_ui.dart';
import 'package:sei_cycle/core/widgets/async_state_widgets.dart';
import 'package:sei_cycle/core/widgets/feature_page.dart';
import 'package:sei_cycle/features/auth/screen/widgets/auth_frame.dart';
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
