import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/theme.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/home/presentation/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Plus Jakarta Sans'], license);
  });

  const previewRequested = bool.fromEnvironment(
    'DEVICE_PREVIEW',
    defaultValue: false,
  );
  final previewEnabled =
      kDebugMode &&
      previewRequested &&
      (kIsWeb || defaultTargetPlatform == TargetPlatform.linux);
  runApp(
    ProviderScope(
      child: previewEnabled
          ? DevicePreview(
              builder: (_) => const BagooRiderApp(useDevicePreview: true),
            )
          : const BagooRiderApp(),
    ),
  );
}

class BagooRiderApp extends ConsumerStatefulWidget {
  const BagooRiderApp({super.key, this.useDevicePreview = false});
  final bool useDevicePreview;

  @override
  ConsumerState<BagooRiderApp> createState() => _BagooRiderAppState();
}

class _BagooRiderAppState extends ConsumerState<BagooRiderApp>
    with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed && mounted) {
      final session = ref.read(authControllerProvider);
      if (session.user != null && !session.busy) {
        unawaited(ref.read(authControllerProvider.notifier).refresh());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id ||
          (previous?.user?.approved == true && next.user?.approved != true)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigator.currentState?.pushNamedAndRemoveUntil('/', (_) => false);
          }
        });
      }
    });
    return MaterialApp(
      navigatorKey: _navigator,
      title: 'BagooPH Rider',
      debugShowCheckedModeBanner: false,
      locale: widget.useDevicePreview ? DevicePreview.locale(context) : null,
      builder: widget.useDevicePreview ? DevicePreview.appBuilder : null,
      theme: buildRiderTheme(),
      routes: {
        '/': (_) => const AccountGate(),
        '/login': (_) => const AccountGate(),
        '/register': (_) => const AccountGate(register: true),
      },
    );
  }
}

class AccountGate extends ConsumerWidget {
  const AccountGate({super.key, this.register = false});
  final bool register;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    if (state.initializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Restoring account session',
          ),
        ),
      );
    }
    if (state.user != null) return const HomePage();
    return register ? const RegisterPage() : const LoginPage();
  }
}
