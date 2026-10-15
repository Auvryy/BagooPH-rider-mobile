import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandLogo(),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: RiderColors.rose,
                      child: Icon(
                        needsCorrection
                            ? Icons.assignment_outlined
                            : Icons.fact_check_outlined,
                        size: 32,
                        color: RiderColors.accentText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome, ${user.name}.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You are signed in to your BagooPH rider account.',
                  ),
                  const SizedBox(height: 24),
                  RiderSurface(
                    padding: const EdgeInsets.all(24),
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 20),
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
                  RiderPressFeedback(
                    child: FilledButton.icon(
                      onPressed: state.busy
                          ? null
                          : () => ref
                                .read(authControllerProvider.notifier)
                                .refresh(),
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text('Refresh account status'),
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
    );
  }
}
