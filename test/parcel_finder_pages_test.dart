import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/stop_mode_page.dart';
import 'package:bagoo_rider_mobile/features/parcel_finder/data/parcel_location_labels.dart';
import 'package:bagoo_rider_mobile/features/parcel_finder/presentation/parcel_finder_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/parcel_finder_support.dart';
import 'support/test_auth_repository.dart';

final capture = GlobalKey();
Widget app(Widget home, {double scale = 1}) => MaterialApp(
  theme: buildRiderTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: RepaintBoundary(key: capture, child: child!),
  ),
  home: home,
);

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> render(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(capture),
  );
  await tester.runAsync(() async {
    final picture = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/parcel-finder-verification/ui');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Plus Jakarta Sans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final (size, scale) in [
    (const Size(320, 740), 2.0),
    (const Size(375, 812), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(900, 480), 2.0),
    (const Size(1200, 850), 1.0),
  ]) {
    testWidgets(
      'slot picker scrolls and stays accessible at $size with ${scale}x text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        try {
          ParcelSlot? saved;
          final task = OperationTask.fromJson(
            finderTaskJson(tracking: 'BGO-TESTABCDEFGHIJ'),
          );
          await tester.pumpWidget(
            app(
              Scaffold(
                appBar: AppBar(title: const Text('Parcel Finder')),
                body: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          StatefulBuilder(
                            builder: (context, rebuild) => ParcelFinderCard(
                              task: task,
                              location: saved,
                              suffix: 'EFGHIJ',
                              enabled: true,
                              save: (slot) async {
                                rebuild(() => saved = slot);
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          await tap(tester, 'parcel-finder-edit');
          await tester.ensureVisible(
            find.byKey(const ValueKey('parcel-slot-topBoxLeft')),
          );
          await tester.pumpAndSettle();
          await render(tester, 'picker-${size.width.toInt()}-${scale}x');
          for (final slot in ParcelSlot.values) {
            final target = find.byKey(ValueKey('parcel-slot-${slot.name}'));
            await tester.ensureVisible(target);
            await tester.pumpAndSettle();
            expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
            expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
          }
          await tap(tester, 'parcel-slot-bag2');
          expect(saved, ParcelSlot.bag2);
          expect(find.text('Planned: Bag 2'), findsOneWidget);
          await tap(tester, 'parcel-finder-edit');
          await tester.ensureVisible(
            find.byKey(const ValueKey('parcel-slot-bag2')),
          );
          await tester.pumpAndSettle();
          expect(
            tester.getSemantics(find.byKey(const ValueKey('parcel-slot-bag2'))),
            matchesSemantics(
              isButton: true,
              isEnabled: true,
              hasEnabledState: true,
              isFocusable: true,
              isSelected: true,
              hasSelectedState: true,
              label: 'Bag 2',
              hasTapAction: true,
              hasFocusAction: true,
            ),
          );
          await tap(tester, 'parcel-finder-clear');
          expect(saved, isNull);
          expect(find.text('Location not set'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'duplicate taps wait for verification and failure retains the original location',
    (tester) async {
      var calls = 0;
      final pending = Completer<String?>();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: ListView(
              children: [
                ParcelFinderCard(
                  task: OperationTask.fromJson(finderTaskJson()),
                  location: ParcelSlot.bag1,
                  suffix: '000031',
                  enabled: true,
                  save: (_) {
                    calls++;
                    return pending.future;
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'parcel-finder-edit');
      await tester.tap(find.byKey(const ValueKey('parcel-slot-bag2')));
      await tester.pump();
      expect(find.text('Verifying this parcel…'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('parcel-slot-bag2')),
            )
            .onPressed,
        isNull,
      );
      expect(calls, 1);
      pending.complete('Could not verify the current assignment.');
      await tester.pumpAndSettle();
      expect(find.text('Planned: Bag 1'), findsOneWidget);
      expect(
        find.text('Could not verify the current assignment.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'actual owned Stop Mode saves a planned label, keeps full tracking and never records a scan',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = ParcelFinderHarness();
      addTearDown(h.dispose);
      await tester.pump();
      final auth = TestAuthRepository()
        ..account = const RiderAccount(
          id: '5',
          name: 'Software Test Rider',
          email: 'rider@example.test',
          status: 'active',
          kycStatus: 'approved',
          approved: true,
          emailVerified: true,
          operationsApiVersion: 1,
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(auth)],
          child: app(
            StopModePage(
              initialTask: OperationsRepository.asRiderTask(h.task()),
              controller: h.work,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final target = find.byKey(const ValueKey('parcel-finder-edit'));
      await tester.scrollUntilVisible(
        target,
        250,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('stop-mode-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tap(tester, 'parcel-finder-edit');
      h.api.calls.clear();
      await tap(tester, 'parcel-slot-topBoxLeft');
      expect(h.work.parcelLocationFor(h.task()), ParcelSlot.topBoxLeft);
      expect(find.text('Planned: Top box left'), findsOneWidget);
      expect(h.api.calls.single.path, 'rider/tasks/pickup-31');
      expect(h.api.calls.single.method, 'GET');
      expect(h.journal.value, isNull);
      expect(h.task().heldByMe, isFalse);
      await render(tester, 'owned-stop-375');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('stop-tracking')),
        -200,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('stop-mode-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.byKey(const ValueKey('stop-tracking')), findsOneWidget);
      expect(find.text(h.task().tracking), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tap(tester, 'parcel-finder-edit');
      h.detailFailure = const AccountFailure('Access denied.', status: 403);
      await tap(tester, 'parcel-slot-bag2');
      expect(h.labels.location(h.task()), isNull);
      expect(find.text('Planned: Top box left'), findsNothing);
      expect(find.byKey(const ValueKey('parcel-finder-edit')), findsNothing);
      expect(tester.takeException(), isNull);
      h.work.setForeground(false);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
