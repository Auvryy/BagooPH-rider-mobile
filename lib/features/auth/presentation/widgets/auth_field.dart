import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.password = false,
    this.keyboardType,
    this.autofillHints,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.helper,
    this.serverError,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final bool password;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? helper;
  final String? serverError;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _visible = false;

  @override
  void didUpdateWidget(covariant AuthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) _visible = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: RiderColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: widget.label,
          child: TextFormField(
            controller: widget.controller,
            style: const TextStyle(fontSize: 16, color: RiderColors.body),
            obscureText: widget.password && !_visible,
            enableSuggestions: !widget.password,
            autocorrect: !widget.password,
            keyboardType: widget.keyboardType,
            autofillHints: widget.autofillHints,
            validator: widget.validator,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.serverError,
              helperText: widget.helper,
              helperMaxLines: 3,
              prefixIcon: widget.icon == null
                  ? null
                  : Icon(widget.icon, size: 20),
              suffixIcon: widget.password
                  ? IconButton(
                      tooltip: _visible
                          ? 'Hide ${widget.label.toLowerCase()}'
                          : 'Show ${widget.label.toLowerCase()}',
                      onPressed: () => setState(() => _visible = !_visible),
                      icon: Icon(
                        _visible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

String? requiredText(String? value, String label) {
  if (value == null || value.trim().isEmpty) return 'Enter your $label.';
  return null;
}

void showAuthPreviewMessage(
  BuildContext context, {
  required String title,
  required String message,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to preview'),
        ),
      ],
    ),
  );
}
