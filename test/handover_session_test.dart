import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/handover/presentation/handover_entry.dart';
import 'package:bagoo_rider_mobile/features/handover/presentation/handover_issues_page.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'handover_pages_test.dart' show tap;
import 'support/handover_support.dart';
import 'support/test_auth_repository.dart';

RiderAccount sessionAccount({
  String id = '5',
  bool approved = true,
  int? handover = 1,
}) => RiderAccount(
  id: id,
  name: 'Example Rider',
  email: 'rider@example.test',
  status: approved ? 'active' : 'pending_approval',
  kycStatus: approved ? 'approved' : 'rejected',
  approved: approved,
  emailVerified: true,
  operationsApiVersion: 1,
  handoverApiVersion: handover,
);

class HandoverAuth extends TestAuthRepository
    implements RiderSessionApi, RiderEvidenceSessionApi {
  HandoverAuth(this.api) {
    account = sessionAccount();
  }
  final HandoverSession api;
  @override
  Future<Map<String, dynamic>> authenticatedRequest(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, String> headers = const {},
  }) => api.authenticatedRequest(
    path,
    method: method,
    data: data,
    headers: headers,
  );
  @override
  Future<PrivateApiBytes> authenticatedEvidence(String path) =>
      api.authenticatedEvidence(path);
}

void main() {
  for (final change in ['account', 'approval', 'handover-version']) {
    testWidgets(
      'Home handover entry preserves main navigation and closes private routes on $change loss',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        final api = HandoverSession(), auth = HandoverAuth(api);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(auth),
              appConfigProvider.overrideWithValue(
                const AppConfig(
                  'https://bagoo.example.test/api/v1',
                  handoverWritesVerified: true,
                ),
              ),
            ],
            child: MaterialApp(
              theme: buildRiderTheme(),
              home: Scaffold(
                body: Column(
                  children: [
                    const Text('Existing Home navigation'),
                    HandoverEntry(
                      home: OperationsHome.fromJson(api.home['data']),
                      accountId: '5',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('home-handover-issues')));
        await tester.pumpAndSettle();
        await tap(tester, 'handover-issue-1');
        expect(find.text('Reported observations'), findsOneWidget);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HandoverIssuesPage)),
        );
        auth.account = sessionAccount(
          id: change == 'account' ? '6' : '5',
          approved: change != 'approval',
          handover: change == 'handover-version' ? null : 1,
        );
        await container.read(authControllerProvider.notifier).refresh();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('handover-page')), findsNothing);
        expect(find.text('Reported observations'), findsNothing);
        expect(find.text('Existing Home navigation'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(api.calls.where((x) => x.method == 'POST'), isEmpty);
      },
    );
  }
  testWidgets('undeployed Home discovery cannot open handover routes', (
    tester,
  ) async {
    final api = HandoverSession();
    api.home['data']['handover_api_version'] = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRiderTheme(),
        home: Scaffold(
          body: HandoverEntry(
            home: OperationsHome.fromJson(api.home['data']),
            accountId: '5',
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('home-handover-issues')),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Handover issues unavailable'), findsOneWidget);
  });
}
