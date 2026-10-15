import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/platform/stop_actions.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/stop_mode_page.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/tasks_page.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_workspace_binding.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'navigation_test.dart' as routes;
import 'operations_contract_test.dart' as contract;
import 'support/test_auth_repository.dart';

class _Actions implements StopActions {
  final copies = <String>[];
  final opened = <Uri>[];
  bool result = true, fail = false;
  @override
  Future<void> copy(String text) async {
    if (fail) throw StateError('Synthetic clipboard failure');
    copies.add(text);
  }

  @override
  Future<bool> open(Uri uri) async {
    if (fail) throw StateError('Synthetic launcher failure');
    opened.add(uri);
    return result;
  }
}

class _Harness {
  _Harness({bool preview = false, bool pickup = false}) {
    data = contract.fixture(
      preview || pickup ? 'pickup-task' : 'final-mile-task',
    )['data'];
    if (preview) {
      data['preview'] = true;
      data['operational_stage'] = 'unassigned';
      data['assignment_reference'] = null;
      data['actions']['pickup'] = false;
      data['actions']['claim'] = true;
    }
    home['data']['counts'] = {
      'available': preview ? 1 : 0,
      'pickup': pickup ? 1 : 0,
      'final_mile': preview || pickup ? 0 : 1,
    };
    home['data']['limits']['poll_interval_seconds'] = 3600;
    api.respond = (path, method, body, headers) async {
      if (path == 'rider/home') return _clone(home);
      if (path.startsWith('rider/tasks/')) {
        details++;
        final gate = detailGate;
        detailGate = null;
        if (gate != null) return gate.future;
        if (detailFailure != null) throw detailFailure!;
        return {'data': _clone(data)};
      }
      return {
        'data': {
          'items': [_clone(data)],
          'pagination': {'page': 1, 'per_page': 20, 'total': 1, 'last_page': 1},
        },
      };
    };
    final repository = OperationsRepository(
      api,
      accountId: '5',
      journal: contract.Journal(),
      writesVerified: false,
      isCurrent: () => authorized,
    );
    work = WorkspaceController(
      repository,
      onSessionEnd: (message) async => sessionEnds++,
    );
    nav = NavigationController(
      routes: road,
      authorize: repository.detail,
      vehicleType: () async => 'motorcycle',
      manual: true,
    );
    binding = NavigationWorkspaceBinding(work, nav);
  }
  final api = contract.Session();
  final actions = _Actions();
  final road = routes.Routes();
  final home = contract.fixture('home');
  late Map<String, dynamic> data;
  late final WorkspaceController work;
  late final NavigationController nav;
  late final NavigationWorkspaceBinding binding;
  int details = 0, sessionEnds = 0;
  bool authorized = true;
  AccountFailure? detailFailure;
  Completer<Map<String, dynamic>>? detailGate;
  OperationTask get task => OperationTask.fromJson(_clone(data));
  void hubStop({
    String kind = 'destination_hub',
    String stage = 'delivery_failed',
  }) {
    data['operational_stage'] = stage;
    data['version'] = 'a' * 64;
    data['stop'] = {
      'kind': kind,
      'name': 'Current authorized hub',
      'address': '42 Current hub road',
      'latitude': null,
      'longitude': null,
      'phone': null,
      'instructions': null,
    };
    data['next_instruction'] =
        'Bring the parcel to the current hub. Its handler confirms receipt.';
  }

  void dispose() {
    binding.dispose();
    nav.dispose();
    road.dispose();
    work.dispose();
  }
}

