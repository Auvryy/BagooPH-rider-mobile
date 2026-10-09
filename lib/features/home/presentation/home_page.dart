import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/ui/brand_logo.dart';
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandLogo(),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome, ${user.name}.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You are signed in to your BagooPH rider account.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(RiderRadii.surface),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(user.email),
                        const SizedBox(height: 8),
                        Text('Account reference: ${user.id}'),
                        const SizedBox(height: 8),
                        Text(
                          user.emailVerified
                              ? 'Email verified'
                              : 'Email verification pending',
                        ),
                        const SizedBox(height: 24),
                        Text(
                          user.approved
                              ? 'Rider account approved'
                              : user.kycStatus == 'rejected'
                              ? 'Application needs correction'
                              : 'Application under review',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: RiderColors.accentText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.approved
                              ? 'Your account approval is recorded. Task and assignment pages are not connected yet.'
                              : 'Your identity and vehicle documents must be reviewed before rider work becomes available.',
                        ),
                        if (user.feedback != null &&
                            user.feedback!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(user.feedback!),
                        ],
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
                  OutlinedButton(
                    onPressed: state.busy
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .refresh(),
                    child: const Text('Refresh account status'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('logout-button'),
                    onPressed: state.busy
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .logout(),
                    child: Text(state.busy ? 'Please wait…' : 'Log out'),
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
