import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

import '../../../../core/ui/rider_surfaces.dart';

class AuthField extends StatefulWidget {
  static const labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: RiderColors.ink,
  );
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
    this.enabled = true,
    this.onChanged,
    this.visibilityVersion = 0,
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
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final int visibilityVersion;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _visible = false;

  @override
  void didUpdateWidget(covariant AuthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.visibilityVersion != widget.visibilityVersion) {
      _visible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: AuthFieldLabels.heightOf(context),
          ),
          child: Text(widget.label, style: AuthField.labelStyle),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: widget.label,
          child: TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
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
                  ? RiderPressFeedback(
                      child: IconButton(
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

/// Paired fields align their inputs even when one persistent label wraps.
class AuthFieldLabels extends InheritedWidget {
  const AuthFieldLabels({
    super.key,
    required this.height,
    required super.child,
  });
  final double height;
  static double heightOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthFieldLabels>()?.height ??
      0;
  @override
  bool updateShouldNotify(AuthFieldLabels oldWidget) =>
      height != oldWidget.height;
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
  showRiderDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Text(message),
      actions: [
        RiderPressFeedback(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to preview'),
          ),
        ),
      ],
    ),
  );
}
