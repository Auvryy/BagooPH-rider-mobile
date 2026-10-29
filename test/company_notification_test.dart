import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/notifications/data/notification_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/company_support.dart';
import 'support/notifications_support.dart';

Map<String, dynamic> me({String id = '5', bool enabled = true}) => {
  'data': {
    'id': id,
    'name': 'Example Rider',
    'email': 'rider@example.test',
    'role': 'courier',
    'status': 'active',
    'kyc_status': 'approved',
    'access_state': 'approved',
    'can_access_portal': true,
    'email_verified': true,
    if (enabled) 'company_api_version': 1,
  },
};

NotificationTarget target(String kind, String id) => NotificationTarget.parse({
  'kind': kind,
  'id': id,
  'href': kind == 'company_request'
      ? '/api/v1/rider/company-requests/$id'
      : '/api/v1/rider/company-assignment',
})!;

void main() {
  test(
    'company offer notices recheck account access and the owned saved request',
    () async {
      final h = NotificationsHarness();
      addTearDown(h.dispose);
      h.api.respond = (path, method, body, headers) async => path == 'rider/me'
          ? me()
          : {'data': companyFixture('application-offered')};
      final destination = await h.repository.resolve(
        target('company_request', '1'),
        cancellation: RiderReadCancellation(),
      ) as NotificationCompanyDestination;
      expect(destination.accountId, '5');
      expect(destination.applicationId, '1');
      expect(h.api.calls.map((c) => c.path), [
        'rider/me',
        'rider/company-requests/1',
      ]);
      expect(h.api.calls.every((c) => c.method == 'GET'), isTrue);
      await expectLater(
        h.repository.resolve(
          target('company_request', '2'),
          cancellation: RiderReadCancellation(),
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'assignment notices open current membership only for their own account',
    () async {
      final h = NotificationsHarness();
      addTearDown(h.dispose);
      h.api.respond = (path, method, body, headers) async => path == 'rider/me'
          ? me()
          : {'data': companyFixture('assignment-accepted')};
      await expectLater(
        h.repository.resolve(
          target('company_assignment', '6'),
          cancellation: RiderReadCancellation(),
        ),
        throwsFormatException,
      );
      expect(h.api.calls, isEmpty);
      final destination = await h.repository.resolve(
        target('company_assignment', '5'),
        cancellation: RiderReadCancellation(),
      ) as NotificationCompanyDestination;
      expect(destination.accountId, '5');
      expect(destination.applicationId, isNull);
      expect(h.api.calls.last.path, 'rider/company-assignment');
    },
  );
  test('changed accounts or disabled company access cannot follow an old offer notice', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    h.api.respond = (_, _, _, _) async => me(id: '6');
    await expectLater(
      h.repository.resolve(
        target('company_request', '1'),
        cancellation: RiderReadCancellation(),
      ),
      throwsFormatException,
    );
    h.api.respond = (_, _, _, _) async => me(enabled: false);
    await expectLater(
      h.repository.resolve(
        target('company_request', '1'),
        cancellation: RiderReadCancellation(),
      ),
      throwsA(isA<AccountFailure>()),
    );
    expect(h.api.calls.every((c) => c.path == 'rider/me'), isTrue);
  });
}
