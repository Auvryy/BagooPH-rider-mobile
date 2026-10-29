// Run through tool/parcel_local_api/run.mjs. Real native Dart HTTP and Laravel;
// synthetic accounts and SQLite :memory:, with an explicit test storage adapter.
import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/auth/data/registration_options.dart';
import 'package:bagoo_rider_mobile/features/cash/data/cash_models.dart';
import 'package:bagoo_rider_mobile/features/company/data/company_repository.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const base = String.fromEnvironment('LOCAL_COMPANY_API_BASE');
  const fixtureToken = String.fromEnvironment('LOCAL_COMPANY_FIXTURE_TOKEN');
  test(
    'native company requests recover once and record only the exact accepted assignment',
    () async {
      final originalOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = originalOverrides);
      FlutterSecureStorage.setMockInitialValues({});
      final origin = Uri.parse(base);
      if (origin.scheme != 'http' ||
          origin.host != '127.0.0.1' ||
          origin.path.isNotEmpty ||
          fixtureToken.isEmpty) {
        throw StateError('Use the isolated company runner.');
      }
      Future<Map<String, dynamic>> control(String operation) async {
        final client = HttpClient();
        try {
          final request = await client.postUrl(origin.resolve('/fixture'));
          request.headers.set('X-Local-Fixture', fixtureToken);
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode({'operation': operation}));
          final response = await request.close().timeout(
            const Duration(seconds: 50),
          );
          expect(response.statusCode, 200);
          return jsonDecode(await response.transform(utf8.decoder).join())
              as Map<String, dynamic>;
        } finally {
          client.close(force: true);
        }
      }

      final info = await control('info');
      expect(info['database'], ':memory:');
      final dio = Dio();
      var next = DateTime.now(), loseBefore = true, loseAfter = false;
      final attempts = <({String path, Object? key, String body})>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            final delay = next.difference(DateTime.now());
            if (delay > Duration.zero) await Future<void>.delayed(delay);
            next = DateTime.now().add(const Duration(milliseconds: 2300));
            if (request.method == 'POST' &&
                request.path.contains('/company-requests')) {
              attempts.add((
                path: request.path,
                key: request.headers['Idempotency-Key'],
                body: jsonEncode(request.data),
              ));
              if (loseBefore) {
                loseBefore = false;
                handler.reject(
                  DioException(
                    requestOptions: request,
                    type: DioExceptionType.connectionError,
                    error: 'Test interruption before dispatch.',
                  ),
                );
                return;
              }
            }
            handler.next(request);
          },
          onResponse: (response, handler) {
            if (loseAfter &&
                response.requestOptions.path.endsWith('/accept') &&
                response.statusCode == 200) {
              loseAfter = false;
              handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  type: DioExceptionType.receiveTimeout,
                  error: 'Test interruption after commit.',
                ),
              );
              return;
            }
            handler.next(response);
          },
        ),
      );
      final config = AppConfig('$base/api/v1', localAuth: true);
      final auth = ApiAuthRepository(config, MemoryTokenStore(), client: dio);
      addTearDown(() => dio.close(force: true));
      final options = RiderRegistrationOptions.fromJson(
        await auth.registrationOptions(),
      );
      expect(
        options.submission(
          sex: options.sexOptions.first,
          accepted: true,
        )['terms_version'],
        options.termsVersion,
      );
      final account = await auth.login(
        info['email'] as String,
        info['password'] as String,
      );
      expect(account.companyApiVersion, 1);
      final journal = SecureCommandJournal(
        origin: config.origin,
        accountId: account.id,
        scope: 'company',
        storage: const FlutterSecureStorage(),
      );
      RiderCompanyRepository repository() => RiderCompanyRepository(
        auth,
        accountId: account.id,
        journal: journal,
        isCurrent: () => true,
      );
      var repo = repository();
      expect((await repo.assignment()).canApply, isTrue);
      final company = (await repo.companies(
        search: 'Bagoo',
        province: 'Laguna',
      )).items.single;
      await expectLater(
        repo.submit(
          company,
          sharingAcknowledged: true,
          note: 'Available for scheduled work.',
          mayDispatch: () => true,
        ),
        throwsA(isA<AccountFailure>()),
      );
      final original = (await journal.read())!;
      expect((await control('counts'))['requests'], 0);
      // Recreate the repository as after app restart; it must retain the original key.
      repo = repository();
      await expectLater(
        repo.reconcile(mayDispatch: () => true),
        throwsA(isA<AccountFailure>()),
      );
      expect((await journal.read())?.key, original.key);
      final submitted = (await repo.reconcile(
        retryUnknown: true,
        mayDispatch: () => true,
      ))!;
      expect(submitted.status, 'pending');
      expect(attempts[0], attempts[1]);
      expect(await journal.read(), isNull);
      await control('offer');
      final reviewed = await repo.application(submitted.applicationId);
      expect(reviewed.canAccept, isTrue);
      await control('offer');
      await expectLater(
        repo.decide(
          reviewed,
          'company.accepted',
          acknowledged: true,
          mayDispatch: () => true,
        ),
        throwsA(
          isA<AccountFailure>().having(
            (e) => e.code,
            'code',
            'STALE_COMPANY_OFFER',
          ),
        ),
      );
      expect(attempts, hasLength(2));
      final current = await repo.application(submitted.applicationId);
      expect(current.offer!.id, isNot(reviewed.offer!.id));
      loseAfter = true;
      await expectLater(
        repo.decide(
          current,
          'company.accepted',
          acknowledged: true,
          mayDispatch: () => true,
        ),
        throwsA(isA<AccountFailure>()),
      );
      expect(await journal.read(), isNotNull);
      repo = repository();
      final accepted = await repo.reconcile(mayDispatch: () => false);
      expect(accepted?.status, 'accepted');
      expect(await journal.read(), isNull);
      expect(attempts, hasLength(3));
      final assignment = await repo.assignment();
      expect(assignment.companyId, company.id);
      expect(assignment.hubName, 'Bagoo Bayan Hub');
      expect(assignment.onDuty, isFalse);
      expect(assignment.canApply, isFalse);
      final home = OperationsHome.fromJson(
        (await auth.authenticatedRequest('rider/home'))['data']
            as Map<String, dynamic>,
      );
      expect(home.accountId, account.id);
      expect(home.onDuty, isFalse);
      expect(home.shift?.held, BigInt.zero);
      final cash = CashPage.fromJson(
        (await auth.authenticatedRequest(
              'rider/cash?page=1&per_page=20',
            ))['data']
            as Map<String, dynamic>,
      );
      expect(cash.earnings.available, isTrue);
      expect(cash.earnings.confirmed, BigInt.zero);
      expect(cash.earnings.pending, BigInt.zero);
      expect(cash.shift?.canClose, isTrue);
      final saved = await repo.application(submitted.applicationId);
      expect(saved.effectiveStatus, 'accepted');
      expect(saved.canAccept, isFalse);
      final counts = await control('counts');
      expect(counts['requests'], 1);
      expect(counts['commands'], 2);
      expect(counts['consents'], 1);
      expect(counts['placements'], 1);
      expect(counts['on_duty'], isFalse);
      expect(counts['delivery_checkpoints'], 0);
      expect(counts['cod_accounts'], 0);
    },
    skip: base.isEmpty,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