Map<String, dynamic> _clone(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

class _Owner extends StatefulWidget {
  const _Owner({required this.harness, required this.child});
  final _Harness harness;
  final Widget child;
  @override
  State<_Owner> createState() => _OwnerState();
}

class _OwnerState extends State<_Owner> {
  @override
  void dispose() {
    widget.harness.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<_Harness> _open(
  WidgetTester tester, {
  bool preview = false,
  bool pickup = false,
  Size size = const Size(390, 844),
  double scale = 1,
  double keyboard = 0,
  bool throughTasks = false,
  void Function(_Harness)? configure,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final h = _Harness(preview: preview, pickup: pickup);
  configure?.call(h);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
  final initial = OperationsRepository.asRiderTask(h.task);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(TestAuthRepository()),
      ],
      child: _Owner(
        harness: h,
        child: MaterialApp(
          theme: buildRiderTheme().copyWith(
            appBarTheme: buildRiderTheme().appBarTheme.copyWith(
              titleTextStyle: buildRiderTheme().appBarTheme.titleTextStyle
                  ?.copyWith(fontFamily: 'Plus Jakarta Sans'),
            ),
            textTheme: buildRiderTheme().textTheme.apply(
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  key: const ValueKey('open-stop'),
                  onPressed: () {
                    if (throughTasks) {
                      TasksPage(
                        account: const RiderAccount(
                          id: '5',
                          name: 'Example Rider',
                          email: 'rider@example.test',
                          status: 'active',
                          kycStatus: 'approved',
                          approved: true,
                          emailVerified: true,
                        ),
                        controller: h.work,
                        preview: false,
                        navigation: h.nav,
                      ).openParcel(context, initial);
                    } else {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => StopModePage(
                            initialTask: initial,
                            controller: h.work,
                            navigation: h.nav,
                            actions: h.actions,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Open stop'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('open-stop')));
  await tester.pumpAndSettle();
  return h;
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scroll = find
        .descendant(
          of: find.byKey(const ValueKey('stop-mode-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(scroll).position.jumpTo(0);
    await tester.pumpAndSettle();
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 160, scrollable: scroll);
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key, {bool settle = true}) async {
  final finder = find.byKey(ValueKey(key));
  await _reveal(tester, finder);
  await tester.tap(finder);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

bool _enabled(WidgetTester tester, String key) =>
    tester.widget<ButtonStyleButton>(find.byKey(ValueKey(key))).onPressed !=
    null;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final text = FontLoader('Plus Jakarta Sans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([text.load(), icons.load()]);
  });
  setUp(() {
    final before = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = before);
  });

  test('phone URI accepts formatting and rejects schemes, dial codes and invalid input', () {
    expect(
      stopPhoneUri(' +63 (917) 000-0000 ')?.toString(),
      'tel:+639170000000',
    );
    expect(stopPhoneUri('09170000000')?.toString(), 'tel:09170000000');
    for (final value in [
      null,
      '',
      ' ',
      'tel:09170000000',
      'https://example.test',
      '*123#',
      '09170000000?x=1',
      '0917\n0000000',
      '1',
      '1' * 16,
    ]) {
      expect(stopPhoneUri(value), isNull, reason: '$value');
    }
  });

  testWidgets(
    'owned stop shows exact identifiers, recorded custody and plain buyer guidance',
    (tester) async {
      final h = await _open(tester);
      expect(find.text('Work this stop'), findsOneWidget);
      expect(
        tester
            .widget<SelectableText>(find.byKey(const ValueKey('stop-tracking')))
            .data,
        h.task.tracking,
      );
      await _reveal(tester, find.byKey(const ValueKey('stop-notes')));
      expect(find.text('Doorstep Guide'), findsOneWidget);
      expect(
        tester
            .widget<SelectableText>(find.byKey(const ValueKey('stop-notes')))
            .data,
        h.task.stop.instructions,
      );
      expect(h.work.canWrite, isFalse);
      expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
    },
  );

  testWidgets(
    'available pickup remains a public preview without private stop actions',
    (tester) async {
      final h = await _open(tester, preview: true);
      expect(find.text('Pickup preview'), findsOneWidget);
      await _reveal(tester, find.byKey(const ValueKey('stop-claim')));
      expect(_enabled(tester, 'stop-claim'), isFalse);
      for (final key in [
        'stop-copy-address',
        'stop-call',
        'stop-navigate',
        'stop-external-directions',
        'stop-phone',
        'stop-notes',
      ]) {
        expect(find.byKey(ValueKey(key)), findsNothing);
      }
      expect(h.details, 0);
      expect(h.actions.opened, isEmpty);
      expect(h.road.calls, isEmpty);
    },
  );

  testWidgets(
    'copy actions reauthorize and preserve full exact values without work writes',
    (tester) async {
      final h = await _open(tester);
      for (final key in [
        'stop-copy-tracking',
        'stop-copy-order',
        'stop-copy-address',
      ]) {
        final before = h.details;
        await _tap(tester, key);
        expect(h.details, before + 1);
      }
      expect(h.actions.copies, [
        h.task.tracking,
        h.task.order,
        h.task.stop.address,
      ]);
      expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
      expect(h.road.calls, isEmpty);
    },
  );

  testWidgets(
    'a changed stop cancels the old call and removes old buyer notes and phone',
    (tester) async {
      final h = await _open(tester);
      h.hubStop();
      await _tap(tester, 'stop-call');
      expect(h.actions.opened, isEmpty);
      expect(h.work.selectedTask!.stop.kind, 'destination_hub');
      expect(find.byKey(const ValueKey('stop-phone')), findsNothing);
      expect(find.byKey(const ValueKey('stop-notes')), findsNothing);
      await _reveal(tester, find.byKey(const ValueKey('stop-notice')));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('stop-notice'))).data,
        contains('stop changed'),
      );
      await _tap(tester, 'stop-copy-address');
      expect(h.actions.copies, ['42 Current hub road']);
    },
  );

  testWidgets(
    'refreshed collection detail switches seller stop to the recorded origin hub',
    (tester) async {
      final h = await _open(tester, pickup: true);
      expect(h.work.selectedTask!.custodyKind, 'seller');
      expect(h.work.selectedTask!.heldByMe, isFalse);
      h.hubStop(kind: 'origin_hub', stage: 'picked_up');
      h.data['custody'] = {
        'kind': 'courier',
        'hub_id': null,
        'held_by_me': true,
      };
      await _tap(tester, 'stop-refresh');
      expect(h.work.selectedTask!.stop.kind, 'origin_hub');
      await _reveal(tester, find.byKey(const ValueKey('stop-custody')));
      expect(find.text('Recorded custody: you'), findsOneWidget);
      expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
    },
  );

  testWidgets(
    'refreshed departure detail switches destination hub to supplied buyer guidance',
    (tester) async {
      final h = await _open(tester);
      h.hubStop(kind: 'destination_hub', stage: 'assigned_to_rider');
      await _tap(tester, 'stop-refresh');
      expect(h.work.selectedTask!.stop.kind, 'destination_hub');
      h.data['operational_stage'] = 'out_for_delivery';
      h.data['stop'] = {
        'kind': 'buyer',
        'name': 'Authorized recipient',
        'address': '18 Frozen buyer road',
        'latitude': 14.6,
        'longitude': 121.0,
        'phone': '09170000000',
        'instructions': 'Use the stored side entrance.',
      };
      h.data['next_instruction'] =
          'Record recipient handoff. The buyer confirms receipt separately.';
      await _tap(tester, 'stop-refresh');
      expect(h.work.selectedTask!.stop.kind, 'buyer');
      await _reveal(tester, find.byKey(const ValueKey('stop-notes')));
      expect(find.text('Doorstep Guide'), findsOneWidget);
      expect(
        tester
            .widget<SelectableText>(find.byKey(const ValueKey('stop-notes')))
            .data,
        'Use the stored side entrance.',
      );
      expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
    },
  );

  testWidgets(
    'live Tasks entry opens a full Stop Mode page and Back returns normally',
    (tester) async {
      await _open(tester, throughTasks: true);
      expect(find.byKey(const ValueKey('stop-mode-page')), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      await _tap(tester, 'stop-back');
      expect(find.byKey(const ValueKey('open-stop')), findsOneWidget);
    },
  );

  testWidgets(
    'failed detail refresh keeps the last display but disables actions until recovery',
    (tester) async {
      final h = await _open(tester);
      h.detailFailure = const AccountFailure(
        'Synthetic network unavailable',
        status: 503,
      );
      await _tap(tester, 'stop-call');
      expect(h.actions.opened, isEmpty);
      expect(_enabled(tester, 'stop-call'), isFalse);
      h.detailFailure = null;
      await _tap(tester, 'stop-refresh');
      await _tap(tester, 'stop-call');
      expect(h.actions.opened.single.toString(), 'tel:09170000000');
    },
  );

  for (final status in [403, 404]) {
    testWidgets(
      'explicit $status denial removes private detail and cannot launch an old contact',
      (tester) async {
        final h = await _open(tester);
        h.detailFailure = AccountFailure(
          'Synthetic access denial',
          status: status,
        );
        await _tap(tester, 'stop-call');
        expect(h.work.selectedTask, isNull);
        expect(h.actions.opened, isEmpty);
        expect(find.byKey(const ValueKey('stop-phone')), findsNothing);
        expect(find.byKey(const ValueKey('stop-notes')), findsNothing);
        expect(h.sessionEnds, status == 403 ? 1 : 0);
      },
    );
  }

  testWidgets(
    'account changes during an outstanding authorization cannot launch a contact',
    (tester) async {
      final h = await _open(tester);
      final gate = Completer<Map<String, dynamic>>();
      h.detailGate = gate;
      await _tap(tester, 'stop-call', settle: false);
      h.authorized = false;
      gate.complete({'data': _clone(h.data)});
      await tester.pumpAndSettle();
      expect(h.work.selectedTask, isNull);
      expect(h.actions.opened, isEmpty);
      expect(h.sessionEnds, 1);
    },
  );

  testWidgets(
    'Back cancels an outstanding contact launch and returns to its opening control',
    (tester) async {
      final h = await _open(tester);
      final gate = Completer<Map<String, dynamic>>();
      h.detailGate = gate;
      await _tap(tester, 'stop-call', settle: false);
      await _tap(tester, 'stop-back');
      gate.complete({'data': _clone(h.data)});
      await tester.pumpAndSettle();
      expect(h.actions.opened, isEmpty);
      expect(find.byKey(const ValueKey('open-stop')), findsOneWidget);
    },
  );

  testWidgets(
    'failed launcher and clipboard preserve text and explain recovery',
    (tester) async {
      final h = await _open(tester);
      h.actions.result = false;
      await _tap(tester, 'stop-call');
      await _reveal(tester, find.byKey(const ValueKey('stop-notice')));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('stop-notice'))).data,
        contains('Could not open the phone app'),
      );
      h.actions.fail = true;
      await _tap(tester, 'stop-copy-address');
      await _reveal(tester, find.byKey(const ValueKey('stop-notice')));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('stop-notice'))).data,
        'Could not copy the address.',
      );
      expect(h.work.selectedTask!.stop.address, h.task.stop.address);
    },
  );

  testWidgets(
    'external directions use the refreshed address and do not start GPS or route requests',
    (tester) async {
      final h = await _open(tester);
      final before = h.details;
      await _tap(tester, 'stop-external-directions');
      expect(h.details, before + 1);
      expect(h.actions.opened.single.host, 'www.google.com');
      expect(
        h.actions.opened.single.queryParameters['destination'],
        h.task.stop.address,
      );
      expect(h.nav.active, isFalse);
      expect(h.road.calls, isEmpty);
    },
  );

  testWidgets('app resume revalidates before the old stop is actionable', (
    tester,
  ) async {
    final h = await _open(tester);
    final before = h.details;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    h.hubStop();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(h.details, before + 1);
    expect(h.work.selectedTask!.stop.kind, 'destination_hub');
    await _reveal(tester, find.byKey(const ValueKey('stop-call')));
    expect(_enabled(tester, 'stop-call'), isFalse);
    expect(find.byKey(const ValueKey('stop-notes')), findsNothing);
  });

  testWidgets(
    'returning from a covered route refreshes stop detail without a work command',
    (tester) async {
      final h = await _open(tester);
      final before = h.details;
      final context = tester.element(find.byType(StopModePage));
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Synthetic capture route')),
        ),
      );
      await tester.pumpAndSettle();
      h.hubStop();
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      expect(h.details, before + 1);
      expect(h.work.selectedTask!.stop.kind, 'destination_hub');
      expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
    },
  );

  testWidgets('Escape returns to tasks without changing parcel state', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(StopModePage), findsNothing);
    expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
  });

  testWidgets(
    'missing stop fields and invalid coordinates keep honest fallbacks',
    (tester) async {
      final h = await _open(
        tester,
        configure: (h) {
          h.data['stop'] = {
            'kind': 'buyer',
            'name': ' ',
            'address': null,
            'phone': 'tel:09170000000',
            'instructions': null,
            'latitude': 91,
            'longitude': 121,
          };
        },
      );
      await _reveal(tester, find.byKey(const ValueKey('stop-address')));
      expect(find.text('Address unavailable'), findsOneWidget);
      expect(find.text('Stop name unavailable'), findsOneWidget);
      expect(find.text('Address only · no saved map pin'), findsOneWidget);
      await _reveal(tester, find.byKey(const ValueKey('stop-call')));
      expect(_enabled(tester, 'stop-copy-address'), isFalse);
      expect(_enabled(tester, 'stop-call'), isFalse);
      expect(
        find.byKey(const ValueKey('stop-external-directions')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('stop-navigate')), findsNothing);
      expect(h.actions.opened, isEmpty);
      expect(h.nav.active, isFalse);
    },
  );

  testWidgets(
    'rate-limited authorization disables actions and respects the cooldown',
    (tester) async {
      final h = await _open(tester);
      h.detailFailure = const AccountFailure(
        'Work request limit reached',
        status: 429,
        retryAfterSeconds: 2,
      );
      await _tap(tester, 'stop-call');
      expect(h.work.coolingDown, isTrue);
      expect(h.actions.opened, isEmpty);
      final reads = h.details;
      await _tap(tester, 'stop-copy-address');
      expect(h.details, reads);
      expect(h.actions.copies, isEmpty);
      h.detailFailure = null;
      await tester.pump(const Duration(seconds: 3));
      await _tap(tester, 'stop-refresh');
      await _tap(tester, 'stop-copy-address');
      expect(h.actions.copies.single, h.task.stop.address);
    },
  );

  testWidgets(
    'late authorization cannot overwrite a different selected parcel or launch its contact',
    (tester) async {
      final h = await _open(tester);
      final old = _clone(h.data), gate = Completer<Map<String, dynamic>>();
      h.detailGate = gate;
      await _tap(tester, 'stop-call', settle: false);
      h.data['id'] = 'final_mile-2';
      h.data['delivery_id'] = '2';
      h.data['tracking_number'] = 'BGO-ANOTHER-OWNED-PARCEL';
      h.data['stop']['phone'] = '09170000002';
      await h.work.openTask(OperationsRepository.asRiderTask(h.task));
      gate.complete({'data': old});
      await tester.pumpAndSettle();
      expect(h.work.selectedTask!.id, 'final_mile-2');
      expect(h.actions.opened, isEmpty);
      expect(find.text('BGO-ANOTHER-OWNED-PARCEL'), findsNothing);
      expect(find.byKey(const ValueKey('stop-phone')), findsNothing);
    },
  );

  testWidgets(
    'backgrounding during an authorization cancels the call; resume performs a new read',
    (tester) async {
      final h = await _open(tester);
      final old = _clone(h.data), gate = Completer<Map<String, dynamic>>();
      h.detailGate = gate;
      await _tap(tester, 'stop-call', settle: false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      h.hubStop();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      gate.complete({'data': old});
      await tester.pumpAndSettle();
      expect(h.actions.opened, isEmpty);
      expect(h.work.selectedTask!.stop.kind, 'destination_hub');
      await _reveal(tester, find.byKey(const ValueKey('stop-call')));
      expect(_enabled(tester, 'stop-call'), isFalse);
    },
  );

  testWidgets(
    'manual Navigate starts only on tap, Stop ends it, and a changed destination cancels its route',
    (tester) async {
      final h = await _open(
        tester,
        configure: (h) {
          h.data['stop']['latitude'] = 14.003;
          h.data['stop']['longitude'] = 121.0;
        },
      );
      expect(h.nav.active, isFalse);
      expect(h.road.calls, isEmpty);
      await _reveal(tester, find.widgetWithText(TextField, 'Origin latitude'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Origin latitude'),
        '14',
      );
      await _reveal(tester, find.widgetWithText(TextField, 'Origin longitude'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Origin longitude'),
        '121',
      );
      await _tap(tester, 'stop-navigate');
      expect(h.nav.active, isTrue);
      expect(h.nav.road, isNotNull);
      await _tap(tester, 'stop-navigation-stop');
      expect(h.nav.active, isFalse);
      await _tap(tester, 'stop-navigate');
      expect(h.nav.active, isTrue);
      h.hubStop();
      await _tap(tester, 'stop-refresh');
      expect(h.nav.active, isFalse);
      expect(h.nav.road, isNull);
      expect(h.nav.target, isNull);
      expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
    },
  );

  testWidgets(
    'directions never launch a changed coordinate and remain recoverable after launcher exceptions',
    (tester) async {
      final h = await _open(
        tester,
        configure: (h) {
          h.data['stop']['latitude'] = 14.6;
          h.data['stop']['longitude'] = 121.0;
        },
      );
      h.data['stop']['latitude'] = 14.7;
      await _tap(tester, 'stop-external-directions');
      expect(h.actions.opened, isEmpty);
      await _tap(tester, 'stop-external-directions');
      expect(
        h.actions.opened.single.queryParameters['destination'],
        '14.7,121.0',
      );
      h.actions.fail = true;
      await _tap(tester, 'stop-external-directions');
      expect(
        find.text('Could not open external directions. Use the stop address.'),
        findsOneWidget,
      );
      expect(h.work.selectedTask!.stop.address, h.task.stop.address);
    },
  );

  testWidgets(
    'a returned handover hold stops active navigation and blocks movement controls',
    (tester) async {
      final h = await _open(
        tester,
        configure: (h) {
          h.data['stop']['latitude'] = 14.6;
          h.data['stop']['longitude'] = 121.0;
        },
      );
      await h.nav.start(h.task, manualOrigin: const LatLng(14, 121));
      await tester.pumpAndSettle();
      expect(h.nav.active, isTrue);
      h.data['handover_hold'] = true;
      h.data['action_denials']['handover'] = 'HANDOVER_HOLD';
      h.data['next_instruction'] =
          'Company review is required before movement.';
      await _tap(tester, 'stop-refresh');
      expect(h.nav.active, isFalse);
      expect(h.nav.road, isNull);
      await _reveal(tester, find.byKey(const ValueKey('stop-navigate')));
      expect(_enabled(tester, 'stop-navigate'), isFalse);
      expect(_enabled(tester, 'stop-external-directions'), isFalse);
      expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
    },
  );

  testWidgets(
    'fresh navigation authorization rejects a hold added after selection',
    (tester) async {
      final h = await _open(
        tester,
        configure: (h) {
          h.data['stop']['latitude'] = 14.6;
          h.data['stop']['longitude'] = 121.0;
        },
      );
      final selection = h.task;
      h.data['action_denials']['handover'] = 'HANDOVER_HOLD';
      await h.nav.start(selection, manualOrigin: const LatLng(14, 121));
      await tester.pumpAndSettle();
      expect(h.nav.active, isFalse);
      expect(h.road.calls, isEmpty);
      expect(h.nav.message, contains('handover hold'));
    },
  );

  for (final width in [320.0, 390.0, 840.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Stop Mode scroll and controls fit width $width at text $scale',
        (tester) async {
          final h = await _open(
            tester,
            size: Size(width, 844),
            scale: scale,
            keyboard: width == 320 ? 280 : 0,
          );
          h.data['tracking_number'] =
              'BGO-LONG-EXACT-TRACKING-REFERENCE-9223372036854775807';
          h.data['order_number'] =
              'BGO-LONG-EXACT-ORDER-REFERENCE-9223372036854775807';
          h.data['stop']['address'] = '123 Long authorized destination, unit twenty three, saved barangay and municipality, Philippines';
          h.data['stop']['instructions'] = '<b>Stored notes remain plain text.</b> Use the side entrance and call the current recipient when stopped.';
          await _tap(tester, 'stop-refresh');
          await _reveal(
            tester,
            find.byKey(const ValueKey('stop-copy-address')),
          );
          for (final key in [
            'stop-copy-tracking',
            'stop-copy-order',
            'stop-copy-address',
            'stop-call',
            'stop-external-directions',
          ]) {
            await _reveal(tester, find.byKey(ValueKey(key)));
            final rect = tester.getRect(find.byKey(ValueKey(key)));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.width, greaterThanOrEqualTo(48));
          }
          expect(tester.takeException(), isNull);
          expect(find.byType(DraggableScrollableSheet), findsNothing);
          expect(find.byType(ListView), findsOneWidget);
          final pageScroll = find
              .descendant(
                of: find.byKey(const ValueKey('stop-mode-scroll')),
                matching: find.byType(Scrollable),
              )
              .first;
          expect(
            tester.state<ScrollableState>(pageScroll).position.maxScrollExtent,
            greaterThan(0),
          );
          if (width == 390 && scale == 1) {
            final boundary = tester.firstRenderObject<RenderObject>(
              find.byType(RepaintBoundary),
            );
            if (boundary is RenderRepaintBoundary) {
              await tester.runAsync(() async {
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                if (bytes != null) {
                  Directory('build/stop-mode-verification')
                      .createSync(recursive: true);
                  File('build/stop-mode-verification/stop-mode-phone.png')
                      .writeAsBytesSync(bytes.buffer.asUint8List());
                }
                image.dispose();
              });
            }
          }
        },
      );
    }
  }
}
