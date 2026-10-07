import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_shell.dart';
import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.onOpenHomePreview});
  final VoidCallback? onOpenHomePreview;
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberEmail = false;

  @override
  void initState() {
    super.initState();
    final remembered = ref
        .read(authControllerProvider.notifier)
        .rememberedEmail;
    _email.text = remembered ?? '';
    _rememberEmail = remembered != null;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(authControllerProvider.notifier)
        .rememberEmail(_rememberEmail ? _email.text.trim() : null);
    await ref
        .read(authControllerProvider.notifier)
        .login(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider);
    return AuthShell(
      registering: false,
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome back.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your rider workspace.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              AuthField(
                label: 'Email address',
                controller: _email,
                hint: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                validator: (value) {
                  if (requiredText(value, 'email address') case final error?) {
                    return error;
                  }
                  if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(value!.trim())) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AuthField(
                label: 'Password',
                controller: _password,
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                password: true,
                autofillHints: const [AutofillHints.password],
                validator: (value) => requiredText(value, 'password'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final remember = InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () =>
                        setState(() => _rememberEmail = !_rememberEmail),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _rememberEmail,
                          onChanged: (value) =>
                              setState(() => _rememberEmail = value ?? false),
                        ),
                        const Flexible(
                          child: Text(
                            'Remember email',
                            style: TextStyle(
                              fontSize: 13,
                              color: RiderColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  final recovery = TextButton(
                    onPressed: () => showAuthPreviewMessage(
                      context,
                      title: 'Password recovery',
                      message:
                          'Password recovery is handled by the Bagoo website. '
                          'Use its Forgot password page to request a reset. This page does not send recovery emails.',
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(fontSize: 13),
                    ),
                  );
                  if (constraints.maxWidth < 340 ||
                      MediaQuery.textScalerOf(context).scale(13) > 18) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [remember, recovery],
                    );
                  }
                  return Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [remember, recovery],
                  );
                },
              ),
              const SizedBox(height: 20),
              if (session.error != null) ...[
                Text(
                  session.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                key: const ValueKey('sign-in-button'),
                onPressed: session.busy ? null : _signIn,
                child: Text(session.busy ? 'Signing in…' : 'Sign in'),
              ),
              if (kDebugMode && widget.onOpenHomePreview != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey('demo-login'),
                  onPressed: session.busy
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          _password.clear();
                          widget.onOpenHomePreview!();
                        },
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Demo login'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Preview Home with sample tasks. No account needed.',
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text('New to BagooPH Rider?', textAlign: TextAlign.center),
              const SizedBox(height: 4),
              TextButton(
                key: const ValueKey('open-register'),
                onPressed: () => Navigator.of(context).pushNamed('/register'),
                child: const Text('Apply as a rider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
