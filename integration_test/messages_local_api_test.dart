// Opt-in synthetic native client verification. The loopback runner owns all data.
import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_validation.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/messages/data/messages_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const base = String.fromEnvironment('LOCAL_MESSAGES_API_BASE');
  const fixtureToken = String.fromEnvironment('LOCAL_MESSAGES_FIXTURE_TOKEN');
  testWidgets(
    'native Messages match real seller buyer read boundaries and retained commands',
    (tester) async {
      final origin = Uri.parse(base);
      if (origin.scheme != 'http' ||
          origin.host != '127.0.0.1' ||
          origin.path.isNotEmpty ||
          fixtureToken.isEmpty) {
        throw StateError('Use the isolated local Messages runner.');
      }
      Future<Map<String, dynamic>> control(
        String operation, [
        Map<String, dynamic> arguments = const {},
      ]) async {
        final client = HttpClient();
        try {
          final request = await client.postUrl(origin.resolve('/fixture'));
          request.headers.set('X-Local-Fixture', fixtureToken);
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode({'operation': operation, ...arguments}));
          final response = await request.close().timeout(
            const Duration(seconds: 50),
          );
          if (response.statusCode != 200) {
            throw StateError('Local Messages fixture failed.');
          }
          return jsonDecode(
            await response
                .transform(utf8.decoder)
                .join()
                .timeout(const Duration(seconds: 50)),
          ) as Map<String, dynamic>;
        } finally {
          client.close(force: true);
        }
      }

      final info = await control('info');
      expect(info['database'], ':memory:');
      final dio = Dio();
      var next = DateTime.now();
      String? loseBefore, loseAfter;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            final delay = next.difference(DateTime.now());
            if (!delay.isNegative) await Future<void>.delayed(delay);
            next = DateTime.now().add(const Duration(milliseconds: 2300));
            if (loseBefore != null &&
                request.method == 'POST' &&
                request.uri.path.endsWith(loseBefore!)) {
              loseBefore = null;
              handler.reject(
                DioException(
                  requestOptions: request,
                  type: DioExceptionType.connectionTimeout,
                ),
              );
            } else {
              handler.next(request);
            }
          },
          onResponse: (response, handler) {
            if (loseAfter != null &&
                response.requestOptions.method == 'POST' &&
                response.requestOptions.uri.path.endsWith(loseAfter!)) {
              loseAfter = null;
              handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  type: DioExceptionType.receiveTimeout,
                ),
              );
            } else {
              handler.next(response);
            }
          },
        ),
      );
      final config = AppConfig('$base/api/v1', localAuth: true);
      final auth = ApiAuthRepository(config, MemoryTokenStore(), client: dio);
      final other = ApiAuthRepository(config, MemoryTokenStore(), client: dio);
      SecureCommandJournal? workJournal, messageJournal;
      try {
        final account = await auth.login(
          info['email'] as String,
          info['password'] as String,
        );
        expect(account.operationsApiVersion, 1);
        workJournal = SecureCommandJournal(
          origin: config.origin,
          accountId: account.id,
        );
        messageJournal = SecureCommandJournal(
          origin: config.origin,
          accountId: account.id,
          scope: 'messages',
        );
        await workJournal.clear();
        await messageJournal.clear();
        final work = OperationsRepository(
          auth,
          accountId: account.id,
          journal: workJournal,
          writesVerified: true,
          parcelWritesVerified: true,
          isCurrent: () => true,
        );
        OperationsMessagesRepository messages() => OperationsMessagesRepository(
          auth,
          accountId: account.id,
          journal: messageJournal!,
          writesVerified: true,
          isCurrent: () => true,
          readHome: work.home,
          avatarOrigin: config.origin,
        );
        var repo = messages();
        expect(await repo.available(), isTrue);
        await work.duty(true);
        final pickupId = info['parcels']['pickup']['id'] as String;
        final available = await work.taskPage(TaskQueue.available);
        final job = available.items.singleWhere(
          (task) => task.deliveryId == pickupId,
        );
        await work.claim(job);
        final pickup = await work.detail('pickup-$pickupId');
        final first = await control('message_reply', {
          'phase': 'pickup',
          'text': 'Software test: parcel ready at the counter.',
        });
        var threads = await repo.conversations();
        final seller = threads.items.singleWhere((t) => t.taskId == pickup.id);
        expect(seller.phase, 'pickup');
        expect(seller.participantRole, 'seller');
        expect(seller.participantId, first['sender_id']);
        final displayed = await repo.history(seller.id);
        expect(displayed.items.single.id, first['id']);
        final late = await control('message_reply', {
          'phase': 'pickup',
          'text': 'Software test: a later entrance update.',
        });
        await repo.acknowledge(
          seller,
          first['id'] as String,
          mayDispatch: () => true,
        );
        var snapshot = await control('messages_snapshot');
        List<dynamic> rows(String kind) =>
            (snapshot['parcels'][kind]['messages'] as List<dynamic>);
        expect(
          rows('pickup').singleWhere((m) => m['id'] == first['id'])['is_read'],
          isTrue,
        );
        expect(
          rows('pickup').singleWhere((m) => m['id'] == late['id'])['is_read'],
          isFalse,
        );
        loseAfter = '/messages';
        await expectLater(
          repo.send(
            seller,
            'Software test: I am at the pickup.',
            mayDispatch: () => true,
          ),
          throwsA(isA<AccountFailure>()),
        );
        final original = (await repo.pending())!;
        expect(original.action, 'message.send');
        // A new repository reads the real native secure journal, rather than a
        // copied in-memory intent or an invented optimistic message.
        repo = messages();
        expect((await repo.pending())!.key, original.key);
        await expectLater(
          repo.send(
            seller,
            'A replacement is forbidden.',
            mayDispatch: () => true,
          ),
          throwsA(isA<AccountFailure>()),
        );
        final recovered = await repo.reconcile(mayDispatch: () => true);
        expect(recovered!.message!.text, original.body['text']);
        final replay = await auth.authenticatedRequest(
          original.path,
          method: 'POST',
          data: original.body,
          headers: {'Idempotency-Key': original.key},
        );
        expect(replay['data']['replayed'], isTrue);
        expect(replay['data']['result']['id'], recovered.message!.id);
        loseBefore = '/read';
        await expectLater(
          repo.acknowledge(
            seller,
            late['id'] as String,
            mayDispatch: () => true,
          ),
          throwsA(isA<AccountFailure>()),
        );
        final readIntent = (await repo.pending())!;
        expect(readIntent.action, 'message.read');
        expect(await repo.reconcile(mayDispatch: () => true), isNull);
        expect((await repo.pending())!.key, readIntent.key);
        await repo.reconcile(retryUnknown: true, mayDispatch: () => true);
        expect(await repo.pending(), isNull);
        await other.login(
          info['other_email'] as String,
          info['other_password'] as String,
        );
        await expectLater(
          other.authenticatedRequest(
            'rider/conversations/${seller.id}/messages',
          ),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.status,
              'foreign thread',
              404,
            ),
          ),
        );
        await expectLater(
          other.authenticatedRequest(
            'rider/conversations/${seller.id}/read',
            method: 'POST',
            data: {'through_message_id': first['id']},
            headers: {'Idempotency-Key': commandUuid()},
          ),
          throwsA(isA<AccountFailure>()),
        );
        final collected = await work.detail(pickup.id);
        await work.parcel(
          ParcelAction.pickup,
          collected,
          barcode: collected.tracking,
        );
        await control('receive_pickup');
        final closed = await repo.history(seller.id);
        expect(closed.thread.canSend, isFalse);
        await expectLater(
          repo.send(
            seller,
            'Software test: stale seller draft.',
            mayDispatch: () => true,
          ),
          throwsA(isA<AccountFailure>()),
        );
        expect(await repo.pending(), isNull);
        final delivery = await control('prepare_delivery');
        final deliveryId = delivery['parcel']['id'] as String;
        final buyerReply = await control('message_reply', {
          'phase': 'final_mile',
          'text': 'Software test: use the saved entrance.',
        });
        threads = await repo.conversations();
        final buyer = threads.items.singleWhere(
          (t) => t.taskId == 'final_mile-$deliveryId',
        );
        expect(buyer.participantRole, 'buyer');
        expect(buyer.participantId, buyerReply['sender_id']);
        expect(buyer.id, isNot(seller.id));
        final sent = await repo.send(
          buyer,
          'Software test: I am at the delivery stop.',
          mayDispatch: () => true,
        );
        expect(sent.message!.fromRider, isTrue);
        await repo.acknowledge(
          buyer,
          buyerReply['id'] as String,
          mayDispatch: () => true,
        );
        await expectLater(
          repo.acknowledge(
            buyer,
            first['id'] as String,
            mayDispatch: () => true,
          ),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.status,
              'foreign boundary',
              409,
            ),
          ),
        );
        expect(await repo.pending(), isNull);
        snapshot = await control('messages_snapshot');
        final pickupOutgoing = rows('pickup')
            .where((m) => m['sender_id'] == account.id)
            .toList();
        final buyerOutgoing = rows('delivery')
            .where((m) => m['sender_id'] == account.id)
            .toList();
        expect(pickupOutgoing, hasLength(1));
        expect(buyerOutgoing, hasLength(1));
        expect(pickupOutgoing.single['receiver_id'], seller.participantId);
        expect(buyerOutgoing.single['receiver_id'], buyer.participantId);
        expect(snapshot['sends'], 2);
        expect(snapshot['reads'], 3);
        expect(snapshot['outcomes'], 0);
        expect(snapshot['parcels']['delivery']['stage'], 'assigned_to_rider');
      } finally {
        await messageJournal?.clear();
        await workJournal?.clear();
        await auth.discardSession();
        await other.discardSession();
        dio.close(force: true);
      }
    },
    skip: base.isEmpty || fixtureToken.isEmpty,
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
