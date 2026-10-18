import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/ui/argon_widgets.dart';
import '../../../core/ui/brand_logo.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../workspace/presentation/workspace_shell.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final user = state.user!;
    if (user.approved) {
      return RiderWorkspaceShell(
        key: ValueKey('workspace-${user.id}'),
        account: user,
      );
    }
    final needsCorrection = user.kycStatus == 'rejected';
    return Scaffold(
      backgroundColor: RiderColors.canvas,
      body: RiderCanvas(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RiderSurface(
                      color: RiderColors.neumorphicSurface,
                      radius: RiderRadii.pill,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: const BrandLogo(),
                    ),
                    const SizedBox(height: 28),
                    RiderSurface(
                      color: RiderColors.neumorphicSurface,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 14,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const LiquidGlassOrb(size: 64, blurSigma: 14),
                              DieCutStickerWidget.speechBubble(
                                text: needsCorrection
                                    ? 'ACTION NEEDED'
                                    : 'UNDER REVIEW',
                                backgroundColor: needsCorrection
                                    ? RiderColors.accent
                                    : RiderColors.creamSticker,
                                textColor: needsCorrection
                                    ? Colors.white
                                    : RiderColors.ink,
                                rotationDegrees: 0,
                                leadingIcon: needsCorrection
                                    ? Icons.assignment_outlined
                                    : Icons.fact_check_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome, ${user.name}.',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You are signed in to your BagooPH rider account.',
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: ShapeDecoration(
                              color: RiderColors.controlFill,
                              shape: RoundedSuperellipseBorder(
                                borderRadius: BorderRadius.circular(
                                  RiderRadii.control,
                                ),
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  needsCorrection
                                      ? 'Application needs correction'
                                      : 'Application under review',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Your identity and vehicle documents must be reviewed before rider work becomes available.',
                                ),
                                if (user.feedback != null &&
                                    user.feedback!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    user.feedback!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 16),
                                const Text(
                                  'Your account',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(user.email),
                                const SizedBox(height: 8),
                                Text(
                                  'Account reference: ${user.id}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.emailVerified
                                      ? 'Email verified'
                                      : 'Email verification pending',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (state.error != null) ...[
                      Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    DecoratedBox(
                      decoration: const ShapeDecoration(
                        shape: StadiumBorder(),
                        shadows: RiderShadows.neumorphicAccent,
                      ),
                      child: RiderPressFeedback(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            shape: const StadiumBorder(),
                            minimumSize: const Size(0, 56),
                          ),
                          onPressed: state.busy
                              ? null
                              : () => ref
                                    .read(authControllerProvider.notifier)
                                    .refresh(),
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: const Text('Refresh account status'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    RiderPressFeedback(
                      child: TextButton(
                        key: const ValueKey('logout-button'),
                        onPressed: state.busy
                            ? null
                            : () => ref
                                  .read(authControllerProvider.notifier)
                                  .logout(),
                        child: Text(state.busy ? 'Please wait…' : 'Log out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
