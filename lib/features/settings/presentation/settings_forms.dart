import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/account.dart';
import '../../auth/presentation/widgets/auth_field.dart';
import '../../workspace/presentation/workspace_widgets.dart';
import '../../../core/platform/rider_website.dart';
import '../data/settings_models.dart';
import 'settings_controller.dart';

enum SettingsFlow { contact, password, emails }

void openSettingsForm(
  BuildContext context,
  WidgetRef ref,
  RiderAccount account,
  bool preview,
  SettingsFlow flow,
) {
  final identity = SettingsIdentity(account.id, preview: preview);
  ref.read(settingsControllerProvider(identity)).clearFeedback();
  final container = ProviderScope.containerOf(context);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: AccountSettingsForm(identity: identity, flow: flow),
      ),
    ),
  );
}

class AccountSettingsForm extends ConsumerStatefulWidget {
  const AccountSettingsForm({
    super.key,
    required this.identity,
    required this.flow,
  });
  final SettingsIdentity identity;
  final SettingsFlow flow;
  @override
  ConsumerState<AccountSettingsForm> createState() =>
      _AccountSettingsFormState();
}

class _AccountSettingsFormState extends ConsumerState<AccountSettingsForm>
    with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  String? _revision, _initialPhone;
  Timer? _ticker;
  bool _discardApproved = false;
  bool _addingEmail = false, _confirmingEmail = false;
  int _visibilityVersion = 0;
  SettingsController get controller =>
      ref.read(settingsControllerProvider(widget.identity));
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _email.addListener(_changedEmail);
    if (widget.flow == SettingsFlow.emails) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _changedEmail() {
    final previous = controller.challengeEmail;
    controller.changedEmail(_email.text);
    if (previous != null && controller.challengeEmail == null) _code.clear();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _clearSecrets();
      if (mounted) setState(() {});
    }
  }

  void _clearSecrets() {
    _visibilityVersion++;
    _current.clear();
    _next.clear();
    _confirmation.clear();
    _code.clear();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _email.removeListener(_changedEmail);
    // Provider scope may already have changed during sign-out; do not read ref.
    for (final field in [
      _phone,
      _current,
      _next,
      _confirmation,
      _email,
      _code,
    ]) {
      field.clear();
      field.dispose();
    }
    super.dispose();
  }

  bool get dirty =>
      _phone.text != (_initialPhone ?? '') ||
      [
        _current,
        _next,
        _confirmation,
        _email,
        _code,
      ].any((c) => c.text.isNotEmpty);
  Future<void> _close() async {
    if (controller.busy) return;
    if (dirty && !_discardApproved) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard unsaved changes?'),
          content: const Text(
            'Your typed changes will be cleared. Saved account details stay as they are.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    controller.closeChallenge();
    setState(() => _discardApproved = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _saveContact() async {
    if (_form.currentState?.validate() != true) return;
    final saved = await controller.savePhone(
      _phone.text.isEmpty ? null : _phone.text,
      _revision!,
    );
    if (saved && mounted) {
      final data = controller.data!;
      setState(() {
        _phone.text = data.phone ?? '';
        _initialPhone = _phone.text;
        _revision = data.revision;
      });
    }
  }

  Future<void> _savePassword() async {
    if (_form.currentState?.validate() != true) return;
    final saved = await controller.changePassword(
      _current.text,
      _next.text,
      _confirmation.text,
    );
    if (!mounted) return;
    if (saved || controller.failure?.unconfirmed == true) _clearSecrets();
    if (saved && widget.identity.preview) {
      _discardApproved = true;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview only · no password was changed.'),
        ),
      );
    }
  }

  Future<void> _emailAction(String action, [ContactEmail? address]) async {
    _addingEmail = action == 'send' || action == 'confirm';
    _confirmingEmail = action == 'confirm';
    if (_current.text.isEmpty) {
      _form.currentState?.validate();
      return;
    }
    bool saved = false;
    if (action == 'send' || action == 'confirm') {
      if (_form.currentState?.validate() != true) return;
      if (action == 'send') {
        await controller.sendCode(_email.text, _current.text);
      } else {
        saved = await controller.confirmEmail(
          _email.text,
          _current.text,
          _code.text,
        );
      }
    } else if (action == 'prefer') {
      saved = await controller.preferEmail(address!.id, _current.text);
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove additional email?'),
          content: Text(
            '${address!.email} will no longer be used for contact or password recovery.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove email'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      saved = await controller.removeEmail(address!.id, _current.text);
    }
    if (saved && mounted) {
      _clearSecrets();
      _email.clear();
      setState(() {});
    }
  }

  Widget _field(
    String label,
    TextEditingController value, {
    bool secret = false,
    String? errorKey,
    String? Function(String?)? validator,
    Iterable<String>? hints,
    TextInputType? keyboard,
    ValueChanged<String>? changed,
  }) => AuthField(
    key: ValueKey('settings-$label'),
    label: label,
    controller: value,
    password: secret,
    visibilityVersion: _visibilityVersion,
    enabled: !controller.busy,
    serverError: controller.failure?.fields[errorKey],
    validator: validator,
    autofillHints: hints,
    keyboardType: keyboard,
    onChanged: changed,
  );
  String? _requiredPassword(String? value) =>
      value == null || value.isEmpty ? 'Enter your current password.' : null;
  String? _emailValid(String? value) {
    if (!_addingEmail) return null;
    final email = value?.trim() ?? '';
    if (email.isEmpty ||
        !email.contains('@') ||
        RegExp(r'\s').hasMatch(email)) {
      return 'Enter a valid additional email address.';
    }
    if (email.length > 255) return 'Use an email address up to 255 characters.';
    return null;
  }

  Widget _value(String title, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(text),
      ],
    ),
  );
  List<Widget> _contact(SettingsSnapshot data) => [
    _value('Reviewed name', data.name),
    _value('Original sign-in email', data.email),
    _value('Saved mobile number', data.phone ?? 'Not provided'),
    const Text(
      'Your approved identity stays with your account. Use the identity review process for a name or identity correction.',
    ),
    if (!widget.identity.preview) ...[
      const SizedBox(height: 12),
      const WebsiteButton(
        page: RiderWebsitePage.settings,
        label: 'Request identity correction on the website',
      ),
    ],
    const SizedBox(height: 24),
    _field(
      'Mobile number',
      _phone,
      errorKey: 'phone',
      hints: [AutofillHints.telephoneNumber],
      keyboard: TextInputType.phone,
      changed: (_) => setState(() {}),
    ),
    const SizedBox(height: 8),
    const Text(
      'Use your Philippine mobile number, or leave it empty to remove it.',
    ),
    const SizedBox(height: 24),
    FilledButton(
      key: const ValueKey('save-contact'),
      onPressed: controller.editable && data.canUpdateContact
          ? _saveContact
          : null,
      child: Text(controller.busy ? 'Saving…' : 'Save contact details'),
    ),
    if (!data.canUpdateContact) ...[
      const SizedBox(height: 12),
      const Text(
        'Contact editing is not currently available for this account.',
      ),
    ],
  ];
  List<Widget> _password(SettingsSnapshot data) => [
    _value('Original sign-in email', data.email),
    _value(
      'Email verification',
      data.emailVerified ? 'Verified' : 'Verification pending',
    ),
    const Text(
      'Use a unique password between 12 and 128 characters. A confirmed change signs you out; use the new password to sign in again.',
    ),
    const SizedBox(height: 24),
    if (!data.canChangePassword)
      const Text(
        'Password changes require verified email and current account access.',
      )
    else ...[
      _field(
        'Current password',
        _current,
        secret: true,
        errorKey: 'current_password',
        validator: _requiredPassword,
        hints: [AutofillHints.password],
      ),
      const SizedBox(height: 20),
      _field(
        'New password',
        _next,
        secret: true,
        errorKey: 'password',
        hints: [AutofillHints.newPassword],
        validator: (value) {
          final length = value?.runes.length ?? 0;
          return length < 12 || length > 128
              ? 'Use between 12 and 128 characters.'
              : null;
        },
      ),
      const SizedBox(height: 20),
      _field(
        'Confirm new password',
        _confirmation,
        secret: true,
        errorKey: 'password_confirmation',
        hints: [AutofillHints.newPassword],
        validator: (value) =>
            value != _next.text ? 'The passwords must match.' : null,
      ),
      const SizedBox(height: 24),
      FilledButton(
        key: const ValueKey('save-password'),
        onPressed: controller.editable ? _savePassword : null,
        child: Text(controller.busy ? 'Updating…' : 'Update password'),
      ),
    ],
    if (!widget.identity.preview) ...[
      const SizedBox(height: 20),
      const WebsiteButton(
        page: RiderWebsitePage.recovery,
        label: 'Forgot password',
      ),
    ],
  ];
  List<Widget> _emails(SettingsSnapshot data) {
    final sent = controller.challengeEmail == _email.text.trim().toLowerCase();
    final capacity = data.emails.where((e) => !e.original).length < 5;
    return [
      const Text(
        'Keep your original sign-in email. Verify up to five additional addresses for contact and password recovery.',
      ),
      const SizedBox(height: 20),
      if (kDebugMode && widget.identity.preview) ...[
        const Text(
          'Sample verification code: 123456. No email is sent in this preview.',
        ),
        const SizedBox(height: 16),
      ],
      for (final address in data.emails) ...[
        WorkspacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address.email,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${address.original ? 'Original sign-in email' : 'Additional email'} · ${address.verified ? 'Verified' : 'Verification pending'}${address.preferred ? ' · Contact email' : ''}',
              ),
              if (data.canManageEmails)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (address.verified && !address.preferred)
                      TextButton(
                        onPressed: controller.editable
                            ? () => _emailAction('prefer', address)
                            : null,
                        child: const Text('Use for contact'),
                      ),
                    if (!address.original)
                      TextButton(
                        onPressed: controller.editable
                            ? () => _emailAction('remove', address)
                            : null,
                        child: const Text('Remove'),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (data.canManageEmails) ...[
        const SizedBox(height: 8),
        _field(
          'Current password',
          _current,
          secret: true,
          errorKey: 'current_password',
          validator: _requiredPassword,
          hints: [AutofillHints.password],
        ),
        const SizedBox(height: 8),
        const Text(
          'Confirm your password to add, remove or choose a contact email.',
        ),
        if (capacity) ...[
          const SizedBox(height: 20),
          _field(
            'Additional email',
            _email,
            errorKey: 'email',
            validator: _emailValid,
            hints: [AutofillHints.email],
            keyboard: TextInputType.emailAddress,
          ),
          if (sent) ...[
            const SizedBox(height: 20),
            _field(
              'Verification code',
              _code,
              errorKey: 'code',
              hints: [AutofillHints.oneTimeCode],
              keyboard: TextInputType.number,
              validator: (value) =>
                  !_confirmingEmail ||
                      RegExp(r'^[0-9]{6}$').hasMatch(value ?? '')
                  ? null
                  : 'Enter the six-digit code.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Use the code from this additional email inbox. Request a new code if it expires.',
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('email-submit'),
            onPressed:
                controller.editable && (sent || controller.cooldownSeconds == 0)
                ? () => _emailAction(sent ? 'confirm' : 'send')
                : null,
            child: Text(
              controller.busy
                  ? 'Updating…'
                  : sent
                  ? 'Verify and add email'
                  : controller.cooldownSeconds > 0
                  ? 'Send code in ${controller.cooldownSeconds}s'
                  : 'Send verification code',
            ),
          ),
          if (sent) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: controller.editable && controller.cooldownSeconds == 0
                  ? () => _emailAction('send')
                  : null,
              child: Text(
                controller.cooldownSeconds > 0
                    ? 'Resend in ${controller.cooldownSeconds}s'
                    : 'Resend code',
              ),
            ),
          ],
        ] else ...[
          const SizedBox(height: 16),
          const Text(
            'You already have five additional addresses. Remove one before adding another.',
          ),
        ],
      ] else
        const Text(
          'Email management is not currently available for this account.',
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider(widget.identity));
    final data = state.data;
    if (_revision == null && data != null) {
      _phone.text = data.phone ?? '';
      _initialPhone = _phone.text;
      _revision = data.revision;
    }
    final title = switch (widget.flow) {
      SettingsFlow.contact => 'Contact information',
      SettingsFlow.password => 'Change password',
      SettingsFlow.emails => 'Email and recovery',
    };
    return PopScope(
      canPop: _discardApproved || (!dirty && !state.busy),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            tooltip: 'Back',
            onPressed: state.busy ? null : _close,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.identity.preview) ...[
                        const WorkspaceBadge(
                          'Preview · sample changes only',
                          accent: true,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (!state.available) ...[
                        const Text(
                          'Account updates are not connected in the app yet. Use the Rider website.',
                        ),
                        const SizedBox(height: 20),
                        if (!widget.identity.preview)
                          const WebsiteButton(
                            page: RiderWebsitePage.settings,
                            label: 'Open website settings',
                          ),
                      ] else if (data == null) ...[
                        if (state.loading)
                          const Center(child: CircularProgressIndicator()),
                        if (!state.loading)
                          OutlinedButton(
                            onPressed: state.load,
                            child: const Text('Retry account settings'),
                          ),
                      ] else
                        ...switch (widget.flow) {
                          SettingsFlow.contact => _contact(data),
                          SettingsFlow.password => _password(data),
                          SettingsFlow.emails => _emails(data),
                        },
                      if (state.failure != null) ...[
                        const SizedBox(height: 20),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            state.failure!.message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      if (state.needsRefresh) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Refresh saved details before trying again. The previous update was not confirmed.',
                        ),
                        OutlinedButton(
                          onPressed: state.busy
                              ? null
                              : () async {
                                  final loaded = await state.load();
                                  if (loaded && mounted) {
                                    setState(() {
                                      _revision = state.data!.revision;
                                      _initialPhone = state.data!.phone ?? '';
                                    });
                                  }
                                },
                          child: const Text('Refresh saved details'),
                        ),
                      ],
                      if (state.result != null) ...[
                        const SizedBox(height: 20),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            widget.identity.preview
                                ? 'Preview only · ${state.result}'
                                : state.result!,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
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
