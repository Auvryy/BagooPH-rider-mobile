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
import 'features/onboarding/presentation/onboarding_page.dart';

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
      // Do not dismiss the welcome onboarding during initial cold-start session restore.
      if (previous == null || previous.initializing) {
        return;
      }
      if (previous.user?.id != next.user?.id ||
          (previous.user?.approved == true && next.user?.approved != true)) {
        unawaited(ref.read(onboardingSeenProvider.notifier).markSeen());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Account changes remove private routes without decorative delay.
            _navigator.currentState?.pushAndRemoveUntil<void>(
              PageRouteBuilder<void>(
                settings: const RouteSettings(name: '/'),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (_, _, _) => const AccountGate(),
              ),
              (_) => false,
            );
          }
        });
      }
    });
    return MaterialApp(
      navigatorKey: _navigator,
      title: 'BagooPH Rider',
      debugShowCheckedModeBanner: false,
      locale: widget.useDevicePreview ? DevicePreview.locale(context) : null,
      builder: (context, child) {
        final previewChild = widget.useDevicePreview
            ? DevicePreview.appBuilder(context, child)
            : child ?? const SizedBox.shrink();
        return _AppPrivacyCover(child: previewChild);
      },
      theme: buildRiderTheme(),
      highContrastTheme: buildRiderTheme(highContrast: true),
      scrollBehavior: const RiderScrollBehavior(),
      routes: {
        '/': (_) => const AccountGate(onboarding: true),
        '/onboarding': (_) => const RiderOnboardingPage(),
        '/login': (_) => const AccountGate(),
        '/register': (_) => const AccountGate(register: true),
      },
    );
  }
}

class _AppPrivacyCover extends StatefulWidget {
  const _AppPrivacyCover({required this.child});

  final Widget child;

  @override
  State<_AppPrivacyCover> createState() => _AppPrivacyCoverState();
}

class _AppPrivacyCoverState extends State<_AppPrivacyCover>
    with WidgetsBindingObserver {
  bool _foreground =
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (mounted && _foreground != foreground) {
      setState(() => _foreground = foreground);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeSemantics(
        excluding: !_foreground,
        child: IgnorePointer(ignoring: !_foreground, child: widget.child),
      ),
      if (!_foreground) const Positioned.fill(child: _AppPausedCover()),
    ],
  );
}

class _AppPausedCover extends StatelessWidget {
  const _AppPausedCover();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: RiderColors.canvas,
    child: SafeArea(
      child: Center(
        child: Semantics(
          container: true,
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 36,
                  color: RiderColors.accentText,
                ),
                const SizedBox(height: 16),
                Text(
                  'Rider is paused',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: RiderColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Return to Rider to continue.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: RiderColors.muted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AccountGate extends ConsumerWidget {
  const AccountGate({
    super.key,
    this.register = false,
    this.onboarding = false,
  });
  final bool register;
  final bool onboarding;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final seenOnboarding = ref.watch(onboardingSeenProvider);
    if (onboarding && !seenOnboarding.loaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(semanticsLabel: 'Opening rider app'),
        ),
      );
    }
    if (onboarding && !seenOnboarding.seen) return const RiderOnboardingPage();
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
    if (register) return const RegisterPage();
    return const LoginPage();
  }
}
