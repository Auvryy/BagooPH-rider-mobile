import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_shell.dart';
import 'auth_controller.dart';
import 'email_verification_dialog.dart';

import '../../../core/ui/rider_surfaces.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  int _step = 0;
  String _vehicle = 'Motorcycle';
  DateTime? _birthday;
  final _scroll = ScrollController();
  final _documents = <String, XFile>{};
  String? _localError;
  DateTime? _adultMaximum;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _province = TextEditingController();
  final _city = TextEditingController();
  final _barangay = TextEditingController();
  final _plate = TextEditingController();
  final _license = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    for (final field in [
      _name,
      _email,
      _phone,
      _address,
      _province,
      _city,
      _barangay,
      _plate,
      _license,
      _password,
      _confirmation,
    ]) {
      field.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _setStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final options = await ref
            .read(authRepositoryProvider)
            .registrationOptions();
        final limits = options['birth_date_limits'];
        if (mounted && limits is Map && limits['adult_maximum'] is String) {
          setState(
            () => _adultMaximum = DateTime.parse(limits['adult_maximum']),
          );
        }
      } catch (_) {
        /* Submission still requires authoritative server validation. */
      }
    });
  }

  void _next() {
    if (!_form.currentState!.validate()) return;
    if (_step == 0 && _birthday == null) {
      setState(
        () => _localError =
            'Choose your birthday. Rider applicants must be at least 18.',
      );
      return;
    }
    setState(() => _localError = null);
    _setStep(_step + 1);
  }

  Future<void> _chooseBirthday() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final latest = _adultMaximum ?? DateTime(now.year - 18, now.month, now.day);
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(1),
      lastDate: latest,
      initialDate: _birthday ?? latest,
      helpText: 'Choose your birthday',
    );
    if (result != null && mounted) setState(() => _birthday = result);
  }

  Future<void> _submitApplication() async {
    setState(() => _localError = null);
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_birthday == null ||
        [
          _name,
          _email,
          _phone,
          _address,
          _city,
        ].any((field) => field.text.trim().isEmpty)) {
      setState(() {
        _localError =
            'Complete your rider and contact details before applying.';
        _step = 0;
      });
      return;
    }
    if (_plate.text.trim().isEmpty || _license.text.trim().isEmpty) {
      setState(() {
        _localError = 'Enter your plate and driver’s license references.';
        _step = 1;
      });
      return;
    }
    if (_documents.length != 3) {
      setState(
        () => _localError = 'Choose your ID, driver’s license and vehicle registration documents.',
      );
      return;
    }
    final verification = await showRiderDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmailVerificationDialog(email: _email.text.trim()),
    );
    if (verification == null || !mounted) return;
    final birthday = _birthday!;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .register(
          {
            'name': _name.text,
            'email': _email.text,
            'phone': _phone.text,
            'birthday':
                '${birthday.year}-${birthday.month.toString().padLeft(2, '0')}-${birthday.day.toString().padLeft(2, '0')}',
            'address': _address.text,
            'province': _province.text,
            'city': _city.text,
            'barangay': _barangay.text,
            'vehicle_type': _vehicle,
            'plate_number': _plate.text,
            'license_number': _license.text,
            'password': _password.text,
            'password_confirmation': _confirmation.text,
            'otp_token': verification,
          },
          {
            'id_document': _documents['identity']!,
            'driver_license': _documents['license']!,
            'or_cr_document': _documents['vehicle']!,
          },
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final errors = ref.read(authControllerProvider).fields.keys;
      if (errors.any(
        [
          'name',
          'email',
          'phone',
          'birthday',
          'address',
          'city',
          'barangay',
        ].contains,
      )) {
        _setStep(0);
      } else if (errors.any(
        ['vehicle_type', 'plate_number', 'license_number'].contains,
      )) {
        _setStep(1);
      }
    }
  }

  void _setDocument(String key, XFile? file) => setState(() {
    if (file == null) {
      _documents.remove(key);
    } else {
      _documents[key] = file;
    }
  });

  void _backToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider);
    final headings = [
      'Let’s get to know you.',
      'Your delivery vehicle.',
      'A few final details.',
    ];
    final captions = [
      'Start with your rider and contact information.',
      'Add the vehicle you’ll use for your rider work.',
      'Prepare your documents and choose a password.',
    ];
    return AuthShell(
      registering: true,
      scrollController: _scroll,
      child: Form(
        key: _form,
        onChanged: () {
          if (_localError != null) setState(() => _localError = null);
          ref.read(authControllerProvider.notifier).clearError();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RiderPressFeedback(
                  child: IconButton(
                    tooltip: 'Back to sign in',
                    onPressed: _backToLogin,
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Rider application',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: RiderColors.muted,
                    ),
                  ),
                ),
                Text(
                  '${_step + 1} / 3',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: RiderColors.accentText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StepNavigation(step: _step, onSelect: _setStep),
            const SizedBox(height: 24),
            Text(
              headings[_step],
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              captions[_step],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (_step == 0) ..._riderFields(),
            if (_step == 1) ..._vehicleFields(),
            if (_step == 2) ..._documentFields(),
            if (_localError != null || session.error != null) ...[
              const SizedBox(height: 16),
              Text(
                _localError ?? session.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            if (_step > 0) ...[
              RiderPressFeedback(
                child: OutlinedButton(
                  key: const ValueKey('registration-back-step'),
                  onPressed: () => _setStep(_step - 1),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            RiderPressFeedback(
              child: FilledButton(
                key: const ValueKey('registration-next'),
                onPressed: session.busy
                    ? null
                    : _step < 2
                    ? _next
                    : _submitApplication,
                child: Text(
                  session.busy
                      ? 'Submitting…'
                      : _step == 2
                      ? 'Submit application'
                      : 'Continue',
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Already have an account?'),
                RiderPressFeedback(
                  child: TextButton(
                    key: const ValueKey('register-sign-in-link'),
                    onPressed: _backToLogin,
                    child: const Text('Sign in'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _riderFields() {
    const gap = SizedBox(height: 24);
    return [
      _FormSection(
        title: 'About you',
        child: _FieldPair(
          first: AuthField(
            label: 'Full name',
            validator: (value) => requiredText(value, 'full name'),
            serverError: ref.watch(authControllerProvider).fields['name'],
            controller: _name,
            hint: 'Your full name',
            autofillHints: const [AutofillHints.name],
          ),
          second: _birthdayField(),
        ),
      ),
      gap,
      _FormSection(
        title: 'Contact details',
        child: _FieldPair(
          first: AuthField(
            label: 'Email address',
            validator: (value) =>
                value != null &&
                    RegExp(r'^\S+@\S+\.\S+$').hasMatch(value.trim())
                ? null
                : 'Enter a valid email address.',
            serverError: ref.watch(authControllerProvider).fields['email'],
            controller: _email,
            hint: 'Your email',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          second: AuthField(
            label: 'Mobile number',
            validator: (value) => requiredText(value, 'mobile number'),
            serverError: ref.watch(authControllerProvider).fields['phone'],
            controller: _phone,
            hint: '09XXXXXXXXX',
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
        ),
      ),
      gap,
      _FormSection(
        title: 'Your address',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthField(
              label: 'Street address',
              validator: (value) => requiredText(value, 'street address'),
              serverError: ref.watch(authControllerProvider).fields['address'],
              controller: _address,
              hint: 'House number, street or subdivision',
              autofillHints: const [AutofillHints.streetAddressLine1],
            ),
            const SizedBox(height: 16),
            AuthField(
              label: 'Province',
              controller: _province,
              hint: 'Your province',
              serverError: ref.watch(authControllerProvider).fields['province'],
            ),
            const SizedBox(height: 16),
            _FieldPair(
              first: AuthField(
                label: 'City / municipality',
                validator: (value) =>
                    requiredText(value, 'city or municipality'),
                serverError: ref.watch(authControllerProvider).fields['city'],
                controller: _city,
                hint: 'Your city',
                autofillHints: const [AutofillHints.addressCity],
              ),
              second: AuthField(
                label: 'Barangay',
                serverError: ref
                    .watch(authControllerProvider)
                    .fields['barangay'],
                controller: _barangay,
                hint: 'Your barangay',
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _birthdayField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Birthday',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: RiderColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        RiderPressFeedback(
          child: OutlinedButton(
            key: const ValueKey('birthday-picker'),
            onPressed: _chooseBirthday,
            style: OutlinedButton.styleFrom(
              backgroundColor: RiderColors.controlFill,
              alignment: Alignment.centerLeft,
              minimumSize: const Size(0, 56),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: RiderColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _birthday == null
                        ? 'Select date'
                        : '${_birthday!.day.toString().padLeft(2, '0')}/'
                              '${_birthday!.month.toString().padLeft(2, '0')}/'
                              '${_birthday!.year}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '18 years or older.',
          style: TextStyle(fontSize: 12, color: RiderColors.muted),
        ),
      ],
    );
  }

  List<Widget> _vehicleFields() {
    return [
      const Text(
        'Vehicle type',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: RiderColors.ink,
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final singleColumn =
              constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(14) > 20;
          final columns = singleColumn
              ? 1
              : constraints.maxWidth >= 520
              ? 3
              : 2;
          final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final vehicle in [
                ('Motorcycle', Icons.two_wheeler_outlined),
                ('Scooter', Icons.electric_moped_outlined),
                ('Sedan / Van', Icons.directions_car_outlined),
              ])
                SizedBox(
                  width: columns == 2 && vehicle.$1 == 'Sedan / Van'
                      ? constraints.maxWidth
                      : width,
                  child: Semantics(
                    button: true,
                    selected: _vehicle == vehicle.$1,
                    child: RiderPressFeedback(
                      child: InkWell(
                        onTap: () => setState(() => _vehicle = vehicle.$1),
                        borderRadius: BorderRadius.circular(RiderRadii.control),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 96),
                          padding: const EdgeInsets.all(16),
                          decoration: ShapeDecoration(
                            color: _vehicle == vehicle.$1
                                ? RiderColors.rose
                                : RiderColors.controlFill,
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(
                                RiderRadii.control,
                              ),
                              side: _vehicle == vehicle.$1
                                  ? const BorderSide(
                                      color: RiderColors.accentText,
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    vehicle.$2,
                                    size: 26,
                                    color: _vehicle == vehicle.$1
                                        ? RiderColors.accentText
                                        : RiderColors.muted,
                                  ),
                                  if (_vehicle == vehicle.$1)
                                    const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 20,
                                      color: RiderColors.accentText,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                vehicle.$1,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _vehicle == vehicle.$1
                                      ? RiderColors.accentText
                                      : RiderColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      _FormSection(
        title: 'Vehicle details',
        child: _FieldPair(
          minimumWidth: 480,
          first: AuthField(
            label: 'Plate or registration number',
            validator: (value) =>
                requiredText(value, 'plate or registration number'),
            serverError: ref
                .watch(authControllerProvider)
                .fields['plate_number'],
            controller: _plate,
            hint: 'Enter the vehicle reference',
          ),
          second: AuthField(
            label: 'Driver’s license number',
            validator: (value) =>
                requiredText(value, 'driver’s license number'),
            serverError: ref
                .watch(authControllerProvider)
                .fields['license_number'],
            controller: _license,
            hint: 'Enter your license number',
            textInputAction: TextInputAction.done,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: RiderColors.controlFill,
          borderRadius: BorderRadius.circular(RiderRadii.control),
        ),
        child: const Text(
          'Your company, hub and work assignment are managed separately '
          'by the logistics team.',
          style: TextStyle(fontSize: 13, color: RiderColors.muted),
        ),
      ),
    ];
  }

  List<Widget> _documentFields() {
    return [
      _DocumentCard(
        key: const ValueKey('identity-document'),
        title: 'Government ID',
        description: 'A clear copy of your valid identification.',
        selectedName: _documents['identity']?.name,
        onChanged: (file) => _setDocument('identity', file),
      ),
      const SizedBox(height: 12),
      _DocumentCard(
        key: const ValueKey('license-document'),
        title: 'Driver’s license',
        description: 'Your current driver’s license document.',
        selectedName: _documents['license']?.name,
        onChanged: (file) => _setDocument('license', file),
      ),
      const SizedBox(height: 12),
      _DocumentCard(
        key: const ValueKey('vehicle-document'),
        title: 'Vehicle registration',
        description: 'Your vehicle OR / CR document.',
        selectedName: _documents['vehicle']?.name,
        onChanged: (file) => _setDocument('vehicle', file),
      ),
      const SizedBox(height: 8),
      const Text(
        'Images or PDF, up to 5 MB each. Documents are submitted privately for review.',
        style: TextStyle(fontSize: 12, color: RiderColors.muted),
      ),
      const SizedBox(height: 24),
      _FormSection(
        title: 'Secure your account',
        child: _FieldPair(
          minimumWidth: 480,
          first: AuthField(
            label: 'Create password',
            serverError: ref.watch(authControllerProvider).fields['password'],
            controller: _password,
            hint: 'Choose a strong password',
            password: true,
            autofillHints: const [AutofillHints.newPassword],
            helper: 'Use at least 8 characters.',
            validator: (value) {
              if (value == null || value.length < 8) {
                return 'Use at least 8 characters.';
              }
              return null;
            },
          ),
          second: AuthField(
            label: 'Confirm password',
            serverError: ref
                .watch(authControllerProvider)
                .fields['password_confirmation'],
            controller: _confirmation,
            hint: 'Enter your password again',
            password: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            validator: (value) => value == _password.text && value!.isNotEmpty
                ? null
                : 'Your passwords need to match.',
          ),
        ),
      ),
    ];
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      child,
    ],
  );
}

class _FieldPair extends StatelessWidget {
  const _FieldPair({
    required this.first,
    required this.second,
    this.minimumWidth = 320,
  });
  final Widget first;
  final Widget second;
  final double minimumWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final paired =
          constraints.maxWidth >= minimumWidth &&
          MediaQuery.textScalerOf(context).scale(16) <= 20;
      if (!paired) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 16), second],
        );
      }
      final row = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 16),
          Expanded(child: second),
        ],
      );
      if (first is! AuthField || second is! AuthField) return row;
      double labelHeight(AuthField field) {
        final painter = TextPainter(
          text: TextSpan(
            text: field.label,
            style: DefaultTextStyle.of(context).style
                .merge(AuthField.labelStyle),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: (constraints.maxWidth - 16) / 2);
        final height = painter.height;
        painter.dispose();
        return height;
      }

      final heights = [
        labelHeight(first as AuthField),
        labelHeight(second as AuthField),
      ];
      return AuthFieldLabels(
        height: heights.reduce((a, b) => a > b ? a : b),
        child: row,
      );
    },
  );
}

class _StepNavigation extends StatelessWidget {
  const _StepNavigation({required this.step, required this.onSelect});
  final int step;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(12) > 18;
    const labels = ['Details', 'Vehicle', 'Documents'];
    Widget item(int index) {
      final active = index == step;
      final circle = Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? RiderColors.rose : Colors.transparent,
        ),
        child: Container(
          key: ValueKey('registration-step-circle-$index'),
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? RiderColors.accent : RiderColors.controlFill,
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : RiderColors.muted,
            ),
          ),
        ),
      );
      final label = Text(
        labels[index],
        textAlign: stacked ? TextAlign.start : TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? RiderColors.accentText : RiderColors.muted,
        ),
      );
      return Semantics(
        key: ValueKey('registration-step-$index'),
        button: true,
        selected: active,
        label:
            'Step ${index + 1}: ${index == 0 ? 'Your details' : labels[index]}',
        value: active ? 'Current step' : null,
        onTap: () => onSelect(index),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(RiderRadii.control),
          child: RiderPressFeedback(
            child: InkWell(
              onTap: () => onSelect(index),
              excludeFromSemantics: true,
              borderRadius: BorderRadius.circular(RiderRadii.control),
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: stacked
                      ? Row(
                          children: [
                            circle,
                            const SizedBox(width: 12),
                            Expanded(child: label),
                          ],
                        )
                      : Column(
                          children: [circle, const SizedBox(height: 8), label],
                        ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final index in [0, 1, 2]) item(index),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned(
            top: 27,
            left: constraints.maxWidth / 6 + 24,
            right: constraints.maxWidth / 6 + 24,
            child: const SizedBox(
              height: 2,
              child: ColoredBox(color: RiderColors.divider),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final index in [0, 1, 2]) Expanded(child: item(index)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatefulWidget {
  const _DocumentCard({
    super.key,
    required this.title,
    required this.description,
    required this.selectedName,
    required this.onChanged,
  });
  final String title;
  final String description;
  final String? selectedName;
  final ValueChanged<XFile?> onChanged;

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  String? _error;
  bool _choosing = false;

  Future<void> _choose() async {
    setState(() {
      _choosing = true;
      _error = null;
    });
    try {
      const group = XTypeGroup(
        label: 'Images and PDF',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'],
        uniformTypeIdentifiers: ['public.image', 'com.adobe.pdf'],
      );
      final file = await openFile(acceptedTypeGroups: [group]);
      if (file == null || !mounted) return;
      final size = await file.length();
      if (!mounted) return;
      if (size > 5 * 1024 * 1024) {
        setState(
          () =>
              _error = 'Choose a file up to 5 MB. The previous choice is kept.',
        );
      } else {
        widget.onChanged(file);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open file selection. Try again.');
      }
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RiderSurface(
      padding: const EdgeInsets.all(16),
      radius: RiderRadii.control,
      color: RiderColors.controlFill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RiderColors.rose,
                  borderRadius: BorderRadius.circular(RiderRadii.control),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 22,
                  color: RiderColors.accentText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.selectedName ?? widget.description,
            style: const TextStyle(fontSize: 13, color: RiderColors.muted),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFBE123C), fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RiderPressFeedback(
                child: OutlinedButton.icon(
                  onPressed: _choosing ? null : _choose,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    _choosing
                        ? 'Choosing…'
                        : widget.selectedName == null
                        ? 'Choose document'
                        : 'Replace document',
                  ),
                ),
              ),
              if (widget.selectedName != null)
                RiderPressFeedback(
                  child: TextButton(
                    onPressed: () {
                      widget.onChanged(null);
                      setState(() => _error = null);
                    },
                    child: const Text('Remove'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
