import 'dart:async';
import 'dart:convert';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/commands/command_intent.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_proof.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_validation.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/parcels/data/parcel_photo_service.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'operations_contract_test.dart' as ops;
import 'support/parcel_finder_support.dart';
import 'support/parcel_support.dart';
import 'support/photo_support.dart';
import 'support/test_auth_repository.dart';

RiderAccount _account({required bool approved}) => RiderAccount(
  id: '5',
  name: 'Software Test Rider',
  email: 'rider@example.test',
  status: approved ? 'active' : 'pending_approval',
  kycStatus: approved ? 'approved' : 'pending_approval',
  approved: approved,
  emailVerified: true,
  operationsApiVersion: 1,
);

class _LifecycleAuth extends TestAuthRepository implements RiderSessionApi {
  _LifecycleAuth(this.api) {
    account = _account(approved: true);
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

class _ObservedParcelPhotoService extends ParcelPhotoService {
  _ObservedParcelPhotoService({
    required super.origin,
    required super.accountId,
    required super.proofs,
    required super.picker,
    required super.isCurrent,
  }) {
    addListener(() {
      if (!busy && !restoreFinished.isCompleted) restoreFinished.complete();
    });
  }

  final restoreFinished = Completer<void>();
  final accessLossCleanupFinished = Completer<void>();

  @override
  Future<void> clearForAccessLoss() async {
    await super.clearForAccessLoss();
    if (!accessLossCleanupFinished.isCompleted) {
      accessLossCleanupFinished.complete();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('approved-account loss purges the old photo before a later approval can restore it', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final domain = ParcelFinderHarness();
    addTearDown(domain.dispose);
    final auth = _LifecycleAuth(domain.api);
    final testProofs = ParcelTestProofStore();
    final picker = TestParcelPhotoPicker();
    final services = <_ObservedParcelPhotoService>[];
    final secondService = Completer<_ObservedParcelPhotoService>();
    _ObservedParcelPhotoService photoFactory({
      required Uri origin,
      required String accountId,
      required ParcelProofStore proofs,
      required bool Function() isCurrent,
    }) {
      final service = _ObservedParcelPhotoService(
        origin: origin,
        accountId: accountId,
        proofs: testProofs,
        picker: picker,
        isCurrent: isCurrent,
      );
      services.add(service);
      if (services.length == 2) secondService.complete(service);
      return service;
    }

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        appConfigProvider.overrideWithValue(
          const AppConfig(ParcelFinderHarness.origin),
        ),
        parcelPhotoServiceFactoryProvider.overrideWithValue(photoFactory),
      ],
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    final family = workspaceControllerProvider(const WorkspaceIdentity('5'));
    final subscription = container.listen(family, (_, _) {});
    addTearDown(subscription.close);

    await services.first.restoreFinished.future.timeout(
      const Duration(seconds: 2),
    );
    final photos = services.first;
    final proof = await photos.choose(
      taskId: 'final_mile-1',
      version: 'a' * 64,
      action: ParcelAction.deliver,
      camera: false,
    );
    final commandCopy = await testProofs.save(commandUuid(), proof!);
    final draftKey =
        'bagoo_rider_parcel_photo_${base64UrlEncode(utf8.encode('${ParcelFinderHarness.origin}/5'))}';
    final storage = const FlutterSecureStorage();
    expect(await storage.read(key: draftKey), isNotNull);

    auth.account = _account(approved: false);
    await container.read(authControllerProvider.notifier).refresh();
    await photos.accessLossCleanupFinished.future.timeout(
      const Duration(seconds: 2),
    );
    expect(photos.recovered, isNull);
    expect(await storage.read(key: draftKey), isNull);
    expect(testProofs.files.keys, [commandCopy.key]);

    auth.account = _account(approved: true);
    await container.read(authControllerProvider.notifier).refresh();
    final restoredWorkspace = await secondService.future.timeout(
      const Duration(seconds: 2),
    );
    await restoredWorkspace.restoreFinished.future.timeout(
      const Duration(seconds: 2),
    );
    expect(restoredWorkspace.recovered, isNull);
    expect(testProofs.files.keys, [commandCopy.key]);
  });
}
