import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/ui/argon_widgets.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_shell.dart';
import 'auth_controller.dart';

import '../../../core/ui/rider_surfaces.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: ShapeDecoration(
                  color: RiderColors.controlFill,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(RiderRadii.control),
                    side: const BorderSide(color: Colors.white, width: 1.5),
                  ),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const LiquidGlassOrb(size: 42, blurSigma: 12),
                    DieCutStickerWidget.speechBubble(
                      text: 'LET’S GET MOVING',
                      backgroundColor: RiderColors.accent,
                      rotationDegrees: -2,
                      leadingIcon: Icons.bolt_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome back.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Your next pickup starts here. Sign in to continue.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 20),
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
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final remember = RiderPressFeedback(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(RiderRadii.pill),
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
                                fontWeight: FontWeight.w600,
                                color: RiderColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  final recovery = RiderPressFeedback(
                    child: TextButton(
                      onPressed: () => showAuthPreviewMessage(
                        context,
                        title: 'Password recovery',
                        message:
                            'Password recovery is handled by the Bagoo website. '
                            'Use its Forgot password page to request a reset. This page does not send recovery emails.',
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                  if (constraints.maxWidth < 300 ||
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
              if (session.notice != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: ShapeDecoration(
                    color: RiderColors.rose,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(RiderRadii.control),
                    ),
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      session.notice!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: RiderColors.accentText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (session.error != null) ...[
                Text(
                  session.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                    key: const ValueKey('sign-in-button'),
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      minimumSize: const Size(0, 56),
                    ),
                    onPressed: session.busy ? null : _signIn,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    iconAlignment: IconAlignment.end,
                    label: Text(session.busy ? 'Signing in…' : 'Sign in'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: ShapeDecoration(
                  color: RiderColors.controlFill,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(RiderRadii.control),
                    side: const BorderSide(color: Colors.white, width: 1.4),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'New to BagooPH Rider?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: RiderColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RiderPressFeedback(
                      child: TextButton(
                        key: const ValueKey('open-register'),
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/register'),
                        child: const Text('Apply as a rider'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
