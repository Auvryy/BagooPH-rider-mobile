import 'dart:io';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';

import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/messages/presentation/messages_page.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/messages_support.dart';

final capture = GlobalKey();
Widget app(WorkspaceController work, {double scale = 1, bool active = true}) =>
    ProviderScope(
      child: MaterialApp(
        theme: buildRiderTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: RepaintBoundary(key: capture, child: child!),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
                ? null
                : const SizedBox(
                    height: 64,
                    child: Center(child: Text('App navigation')),
                  ),
            body: SafeArea(
              child: MessagesPage(
                controller: work,
                preview: false,
                active: active,
              ),
            ),
          ),
        ),
      ),
    );
Future<void> render(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(capture),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/messages-verification/ui');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
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
    (const Size(1200, 850), 1.0),
    (const Size(900, 480), 2.0),
  ]) {
    testWidgets(
      'paged Messages list and thread fit $size with ${scale}x text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = MessagesHarness();
        addTearDown(h.dispose);
        final work = WorkspaceController(
          const UnavailableWorkspaceRepository(),
          messagesRepository: h.repository,
        );
        addTearDown(work.dispose);
        await tester.pumpWidget(app(work, scale: scale));
        await tester.pumpAndSettle();
        expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
        await render(tester, 'inbox-${size.width.toInt()}-${scale}x');
        await tap(tester, 'conversation-$pickupThread');
        expect(work.messages.thread!.participantId, '3');
        expect(tester.takeException(), isNull);
        final send = find.byKey(const ValueKey('send-message'));
        await tester.ensureVisible(send);
        await tester.pumpAndSettle();
        expect(tester.getSize(send).height, greaterThanOrEqualTo(48));
        await tester.enterText(
          find.byKey(const ValueKey('message-draft')),
          'I am at the shop entrance.',
        );
        await tester.pumpAndSettle();
        await render(tester, 'thread-${size.width.toInt()}-${scale}x');
        await tap(tester, 'send-message');
        expect(
          h.api.calls.where(
            (c) => c.method == 'POST' && c.path.endsWith('/messages'),
          ),
          hasLength(1),
        );
        expect(work.messages.draft, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'the composer remains reachable above a phone keyboard at ${scale}x text',
      (tester) async {
        tester.view.physicalSize = const Size(375, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final h = MessagesHarness();
        addTearDown(h.dispose);
        final work = WorkspaceController(
          const UnavailableWorkspaceRepository(),
          messagesRepository: h.repository,
        );
        addTearDown(work.dispose);
        await tester.pumpWidget(app(work, scale: scale));
        await tester.pumpAndSettle();
        await tap(tester, 'conversation-$pickupThread');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        final input = find.byKey(const ValueKey('message-draft'));
        await tester.ensureVisible(input);
        await tester.enterText(input, 'Parcel update.');
        await tester.pumpAndSettle();
        final send = find.byKey(const ValueKey('send-message'));
        await tester.ensureVisible(send);
        await tester.pumpAndSettle();
        expect(tester.getRect(send).bottom, lessThanOrEqualTo(440));
        expect(tester.getRect(input).bottom, lessThanOrEqualTo(440));
        expect(find.text('App navigation'), findsNothing);
        expect(tester.takeException(), isNull);
        await render(tester, 'keyboard-${scale}x');
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'a new offscreen arrival preserves scroll and remains unread until displayed',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = MessagesHarness();
      addTearDown(h.dispose);
      bool arrived = false;
      h.api.respond = (path, method, body, headers) async {
        if (path.contains('/messages?')) {
          return historyEnvelope(parcelConversationJson(unread: 20), [
            for (var id = arrived ? 101 : 100; id >= (arrived ? 82 : 81); id--)
              parcelMessageJson(
                id: '$id',
                text: id == 101
                    ? 'A new unseen arrival.'
                    : 'History update $id.',
              ),
          ], total: arrived ? 21 : 20);
        }
        return h.respond(path, method, body, headers);
      };
      final work = WorkspaceController(
        const UnavailableWorkspaceRepository(),
        messagesRepository: h.repository,
      );
      addTearDown(work.dispose);
      await tester.pumpWidget(app(work));
      await tester.pumpAndSettle();
      await tap(tester, 'conversation-$pickupThread');
      final target = find.text('History update 90.');
      final list = find.byKey(const PageStorageKey('messages-$pickupThread'));
      await tester.scrollUntilVisible(
        target,
        180,
        scrollable: find
            .descendant(of: list, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(target).dy;
      final reads = h.api.calls.where((c) => c.method == 'POST').length;
      arrived = true;
      await work.messages.refreshThread();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(target).dy, closeTo(before, 1));
      expect(work.messages.messages.first.isRead, isFalse);
      expect(h.api.calls.where((c) => c.method == 'POST'), hasLength(reads));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'an offstage selected thread cannot acknowledge and read-only chat has no composer',
    (tester) async {
      final h = MessagesHarness();
      addTearDown(h.dispose);
      h.canSend = false;
      final work = WorkspaceController(
        const UnavailableWorkspaceRepository(),
        messagesRepository: h.repository,
      );
      addTearDown(work.dispose);
      await tester.pumpWidget(app(work));
      await tester.pumpAndSettle();
      await tap(tester, 'conversation-$pickupThread');
      expect(find.byKey(const ValueKey('message-draft')), findsNothing);
      expect(
        find.text(
          'This assignment is read only. New messages are unavailable.',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(app(work, active: false));
      await tester.pumpAndSettle();
      final reads = h.api.calls.where((c) => c.method == 'POST').length;
      await work.messages.acknowledgeDisplayed(
        pickupThread,
        '51',
        work.messages.historyRevision,
      );
      expect(h.api.calls.where((c) => c.method == 'POST'), hasLength(reads));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'an uncertain send exposes original recovery and keeps the draft until confirmed',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = MessagesHarness();
      addTearDown(h.dispose);
      final work = WorkspaceController(
        const UnavailableWorkspaceRepository(),
        messagesRepository: h.repository,
      );
      addTearDown(work.dispose);
      await tester.pumpWidget(app(work, scale: 2));
      await tester.pumpAndSettle();
      await tap(tester, 'conversation-$pickupThread');
      h.api.respond = (path, method, body, headers) async {
        if (method == 'POST' && path.endsWith('/messages')) {
          throw const AccountFailure(
            'Message response lost.',
            unconfirmed: true,
          );
        }
        return h.respond(path, method, body, headers);
      };
      await tester.enterText(
        find.byKey(const ValueKey('message-draft')),
        'A parcel update.',
      );
      await tester.pumpAndSettle();
      await tap(tester, 'send-message');
      expect(work.messages.pendingIntent, isNotNull);
      expect(work.messages.draft, 'A parcel update.');
      final attempts = h.api.calls
          .where((call) => call.method == 'POST')
          .length;
      h.api.respond = h.respond;
      await tap(tester, 'message-reconcile');
      expect(work.messages.pendingIntent, isNull);
      expect(work.messages.draft, isEmpty);
      expect(
        h.api.calls.where((call) => call.method == 'POST'),
        hasLength(attempts),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'a disabled deployment gate preserves real browsing without send or read writes',
    (tester) async {
      final h = MessagesHarness(enabled: false);
      addTearDown(h.dispose);
      final work = WorkspaceController(
        const UnavailableWorkspaceRepository(),
        messagesRepository: h.repository,
      );
      addTearDown(work.dispose);
      await tester.pumpWidget(app(work));
      await tester.pumpAndSettle();
      await tap(tester, 'conversation-$pickupThread');
      await tester.enterText(
        find.byKey(const ValueKey('message-draft')),
        'An unsent draft.',
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('send-message')))
            .onPressed,
        isNull,
      );
      expect(h.api.calls.where((call) => call.method == 'POST'), isEmpty);
      expect(work.messages.thread!.participantName, 'Example seller');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
