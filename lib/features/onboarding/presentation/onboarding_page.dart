import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/ui/brand_logo.dart';
import '../data/onboarding_preferences.dart';
import 'onboarding_art.dart';

final onboardingPreferencesProvider = Provider<OnboardingPreferences>(
  (ref) => LocalOnboardingPreferences(),
);

class OnboardingStatus {
  const OnboardingStatus({this.loaded = false, this.seen = false});
  final bool loaded, seen;
}

class OnboardingSeenNotifier extends Notifier<OnboardingStatus> {
  int _generation = 0;
  @override
  OnboardingStatus build() {
    final preferences = ref.watch(onboardingPreferencesProvider);
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    unawaited(
      Future.microtask(() async {
        var seen = false;
        try {
          seen = await preferences.readSeen().timeout(
            const Duration(seconds: 2),
          );
        } catch (_) {
          /* An unavailable preference store must not block sign-in. */
        }
        if (generation == _generation) {
          state = OnboardingStatus(loaded: true, seen: seen);
        }
      }),
    );
    return const OnboardingStatus();
  }

  Future<void> markSeen() async {
    _generation++;
    state = const OnboardingStatus(loaded: true, seen: true);
    try {
      await ref
          .read(onboardingPreferencesProvider)
          .writeSeen(true)
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      /* Show the introduction next launch if saving is unavailable. */
    }
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingSeenNotifier, OnboardingStatus>(
      OnboardingSeenNotifier.new,
    );

const _pages = [
  (
    eyebrow: 'YOUR RIDER WORKSPACE',
    title: 'Every parcel starts with you.',
    body: 'See your pickup and delivery tasks, check parcel details, and keep your work in one place.',
  ),
  (
    eyebrow: 'FIND YOUR NEXT STOP',
    title: 'Clear details for every stop.',
    body: 'Open a task to review its address, parcel details and handover instructions before you head out.',
  ),
  (
    eyebrow: 'KEEP EVERY HANDOVER CLEAR',
    title: 'Small updates. Clear progress.',
    body: 'Scan the waybill, confirm the handover, and keep pickup and delivery progress accurate.',
  ),
];

class RiderOnboardingPage extends ConsumerStatefulWidget {
  const RiderOnboardingPage({super.key, this.onContinue, this.onApply});
  final VoidCallback? onContinue, onApply;
  @override
  ConsumerState<RiderOnboardingPage> createState() =>
      _RiderOnboardingPageState();
}

class _RiderOnboardingPageState extends ConsumerState<RiderOnboardingPage> {
  int _page = 0;
  bool _leaving = false;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _finish({required bool register}) {
    if (_leaving) return;
    setState(() => _leaving = true);
    unawaited(ref.read(onboardingSeenProvider.notifier).markSeen());
    final callback = register ? widget.onApply : widget.onContinue;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context)
        .pushReplacementNamed(register ? '/register' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final current = _pages[_page];
    return Scaffold(
      key: const ValueKey('rider-onboarding-page'),
      backgroundColor: RiderColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            controller: _scroll,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 560,
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: BrandLogo(size: 36),
                                ),
                              ),
                              TextButton(
                                onPressed: _leaving
                                    ? null
                                    : () => _finish(register: true),
                                style: TextButton.styleFrom(
                                  foregroundColor: RiderColors.muted,
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                ),
                                child: const Text('Skip'),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  OnboardingArt(
                                    key: ValueKey('onboarding-art-$_page'),
                                    page: _page,
                                  ),
                                  const SizedBox(height: 26),
                                  Text(
                                    current.eyebrow,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 1.3,
                                      fontWeight: FontWeight.w700,
                                      color: RiderColors.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      current.title,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        height: 37 / 30,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -.65,
                                        color: RiderColors.ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    current.body,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: RiderColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 26),
                                  Semantics(
                                    label:
                                        'Introduction page ${_page + 1} of ${_pages.length}',
                                    liveRegion: true,
                                    child: ExcludeSemantics(
                                      child: Row(
                                        children: [
                                          for (
                                            var i = 0;
                                            i < _pages.length;
                                            i++
                                          )
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 7,
                                              ),
                                              child: Container(
                                                key: ValueKey(
                                                  'onboarding-dot-$i',
                                                ),
                                                width: i == _page ? 28 : 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: i == _page
                                                      ? RiderColors.accent
                                                      : RiderColors.border,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          FilledButton(
                            key: const ValueKey('onboarding-cta'),
                            onPressed: _leaving
                                ? null
                                : () {
                                    if (_page < _pages.length - 1) {
                                      setState(() => _page++);
                                      if (_scroll.hasClients) _scroll.jumpTo(0);
                                    } else {
                                      _finish(register: true);
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: RiderColors.accent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 54),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                height: 22 / 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    _page == _pages.length - 1
                                        ? 'Apply as a rider'
                                        : 'Next',
                                  ),
                                ),
                                if (_page < _pages.length - 1) ...[
                                  const SizedBox(width: 9),
                                  const Icon(Icons.arrow_forward, size: 20),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 5,
                            children: [
                              const Text(
                                'Already have an account?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: RiderColors.muted,
                                ),
                              ),
                              TextButton(
                                key: const ValueKey('onboarding-sign-in'),
                                onPressed: _leaving
                                    ? null
                                    : () => _finish(register: false),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                child: const Text('Sign in'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
