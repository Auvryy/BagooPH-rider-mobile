import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/parcel_finder/data/parcel_location_labels.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'operations_contract_test.dart' as ops;
import 'support/parcel_finder_support.dart';
import 'support/test_auth_repository.dart';

RiderAccount account({String id = '5', bool approved = true}) => RiderAccount(
  id: id,
  name: 'Software Test Rider',
  email: 'rider@example.test',
  status: approved ? 'active' : 'pending_approval',
  kycStatus: approved ? 'approved' : 'pending',
  approved: approved,
  emailVerified: true,
  operationsApiVersion: 1,
);

class FinderAuth extends TestAuthRepository implements RiderSessionApi {
  FinderAuth(this.api) {
    this.account = account();
  }
  final ops.Session api;
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('the actual workspace provider replaces label memory for API/account changes and approval loss', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final h = ParcelFinderHarness();
    addTearDown(h.dispose);
    final auth = FinderAuth(h.api);
    var config = const AppConfig(ParcelFinderHarness.origin);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        appConfigProvider.overrideWithValue(config),
      ],
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    final family = workspaceControllerProvider(const WorkspaceIdentity('5'));
    final subscription = container.listen(family, (_, _) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    final first = container.read(family);
    final task = h.task();
    await first.openTask(OperationsRepository.asRiderTask(task));
    expect(
      await first.setParcelLocation(
        task,
        ParcelSlot.bag2,
        mayApply: () => true,
      ),
      isNull,
    );
    expect(first.parcelLocationFor(task), ParcelSlot.bag2);

    config = const AppConfig('https://other.example.test/api/v1');
    container.updateOverrides([
      authRepositoryProvider.overrideWithValue(auth),
      appConfigProvider.overrideWithValue(config),
    ]);
    await Future<void>.delayed(Duration.zero);
    final changedApi = container.read(family);
    expect(identical(changedApi, first), isFalse);
    expect(first.parcelLocationFor(task), isNull);
    expect(changedApi.parcelLocationFor(task), isNull);
    await changedApi.openTask(OperationsRepository.asRiderTask(task));
    expect(
      await changedApi.setParcelLocation(
        task,
        ParcelSlot.bag1,
        mayApply: () => true,
      ),
      isNull,
    );

    h.accountId = '6';
    auth.account = account(id: '6');
    await container.read(authControllerProvider.notifier).refresh();
    await Future<void>.delayed(Duration.zero);
    expect(changedApi.parcelLocationFor(task), isNull);
    expect(container.read(family).parcelFinderAvailable, isFalse);
    final newFamily = workspaceControllerProvider(const WorkspaceIdentity('6'));
    final newSubscription = container.listen(newFamily, (_, _) {});
    addTearDown(newSubscription.close);
    await Future<void>.delayed(Duration.zero);
    final otherAccount = container.read(newFamily);
    expect(otherAccount.parcelLocationFor(task), isNull);
    await otherAccount.openTask(OperationsRepository.asRiderTask(task));
    expect(
      await otherAccount.setParcelLocation(
        task,
        ParcelSlot.topBoxLeft,
        mayApply: () => true,
      ),
      isNull,
    );

    auth.account = account(id: '6', approved: false);
    await container.read(authControllerProvider.notifier).refresh();
    await Future<void>.delayed(Duration.zero);
    expect(otherAccount.parcelLocationFor(task), isNull);
    expect(container.read(newFamily).parcelFinderAvailable, isFalse);
    expect(h.api.calls.where((call) => call.method != 'GET'), isEmpty);
  });
}
