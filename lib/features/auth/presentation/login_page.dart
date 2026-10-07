import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberEmail = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signIn() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    showAuthPreviewMessage(
      context,
      title: 'Sign-in preview',
      message:
          'You can explore the login and registration screens here. '
          'Sign-in is not connected, and your details are not sent anywhere.',
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          'Password recovery will be available when sign-in '
                          'is connected. This preview does not send recovery emails.',
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
              FilledButton(
                key: const ValueKey('sign-in-button'),
                onPressed: _signIn,
                child: const Text('Sign in'),
              ),
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
