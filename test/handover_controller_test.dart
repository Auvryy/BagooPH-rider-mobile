import 'dart:async';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/handover/presentation/handover_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/handover_support.dart';

void main() {
  test('refresh failure retains checked rows but blocks writes until successful fresh data', () async {
    final api = HandoverSession(), journal = MemoryHandoverJournal();
    final c = HandoverController(testHandoverRepository(api, journal));
    addTearDown(c.dispose);
    await c.refresh();
    expect(c.items.length, 1);
    expect(c.canWrite, true);
    api.handler = (path, method, data, headers) async =>
        throw const AccountFailure('Synthetic read failure', status: 500);
    await c.refresh();
    expect(c.items.length, 1);
    expect(c.canWrite, false);
    expect(c.failure, isNotNull);
    api.handler = null;
    await c.refresh();
    expect(c.failure, isNull);
    expect(c.canWrite, true);
  });
  test('offset pagination deduplicates shifted IDs and preserves later server detail', () async {
    final api = HandoverSession(), journal = MemoryHandoverJournal();
    final c = HandoverController(testHandoverRepository(api, journal));
    addTearDown(c.dispose);
    api.listBody['data']['pagination']['last_page'] = 2;
    api.listBody['data']['pagination']['total'] = 2;
    await c.refresh();
    api.handler = (path, method, data, headers) async {
      if (path.contains('page=2')) {
        final page = handoverFixture('issues');
        page['data']['pagination'] = {
          'page': 2,
          'per_page': 20,
          'total': 2,
          'last_page': 2,
        };
        final other = Map<String, dynamic>.from(page['data']['items'][0]);
        other['id'] = '2';
        page['data']['items'].add(other);
        return page;
      }
      return api.reply(path);
    };
    await c.more();
    expect(c.items.map((x) => x.id), ['1', '2']);
    expect(c.page!.hasNext, false);
    expect(api.calls.last.path, contains('status=open&page=2&per_page=20'));
  });
  test(
    'new selection, Back and background discard late private detail',
    () async {
      for (final action in ['selection', 'back', 'background']) {
        final api = HandoverSession(), journal = MemoryHandoverJournal();
        final c = HandoverController(testHandoverRepository(api, journal));
        await c.refresh();
        final late = Completer<Map<String, dynamic>>();
        api.handler = (path, method, data, headers) async {
          if (path == 'rider/handover-issues/1') return late.future;
          if (path == 'rider/handover-issues/2') {
            final second = handoverFixture('detail');
            second['data']['id'] = '2';
            second['data']['evidence']['download_path'] =
                '/api/v1/rider/handover-issues/2/evidence';
            return second;
          }
          return api.reply(path);
        };
        final old = c.open('1');
        await Future<void>.delayed(Duration.zero);
        if (action == 'selection') await c.open('2');
        if (action == 'back') c.closeDetail();
        if (action == 'background') c.setForeground(false);
        late.complete(api.detailBody);
        await old;
        expect(c.selected?.id, action == 'selection' ? '2' : null);
        if (action == 'back') {
          await Future<void>.delayed(Duration.zero);
          expect(c.loading, false);
        }
        c.dispose();
      }
    },
  );
  test('field feedback survives post-command refresh and safe entered values remain retryable', () async {
    final api = HandoverSession(), journal = MemoryHandoverJournal();
    final c = HandoverController(testHandoverRepository(api, journal));
    addTearDown(c.dispose);
    await c.refresh();
    api.handler = (path, method, data, headers) async {
      if (method == 'POST') {
        throw const AccountFailure(
          'Please clarify',
          status: 422,
          fields: {'reported_location': 'Use the actual observed location.'},
        );
      }
      return api.reply(path);
    };
    expect(
      await c.report(
        barcode: 'BGO-TEST',
        holder: 'Known rider',
        location: 'Assigned hub',
        notes: 'Actual observed missed scan',
        file: evidenceFile,
      ),
      false,
    );
    expect(
      c.failure!.fields['reported_location'],
      'Use the actual observed location.',
    );
    expect(c.pendingIntent, isNull);
    expect(c.canWrite, true);
  });
  test('unknown request remains blocked and one explicit reconciliation does one command GET', () async {
    final api = HandoverSession(), journal = MemoryHandoverJournal();
    final c = HandoverController(testHandoverRepository(api, journal));
    addTearDown(c.dispose);
    await c.refresh();
    api.handler = (path, method, data, headers) async {
      if (method == 'POST') {
        throw const AccountFailure('Synthetic timeout', unconfirmed: true);
      }
      if (path.startsWith('rider/commands/')) {
        throw const AccountFailure(
          'Unknown',
          status: 404,
          code: 'COMMAND_UNKNOWN',
        );
      }
      return api.reply(path);
    };
    await c.report(
      barcode: 'BGO-TEST',
      holder: 'Known rider',
      location: 'Assigned hub',
      notes: 'Actual observed missed scan',
      file: evidenceFile,
    );
    expect(c.pendingIntent, isNotNull);
    expect(c.canWrite, false);
    final before = api.calls
        .where((x) => x.path.startsWith('rider/commands/'))
        .length;
    await c.reconcile();
    expect(
      api.calls.where((x) => x.path.startsWith('rider/commands/')).length,
      before + 1,
    );
    expect(c.pendingIntent, isNotNull);
  });
  test('acknowledgement retains hold; fresh actual hub receipt later shows recovered without client transition', () async {
    final api = HandoverSession(), journal = MemoryHandoverJournal();
    final c = HandoverController(testHandoverRepository(api, journal));
    addTearDown(c.dispose);
    await c.refresh();
    await c.open('1');
    api.handler = (path, method, data, headers) async {
      if (method == 'POST') {
        final result = handoverCommand((await journal.read())!);
        api.detailBody['data']['recovery']['acknowledged'] = true;
        api.detailBody['data']['recovery']['actions']['acknowledge'] = false;
        return result;
      }
      return api.reply(path);
    };
    expect(
      await c.acknowledge(
        barcode: c.selected!.tracking,
        notes: 'I physically hold this actual parcel.',
        possessionVerified: true,
      ),
      true,
    );
    expect(c.selected!.held, true);
    expect(c.selected!.recovery!.acknowledged, true);
    api.detailBody['data']['state'] = 'recovered';
    api.detailBody['data']['held'] = false;
    api.detailBody['data']['recovery']['closed'] = true;
    await c.refresh();
    expect(c.selected!.state, 'recovered');
    expect(c.selected!.held, false);
    expect(api.calls.where((x) => x.method == 'POST').length, 1);
  });
  for (final status in [401, 403, 404, 429, 503]) {
    test(
      'status $status preserves the required access/cooldown behavior',
      () async {
        final api = HandoverSession(), journal = MemoryHandoverJournal();
        final notices = <String>[];
        final c = HandoverController(
          testHandoverRepository(api, journal),
          onSessionEnd: (n) async {
            notices.add(n);
          },
        );
        addTearDown(c.dispose);
        await c.refresh();
        api.handler = (path, method, data, headers) async {
          throw AccountFailure(
            'Synthetic denied read',
            status: status,
            retryAfterSeconds: status == 429 ? 30 : null,
          );
        };
        await c.open('1');
        expect(c.selected, isNull);
        expect(c.failure!.status, status);
        if ([401, 403].contains(status)) {
          expect(c.items, isEmpty);
          expect(notices.length, 1);
          expect(c.active, false);
        }
        if (status == 404) expect(c.items, isEmpty);
        if (status == 429) {
          expect(c.coolingDown, true);
          final calls = api.calls.length;
          await c.refresh();
          expect(api.calls.length, calls);
        }
      },
    );
  }
  test('no reads poll in background or covered views; resume revalidates the selected issue', () async {
    final api = HandoverSession(), journal = MemoryHandoverJournal();
    final c = HandoverController(testHandoverRepository(api, journal));
    addTearDown(c.dispose);
    await c.refresh();
    await c.open('1');
    final before = api.calls.length;
    c.setVisible(false);
    await c.refresh();
    c.setForeground(false);
    await c.refresh();
    expect(api.calls.length, before);
    api.detailBody['data']['version'] = 5;
    api.detailBody['data']['recovery']['expected_version'] = 5;
    c.setVisible(true);
    expect(api.calls.length, before);
    c.setForeground(true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.selected!.version, 5);
    expect(api.calls.where((x) => x.method == 'POST'), isEmpty);
  });
}
