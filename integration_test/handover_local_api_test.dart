import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/handover/data/handover_intent.dart';
import 'package:bagoo_rider_mobile/features/handover/data/handover_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'handover_native_test.dart' show twoPagePdf;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const base = String.fromEnvironment('LOCAL_HANDOVER_API_BASE');
  const fixtureToken = String.fromEnvironment('LOCAL_HANDOVER_FIXTURE_TOKEN');
  testWidgets(
    'native client exchanges real handover requests with the isolated Laravel kernel',
    (tester) async {
      final origin = Uri.parse(base);
      if (origin.scheme != 'http' ||
          origin.host != '127.0.0.1' ||
          origin.path.isNotEmpty ||
          fixtureToken.isEmpty) {
        throw StateError('Use the isolated local handover runner.');
      }
      Future<Map<String, dynamic>> control(
        String operation, {
        String? issue,
      }) async {
        final client = HttpClient();
        try {
          final request = await client.postUrl(origin.resolve('/fixture'));
          request.headers.set('X-Local-Fixture', fixtureToken);
          request.headers.contentType = ContentType.json;
          request.write(
            jsonEncode({'operation': operation, 'issue_id': ?issue}),
          );
          final response = await request.close();
          if (response.statusCode != 200) {
            throw StateError('Local fixture operation failed.');
          }
          return jsonDecode(await response.transform(utf8.decoder).join())
              as Map<String, dynamic>;
        } finally {
          client.close(force: true);
        }
      }

      final info = await control('info');
      expect(info['database'], ':memory:');
      final barcodes = List<String>.from(info['barcodes']);
      final dio = Dio();
      var loseCommittedReport = true, loseBeforeCommit = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            if (loseBeforeCommit &&
                request.method == 'POST' &&
                request.uri.path.endsWith('/handover-issues')) {
              loseBeforeCommit = false;
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
            if (loseCommittedReport &&
                response.requestOptions.method == 'POST' &&
                response.requestOptions.uri.path.endsWith('/handover-issues')) {
              loseCommittedReport = false;
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
      final auth = ApiAuthRepository(
        AppConfig('$base/api/v1', localAuth: true),
        MemoryTokenStore(),
        client: dio,
      );
      SecureHandoverJournal? journal;
      try {
        final account = await auth.login(
          info['email'] as String,
          info['password'] as String,
        );
        expect(account.handoverApiVersion, 1);
        journal = SecureHandoverJournal(
          origin: Uri.parse('$base/api/v1'),
          accountId: account.id,
        );
        expect(await journal.read(), isNull);
        HandoverRepository repository() => HandoverRepository(
          auth,
          accountId: account.id,
          journal: journal!,
          isCurrent: () => true,
          writesVerified: true,
          sessionVersion: account.handoverApiVersion,
        );
        var repo = repository();
        final before = await control('counts');
        final png = HandoverFile(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jfS8AAAAASUVORK5CYII=',
          ),
          'png',
        );
        Future<Map<String, dynamic>> report(
          String barcode,
          HandoverFile file,
        ) => repo.report(
          barcode: barcode,
          holder: 'Synthetic local rider',
          location: 'Synthetic assigned hub desk',
          notes: 'Isolated local client-to-kernel handover verification.',
          file: file,
        );

        // The server commits, but the client loses its response. Re-create the
        // repository from native protected storage and reconcile the original key.
        await expectLater(
          report(barcodes[0], png),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.unconfirmed,
              'uncertain',
              true,
            ),
          ),
        );
        final saved = (await journal.read())!;
        repo = repository();
        final result = (await repo.reconcile())!;
        expect(await journal.read(), isNull);
        final id = result['issue_id'] as String;
        final rows = await repo.list();
        expect(rows.items.single.id, id);
        var detail = await repo.detail(id);
        expect(detail.state, 'pending_review');
        expect(detail.held, false);
        expect((await repo.evidence(detail)).bytes, png.bytes);
        final observed = await control('counts');
        expect(observed['reports'], 1);
        expect(observed['commands'], 1);
        expect(observed['parcels'], before['parcels']);
        expect(observed['orders_hash'], before['orders_hash']);
        expect(observed['products_hash'], before['products_hash']);
        expect(observed['cod_accounts'], before['cod_accounts']);
        expect(observed['evidence_hashes'], [saved.file!.digest]);

        // Independent web fixture actors review and authorize through the
        // backend's existing test helpers; the rider API cannot perform these steps.
        await control('authorize', issue: id);
        detail = await repo.detail(id);
        expect(detail.recovery!.canAcknowledge(DateTime.now()), true);
        final acknowledged = await repo.acknowledge(
          detail,
          barcode: detail.tracking,
          notes: 'Synthetic possession confirmation inside the isolated test only.',
          possessionVerified: true,
        );
        expect(acknowledged['event_type'], 'holder_acknowledged');
        detail = await repo.detail(id);
        expect(detail.held, true);
        expect(detail.recovery!.acknowledged, true);
        expect((await control('counts'))['acknowledgements'], 1);
        expect((await control('receive', issue: id))['state'], 'recovered');
        detail = await repo.detail(id);
        expect(detail.state, 'recovered');
        expect(detail.held, false);

        // No command was committed for this interruption. The backend returns
        // COMMAND_UNKNOWN and accepts only the retained original PDF intent.
        final pdf = HandoverFile(twoPagePdf(), 'pdf');
        loseBeforeCommit = true;
        await expectLater(
          report(barcodes[1], pdf),
          throwsA(isA<AccountFailure>()),
        );
        final unknown = (await journal.read())!;
        expect(await repo.reconcile(), isNull);
        expect((await journal.read())!.key, unknown.key);
        final pdfResult = (await repo.reconcile(retryUnknown: true))!;
        final pdfDetail = await repo.detail(pdfResult['issue_id'] as String);
        final document = await repo.evidence(pdfDetail);
        expect(document.mimeType, 'application/pdf');
        expect(document.bytes, pdf.bytes);
        expect(await journal.read(), isNull);
        final finalCounts = await control('counts');
        expect(finalCounts['reports'], 2);
        expect(finalCounts['commands'], 3);
        expect(finalCounts['acknowledgements'], 1);
        expect(finalCounts['evidence_hashes'], [png.digest, pdf.digest]);

        // Magic bytes alone do not make a readable image. Real backend field
        // validation must reach the client and release only the rejected intent.
        final broken = HandoverFile(
          Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
          'png',
        );
        await expectLater(
          report(barcodes[1], broken),
          throwsA(
            isA<AccountFailure>()
                .having((e) => e.status, 'status', 422)
                .having(
                  (e) => e.fields.containsKey('evidence'),
                  'field feedback',
                  true,
                ),
          ),
        );
        expect(await journal.read(), isNull);
      } finally {
        await journal?.clear();
        await auth.logout();
        dio.close(force: true);
      }
    },
    skip: base.isEmpty,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
