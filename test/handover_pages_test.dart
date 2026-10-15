import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/handover/presentation/handover_controller.dart';
import 'package:bagoo_rider_mobile/features/handover/presentation/handover_issues_page.dart';
import 'package:bagoo_rider_mobile/features/handover/presentation/handover_evidence_page.dart';
import 'package:bagoo_rider_mobile/features/handover/data/handover_models.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/handover_support.dart';

Future<void> reveal(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('handover-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String key) async {
  await reveal(tester, key);
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

Future<
  ({
    HandoverController controller,
    HandoverSession api,
    MemoryHandoverJournal journal,
  })
>
openView(
  WidgetTester tester, {
  bool writes = true,
  double scale = 1,
  String? initialBarcode,
  Future<XFile?> Function()? pickFile,
}) async {
  final api = HandoverSession(), journal = MemoryHandoverJournal();
  final controller = HandoverController(
    testHandoverRepository(api, journal, writes: writes),
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildRiderTheme(),
      home: MediaQuery(
        data: MediaQueryData(
          size: tester.view.physicalSize,
          textScaler: TextScaler.linear(scale),
        ),
        child: HandoverIssuesView(
          controller: controller,
          initialBarcode: initialBarcode,
          pickFile: pickFile,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (controller: controller, api: api, journal: journal);
}

Future<void> fillReport(WidgetTester tester) async {
  for (final entry in {
    'barcode': 'BGO-TEST',
    'reported_holder': 'Known rider',
    'reported_location': 'Assigned hub desk',
    'notes': 'The actual parcel moved without the expected scan.',
  }.entries) {
    await reveal(tester, 'handover-${entry.key}');
    await tester.enterText(
      find.byKey(ValueKey('handover-${entry.key}')),
      entry.value,
    );
  }
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Plus Jakarta Sans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() {
    final old = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = old);
  });
  testWidgets(
    'issue detail separates observations, original/current records and actual receipt guidance',
    (tester) async {
      final h = await openView(tester);
      await tap(tester, 'handover-issue-1');
      expect(find.text('Reported observations'), findsOneWidget);
      expect(find.text('Recorded custody'), findsOneWidget);
      expect(find.text('Original: Custody not established'), findsOneWidget);
      expect(find.text('Current: Custody not established'), findsOneWidget);
      await reveal(tester, 'handover-acknowledge');
      expect(find.text('I physically hold this exact parcel'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('handover-acknowledge')),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.text('Only actual authorized hub receipt clears a recovery hold.'),
        findsOneWidget,
      );
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      await tap(tester, 'handover-back');
      expect(find.text('Handover issues'), findsOneWidget);
      expect(find.text('Reported observations'), findsNothing);
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    },
  );
  testWidgets(
    'report fields and original file remain after server validation errors',
    (tester) async {
      final h = await openView(
        tester,
        pickFile: () async =>
            XFile.fromData(pngEvidence, path: 'actual-evidence.png'),
      );
      await tap(tester, 'handover-new-report');
      await fillReport(tester);
      await tap(tester, 'handover-pick-evidence');
      expect(find.text('actual-evidence.png'), findsOneWidget);
      h.api.handler = (path, method, data, headers) async {
        if (method == 'POST') {
          throw const AccountFailure(
            'Please clarify',
            status: 422,
            fields: {
              'notes': 'Explain the actual missed scan.',
              'evidence': 'Use the original observed evidence.',
            },
          );
        }
        return h.api.reply(path);
      };
      await tap(tester, 'handover-submit-report');
      expect(
        h.controller.failure!.fields['notes'],
        'Explain the actual missed scan.',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('handover-notes')))
            .controller!
            .text,
        'The actual parcel moved without the expected scan.',
      );
      expect(find.text('actual-evidence.png'), findsOneWidget);
      expect(find.text('Use the original observed evidence.'), findsOneWidget);
      expect(h.controller.pendingIntent, isNull);
      expect(h.controller.canWrite, true);
    },
  );
  testWidgets(
    'invalid file choice keeps the prior original evidence and no report is sent',
    (tester) async {
      var choices = 0;
      final h = await openView(
        tester,
        pickFile: () async => choices++ == 0
            ? XFile.fromData(pngEvidence, path: 'original.png')
            : XFile.fromData(Uint8List.fromList([1, 2, 3]), path: 'fake.pdf'),
      );
      await tap(tester, 'handover-new-report');
      await tap(tester, 'handover-pick-evidence');
      await tap(tester, 'handover-pick-evidence');
      expect(find.text('original.png'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('handover-evidence-error')),
        findsOneWidget,
      );
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    },
  );
  testWidgets(
    'cancelled picker and missing file remain honest without dispatch',
    (tester) async {
      final h = await openView(tester, pickFile: () async => null);
      await tap(tester, 'handover-new-report');
      await fillReport(tester);
      await tap(tester, 'handover-pick-evidence');
      await tap(tester, 'handover-submit-report');
      expect(
        find.text('Choose actual evidence before reporting.'),
        findsOneWidget,
      );
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    },
  );
  testWidgets(
    'confirmed report opens current detail and does not fabricate custody or receipt',
    (tester) async {
      final h = await openView(
        tester,
        pickFile: () async => XFile.fromData(pngEvidence, path: 'original.png'),
      );
      h.api.detailBody = handoverFixture('detail');
      h.api.handler = (path, method, data, headers) async {
        if (method == 'POST') return handoverCommand((await h.journal.read())!);
        return h.api.reply(path);
      };
      await tap(tester, 'handover-new-report');
      await fillReport(tester);
      await tap(tester, 'handover-pick-evidence');
      await tap(tester, 'handover-submit-report');
      expect(find.text('Handover issue'), findsOneWidget);
      expect(find.text('Pending review'), findsOneWidget);
      expect(h.controller.selected!.held, false);
      expect(h.controller.selected!.recovery, isNull);
      expect(h.api.calls.where((c) => c.method == 'POST').length, 1);
    },
  );
  testWidgets(
    'changed source resets possession; a fresh acknowledgement still retains the hold',
    (tester) async {
      final h = await openView(tester);
      await tap(tester, 'handover-issue-1');
      await reveal(tester, 'handover-possession');
      await tester.tap(find.byKey(const ValueKey('handover-possession')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('handover-possession')),
            )
            .value,
        true,
      );
      h.api.detailBody['data']['recovery']['expected_version'] = 5;
      h.api.detailBody['data']['version'] = 5;
      h.api.detailBody['data']['recovery']['source_token'] = '0' * 64;
      await h.controller.refresh();
      await tester.pumpAndSettle();
      await reveal(tester, 'handover-possession');
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('handover-possession')),
            )
            .value,
        false,
      );
      await reveal(tester, 'handover-ack-barcode');
      await tester.enterText(
        find.byKey(const ValueKey('handover-ack-barcode')),
        h.controller.selected!.tracking,
      );
      await reveal(tester, 'handover-ack-notes');
      await tester.enterText(
        find.byKey(const ValueKey('handover-ack-notes')),
        'I physically hold this actual parcel.',
      );
      h.api.handler = (path, method, data, headers) async {
        if (method == 'POST') {
          h.api.detailBody['data']['recovery']['acknowledged'] = true;
          h.api.detailBody['data']['recovery']['actions']['acknowledge'] =
              false;
          return handoverCommand((await h.journal.read())!);
        }
        return h.api.reply(path);
      };
      await tap(tester, 'handover-possession');
      await tap(tester, 'handover-acknowledge');
      expect(h.controller.selected!.held, true);
      expect(h.controller.selected!.recovery!.acknowledged, true);
      expect(
        find.text(
          'Possession acknowledgement recorded. Keep the parcel until the named hub records receipt.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'known unavailable deployment disables reports without replacing account access',
    (tester) async {
      final h = await openView(tester, writes: false);
      expect(
        find.text(
          'Reporting and acknowledgement await handover deployment verification.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('handover-new-report')),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, 'handover-issue-1');
      await reveal(tester, 'handover-acknowledge');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('handover-acknowledge')),
            )
            .onPressed,
        isNull,
      );
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    },
  );
  testWidgets('Escape returns from report to list and clears unsent evidence', (
    tester,
  ) async {
    await openView(
      tester,
      pickFile: () async => XFile.fromData(pngEvidence, path: 'original.png'),
    );
    await tap(tester, 'handover-new-report');
    await tap(tester, 'handover-pick-evidence');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Handover issues'), findsOneWidget);
    expect(find.text('original.png'), findsNothing);
  });
  testWidgets(
    'background evidence is cleared; resume revalidates permission before showing bytes',
    (tester) async {
      final api = HandoverSession(),
          journal = MemoryHandoverJournal(),
          repo = testHandoverRepository(api, journal);
      final detail = HandoverDetail.fromJson(api.detailBody['data']);
      final failures = <Object>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRiderTheme(),
          home: HandoverEvidencePage(
            repository: repo,
            detail: detail,
            onFailure: (error) async {
              failures.add(error);
            },
            documentBuilder: (_) => const Text('Authorized test document'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Authorized test document'), findsOneWidget);
      // Inactive still permits a frame so the cleared view can be inspected;
      // paused suspends Flutter frames until resume.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.text('Authorized test document'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      api.downloadHandler = (_) async =>
          throw const AccountFailure('Evidence access removed', status: 404);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Evidence access removed'), findsOneWidget);
      expect(find.text('Authorized test document'), findsNothing);
      expect(failures.length, 1);
      expect(api.downloads.length, 2);
    },
  );
  for (final width in [320.0, 390.0, 840.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'handover list, report and acknowledgement stay usable at $width / $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final h = await openView(
            tester,
            scale: scale,
            pickFile: () async => null,
            initialBarcode: 'BGO-${'LONG-REFERENCE-' * 10}',
          );
          await tap(tester, 'handover-new-report');
          await fillReport(tester);
          await reveal(tester, 'handover-submit-report');
          expect(
            tester
                .getSize(find.byKey(const ValueKey('handover-submit-report')))
                .height,
            greaterThanOrEqualTo(48),
          );
          expect(tester.takeException(), isNull);
          await tap(tester, 'handover-back');
          await tap(tester, 'handover-issue-1');
          await reveal(tester, 'handover-possession');
          await reveal(tester, 'handover-acknowledge');
          expect(
            tester
                .getSize(find.byKey(const ValueKey('handover-acknowledge')))
                .height,
            greaterThanOrEqualTo(48),
          );
          expect(tester.takeException(), isNull);
          expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
        },
      );
    }
  }
}
