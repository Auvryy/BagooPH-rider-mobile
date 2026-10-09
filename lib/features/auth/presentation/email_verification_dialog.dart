import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account.dart';
import 'auth_controller.dart';

import '../../../core/ui/rider_surfaces.dart';

class EmailVerificationDialog extends ConsumerStatefulWidget {
  const EmailVerificationDialog({super.key, required this.email});
  final String email;
  @override
  ConsumerState<EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState
    extends ConsumerState<EmailVerificationDialog> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  int _cooldown = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    Future.microtask(_send);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendCode(widget.email);
      if (!mounted) return;
      _cooldown = 60;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _cooldown == 0) {
          timer.cancel();
          return;
        }
        setState(() => _cooldown--);
      });
    } catch (error) {
      if (mounted) {
        _error = error is AccountFailure
            ? error.message
            : 'Could not send the email code. Try again.';
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) {
      setState(() => _error = 'Enter the six-digit code from your email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await ref
          .read(authRepositoryProvider)
          .verifyCode(widget.email, _code.text);
      if (mounted) Navigator.of(context).pop(token);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AccountFailure
              ? error.message
              : 'Could not verify this code. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Verify your email'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Enter the six-digit code sent to ${widget.email}.'),
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('email-code-input'),
          controller: _code,
          maxLength: 6,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: const InputDecoration(labelText: 'Verification code'),
          onSubmitted: (_) => _verify(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        RiderPressFeedback(
          child: TextButton(
            onPressed: _busy || _cooldown > 0 ? null : _send,
            child: Text(
              _cooldown > 0 ? 'Resend in $_cooldown seconds' : 'Resend code',
            ),
          ),
        ),
      ],
    ),
    actions: [
      RiderPressFeedback(
        child: TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
      RiderPressFeedback(
        child: FilledButton(
          key: const ValueKey('verify-email-button'),
          onPressed: _busy ? null : _verify,
          child: Text(_busy ? 'Please wait…' : 'Verify email'),
        ),
      ),
    ],
  );
}
