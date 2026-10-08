import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/widgets/auth_field.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:dio/dio.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/rider_website.dart';

Finder field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is AuthField && w.label == label),
  matching: find.byType(TextFormField),
);

Future<void> tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _SyntheticPicker extends FileSelectorPlatform {
  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => XFile.fromData(
    Uint8List.fromList(
      utf8.encode(
        '%PDF-1.4\n1 0 obj <</Type /Catalog>> endobj\n'
        '% SYNTHETIC INTEGRATION TEST DOCUMENT - NOT VALID ID\n%%EOF\n',
      ),
    ),
    name: 'synthetic-integration-test.pdf',
    path: 'synthetic-integration-test.pdf',
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  const enabled = bool.fromEnvironment('LIVE_AZURE_SIGNUP');
  testWidgets(
    'live native verified signup, private uploads and website compatibility',
    (tester) async {
      binding.shouldPropagateDevicePointerEvents = true;
      final config = AppConfig.environment();
      if (config.origin.scheme != 'https' ||
          config.origin.host != 'bagooph.shop') {
        throw StateError(
          'Use the reviewed HTTPS profile for this live signup check.',
        );
      }
      final input = jsonDecode(
        await File('build/native-checks/azure-signup-input.json')
            .readAsString(),
      ) as Map;
      final email = input['email'] as String;
      final password =
          'RiderTest!${base64UrlEncode(List.generate(24, (_) => Random.secure().nextInt(256)))}';
      final store = SecureTokenStore(apiOrigin: config.origin);
      if (await store.read() != null) {
        throw StateError(
          'Sign out of the existing native device session before this check.',
        );
      }
      var emailSent = false;
      int? emailStatus;
      var privateUploadCount = 0;
      final transport = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onResponse: (r, handler) {
              if (r.requestOptions.path.endsWith('/email/send')) {
                emailStatus = r.statusCode;
                emailSent = r.statusCode == 200 && r.data['success'] == true;
              }
              if (r.requestOptions.path.endsWith('/rider/applications') &&
                  r.statusCode == 201) {
                privateUploadCount =
                    (r.requestOptions.data as FormData).files.length;
              }
              handler.next(r);
            },
            onError: (error, handler) {
              if (error.requestOptions.path.endsWith('/email/send')) {
                emailStatus = error.response?.statusCode ?? 0;
              }
              handler.next(error);
            },
          ),
        );
      final repo = ApiAuthRepository(config, store, client: transport);
      final originalPicker = FileSelectorPlatform.instance;
      FileSelectorPlatform.instance = _SyntheticPicker();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(repo)],
            child: const BagooRiderApp(),
          ),
        );
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(const ValueKey('open-register')));
        await tester.enterText(field('Full name'), 'Integration Test Rider');
        await tester.enterText(field('Email address'), email);
        await tester.enterText(field('Mobile number'), '09173334444');
        await tester.enterText(
          field('Street address'),
          'Integration Test Street',
        );
        await tester.enterText(field('City / municipality'), 'Pasig');
        await tap(tester, find.byKey(const ValueKey('birthday-picker')));
        await tap(tester, find.text('OK'));
        await tap(tester, find.byKey(const ValueKey('registration-next')));
        await tester.enterText(
          field('Plate or registration number'),
          'TEST-123',
        );
        await tester.enterText(field('Driver’s license number'), 'TEST-123');
        await tap(tester, find.byKey(const ValueKey('registration-next')));
        for (final key in [
          'identity-document',
          'license-document',
          'vehicle-document',
        ]) {
          await tap(
            tester,
            find.descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.widgetWithText(OutlinedButton, 'Choose document'),
            ),
          );
        }
        await tester.enterText(field('Create password'), password);
        await tester.enterText(field('Confirm password'), password);
        await tap(tester, find.byKey(const ValueKey('registration-next')));
        final emailDeadline = DateTime.now().add(const Duration(seconds: 45));
        while (emailStatus == null && DateTime.now().isBefore(emailDeadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (!emailSent) {
          throw StateError(
            'The live verification email endpoint returned status ${emailStatus ?? 0}.',
          );
        }
        debugPrint('WAITING_FOR_PRIVATE_EMAIL_CODE_IN_NATIVE_APP');
        binding.framePolicy =
            LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
        final deadline = DateTime.now().add(const Duration(minutes: 8));
        while (find.byKey(const ValueKey('logout-button')).evaluate().isEmpty) {
          if (DateTime.now().isAfter(deadline)) {
            throw StateError(
              'Private verification input did not complete before the check deadline.',
            );
          }
          await tester.pump(const Duration(milliseconds: 200));
        }
        await tester.pumpAndSettle();
        final account = await repo.refresh();
        expect(account.emailVerified, isTrue);
        expect(account.approved, isFalse);
        expect(account.status == 'pending_approval', isTrue);
        expect(find.text('Application under review'), findsOneWidget);
        expect(privateUploadCount == 3, isTrue);
        expect(
          await confirmRiderWebsiteAccount(
            config.origin,
            account,
            password,
            report: debugPrint,
          ),
          isTrue,
        );
        debugPrint(
          'AZURE_NATIVE_SIGNUP_PRIVATE_UPLOADS_PENDING_HOME_AND_WEBSITE_LOGIN_PASSED',
        );
        await tap(tester, find.byKey(const ValueKey('logout-button')));
        expect(find.text('Welcome back.'), findsOneWidget);
      } finally {
        FileSelectorPlatform.instance = originalPicker;
        await repo.logout();
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
    skip: !enabled,
  );
}
