import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_validation.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/ui/private_image.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/parcels/data/parcel_photo_service.dart';
import 'package:bagoo_rider_mobile/features/parcels/presentation/parcel_action_page.dart';
import 'package:bagoo_rider_mobile/features/parcels/presentation/parcel_outcome_fields.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/parcel_support.dart';
import 'support/photo_support.dart';

const _renderKey = ValueKey('parcel-form-render');
Future<void> _render(
  WidgetTester tester,
  String name, {
  bool top = false,
}) async {
  if (!const bool.fromEnvironment('RIDER_WORK_RENDER')) return;
  if (top) {
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_renderKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/operations-delivery-verification/screens');
    await folder.create(recursive: true);
    await File('${folder.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

class _Outcome {
  _Outcome(ParcelAction action, {bool prepaid = false})
    : domain = ParcelHarness(action: action) {
    if (prepaid) {
      domain.taskJson['payment'] = {
        'method': 'wallet',
        'commercial_payment_status': 'paid',
        'cod_due_cents': null,
      };
      domain.taskJson['stop']['kind'] = 'buyer';
    }
    photos = ParcelPhotoService(
      origin: Uri.parse('https://example.test/api/v1'),
      accountId: '5',
      proofs: domain.proofs,
      isCurrent: () => domain.current,
      picker: TestParcelPhotoPicker(),
    );
    work = WorkspaceController(
      domain.restart(photos: photos, prepaidEnabled: prepaid),
    );
    domain.api.respond = respond;
  }
  final ParcelHarness domain;
  late final WorkspaceController work;
  late final ParcelPhotoService photos;
  final sent = <FormData>[];
  bool rejectRecipient = false, _disposed = false;
  Future<void> open() async {
    await Future<void>.delayed(Duration.zero);
    await work.openTask(OperationsRepository.asRiderTask(domain.task));
  }

  Future<Map<String, dynamic>> respond(
    String path,
    String method,
    Object? body,
    Map<String, String> headers,
  ) async {
    if (method == 'POST') {
      sent.add(body as FormData);
      if (rejectRecipient) {
        throw const AccountFailure(
          'Check the recipient.',
          status: 422,
          fields: {'recipient_name': 'Use the actual recipient name.'},
        );
      }
      final result = parcelCommand(domain.journal.value!);
      domain.taskJson['operational_stage'] = domain.action.recordedStage;
      domain.taskJson['version'] = 'b' * 64;
      domain.taskJson['actions']['deliver'] = false;
      domain.taskJson['actions']['fail'] = false;
      if (domain.action == ParcelAction.fail) {
        domain.taskJson['stop']['kind'] = 'destination_hub';
        domain.taskJson['next_instruction'] = 'Return the parcel to the destination hub. Its handler records receipt and any retry.';
        domain.taskJson['failure_policy']['recorded_attempts'] = 2;
      }
      return result;
    }
    if (path == 'rider/tasks/${domain.task.id}' &&
        domain.task.stage == 'delivered') {
      throw const AccountFailure('Hidden terminal task', status: 404);
    }
    return domain.standardResponse(path, method, body, headers);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    work.dispose();
    photos.dispose();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

Future<void> _mount(WidgetTester tester, _Outcome h, {double scale = 1}) async {
  await tester.runAsync(h.open);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildRiderTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _renderKey, child: child!),
      ),
      home: ParcelActionPage(
        work: h.work,
        taskId: h.domain.task.id,
        action: h.domain.action,
        cameraAvailable: true,
        scan: (_, _) async => h.domain.task.tracking,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _tap(tester, find.byKey(const ValueKey('parcel-scan')));
  await _tap(tester, find.byKey(const ValueKey('parcel-photo-choose')));
}

Future<void> _deliveryFields(
  WidgetTester tester,
  _Outcome h, {
  bool cash = true,
}) async {
  await _enter(tester, 'parcel-recipient', 'Software Test Recipient');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await _tap(
    tester,
    find.byKey(ValueKey('parcel-relationship-${h.domain.task.version}')),
  );
  await tester.tap(find.text('Buyer').last);
  await tester.pumpAndSettle();
  if (!cash) return;
  await _enter(tester, 'parcel-cash-received', '200.00');
  await _enter(tester, 'parcel-change-given', '75.00');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await _tap(tester, find.byKey(const ValueKey('parcel-cash-confirmed')));
}

void main() {
  test('software-test proof decodes as an original image', () async {
    final codec = await ui.instantiateImageCodec(parcelTestPng());
    try {
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1);
      expect(frame.image.height, 1);
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
  });
  setUpAll(() async {
    if (!const bool.fromEnvironment('RIDER_WORK_RENDER')) return;
    await (FontLoader(
      'Plus Jakarta Sans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'changed payment clears reviewed proof and cash without a version change',
    (tester) async {
      final h = _Outcome(ParcelAction.deliver);
      addTearDown(h.dispose);
      await _mount(tester, h);
      await _deliveryFields(tester, h);
      final fields = tester.state<ParcelOutcomeFieldsState>(
        find.byType(ParcelOutcomeFields),
      );
      expect(fields.ready, isTrue);
      expect(fields.cashConfirmed, isTrue);
      final version = h.domain.task.version;
      h.domain.taskJson['payment']['cod_due_cents'] = '12600';
      await _tap(tester, find.byKey(const ValueKey('parcel-refresh')));
      expect(h.domain.task.version, version);
      expect(fields.proof, isNull);
      expect(fields.cashConfirmed, isFalse);
      expect(fields.received.text, isEmpty);
      expect(fields.change.text, isEmpty);
      expect(fields.ready, isFalse);
      expect(h.sent, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      h.dispose();
    },
  );
  for (final width in [320.0, 840.0]) {
    testWidgets(
      'paid wallet delivery keeps recipient proof and omits cash at width $width with 200 percent text',
      (tester) async {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = _Outcome(ParcelAction.deliver, prepaid: true);
        addTearDown(h.dispose);
        await _mount(tester, h, scale: 2);
        await _deliveryFields(tester, h, cash: false);
        final instruction = find.byKey(
          const ValueKey('parcel-payment-instruction'),
        );
        await tester.ensureVisible(instruction);
        await tester.pumpAndSettle();
        expect(find.text('Paid — no cash to collect'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('parcel-cash-received')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('parcel-change-given')), findsNothing);
        expect(
          find.byKey(const ValueKey('parcel-cash-confirmed')),
          findsNothing,
        );
        await _render(tester, 'prepaid-deliver-${width.toInt()}-payment');
        expect(tester.takeException(), isNull);
        await _tap(tester, find.byKey(const ValueKey('parcel-submit')));
        expect(find.text('Delivery recorded'), findsOneWidget);
        expect(h.sent, hasLength(1));
        final fields = Map.fromEntries(h.sent.single.fields);
        expect(fields['recipient_name'], 'Software Test Recipient');
        expect(fields['recipient_relationship'], 'buyer');
        expect(
          fields.keys.any((k) => k.startsWith('cash') || k == 'change_given'),
          isFalse,
        );
        expect(h.sent.single.files.single.key, 'proof_image_file');
        expect(h.work.selectedTask, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        h.dispose();
      },
    );
  }
  for (final width in [320.0, 840.0]) {
    testWidgets(
      'COD form records actual recipient original proof and exact cash at width $width with 200 percent text',
      (tester) async {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = _Outcome(ParcelAction.deliver);
        addTearDown(h.dispose);
        await _mount(tester, h, scale: 2);
        await _render(tester, 'parcel-deliver-${width.toInt()}-top', top: true);
        await _deliveryFields(tester, h);
        await _render(tester, 'parcel-deliver-${width.toInt()}-confirm');
        expect(tester.takeException(), isNull);
        await _tap(tester, find.byKey(const ValueKey('parcel-submit')));
        expect(find.text('Delivery recorded'), findsOneWidget);
        expect(h.sent, hasLength(1));
        final fields = Map.fromEntries(h.sent.single.fields);
        expect(fields['recipient_name'], 'Software Test Recipient');
        expect(fields['recipient_relationship'], 'buyer');
        expect(fields['cash_received'], '200.00');
        expect(fields['change_given'], '75.00');
        expect(fields['cash_confirmed'], '1');
        expect(
          await tester.runAsync(
            () => h.sent.single.files.single.value
                .finalize()
                .expand((v) => v)
                .toList(),
          ),
          parcelTestPng(),
        );
        expect(h.work.selectedTask, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        h.dispose();
      },
    );
  }
  testWidgets(
    'mismatched cash does not dispatch and focuses a visible validation summary',
    (tester) async {
      final h = _Outcome(ParcelAction.deliver);
      addTearDown(h.dispose);
      await _mount(tester, h);
      await _deliveryFields(tester, h);
      await _enter(tester, 'parcel-change-given', '74.99');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('parcel-submit')));
      expect(h.sent, isEmpty);
      expect(
        find.textContaining('Check the highlighted fields'),
        findsOneWidget,
      );
      expect(
        find.text('Received cash minus change must equal COD.'),
        findsOneWidget,
      );
      expect(h.domain.journal.value, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      h.dispose();
    },
  );
  testWidgets(
    'field rejection keeps the photo and safe input for an explicit corrected submission',
    (tester) async {
      final h = _Outcome(ParcelAction.deliver);
      addTearDown(h.dispose);
      h.rejectRecipient = true;
      await _mount(tester, h);
      await _deliveryFields(tester, h);
      await _tap(tester, find.byKey(const ValueKey('parcel-submit')));
      expect(h.sent, hasLength(1));
      expect(find.text('Use the actual recipient name.'), findsWidgets);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('parcel-cash-received')),
            )
            .controller!
            .text,
        '200.00',
      );
      expect(find.byType(PrivateImage), findsOneWidget);
      h.rejectRecipient = false;
      await _enter(tester, 'parcel-recipient', 'Corrected Test Recipient');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('parcel-submit')));
      expect(find.text('Delivery recorded'), findsOneWidget);
      expect(h.sent, hasLength(2));
      await tester.pumpWidget(const SizedBox.shrink());
      h.dispose();
    },
  );
  testWidgets(
    'failure requires the server reason notes location and proof then keeps hub return responsibility',
    (tester) async {
      final h = _Outcome(ParcelAction.fail);
      addTearDown(h.dispose);
      await _mount(tester, h);
      await _render(tester, 'parcel-failure-form', top: true);
      await _tap(tester, find.byKey(const ValueKey('parcel-submit')));
      expect(h.sent, isEmpty);
      expect(
        find.text('Describe what happened during this attempt.'),
        findsOneWidget,
      );
      await _tap(
        tester,
        find.byKey(ValueKey('parcel-failure-reason-${h.domain.task.version}')),
      );
      await tester.tap(find.text('customer unavailable').last);
      await tester.pumpAndSettle();
      await _enter(
        tester,
        'parcel-failure-location',
        'Software test delivery stop',
      );
      await _enter(
        tester,
        'parcel-notes',
        'Software test recipient was not available at the agreed stop.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('parcel-submit')));
      expect(find.text('Attempt recorded'), findsOneWidget);
      expect(h.sent, hasLength(1));
      expect(
        Map.fromEntries(h.sent.single.fields)['reason'],
        'customer_unavailable',
      );
      expect(h.work.selectedTask?.stop.kind, 'destination_hub');
      expect(h.work.selectedTask?.failurePolicy?.recordedAttempts, 2);
      expect(
        h.work.selectedTask?.nextInstruction,
        contains('handler records receipt'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      h.dispose();
    },
  );
  testWidgets(
    'private image display cache is evicted when its screen is removed',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivateImage(
              bytes: parcelTestPng(),
              label: 'Private software-test proof',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final provider = tester.widget<Image>(find.byType(Image)).image;
      final key = await provider.obtainKey(ImageConfiguration.empty);
      final before = PaintingBinding.instance.imageCache.statusForKey(key);
      expect(before.live || before.pending || before.keepAlive, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final after = PaintingBinding.instance.imageCache.statusForKey(key);
      expect(after.live || after.pending || after.keepAlive, isFalse);
    },
  );
}
