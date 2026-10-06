import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _step = 0;
  String _vehicle = 'Motorcycle';
  DateTime? _birthday;
  final _scroll = ScrollController();
  final _documentNames = <String, String?>{};
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
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

  Future<void> _chooseBirthday() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final latest = DateTime(now.year - 18, now.month, now.day);
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: latest,
      initialDate: _birthday ?? latest,
      helpText: 'Choose your birthday',
    );
    if (result != null && mounted) setState(() => _birthday = result);
  }

  void _submitPreview() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    showAuthPreviewMessage(
      context,
      title: 'Registration preview',
      message:
          'This is a preview of your rider application. '
          'No account is created and no information or documents are submitted.',
    );
  }

  void _backToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back to sign in',
                  onPressed: _backToLogin,
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
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
            const SizedBox(height: 20),
            _StepNavigation(step: _step, onSelect: _setStep),
            const SizedBox(height: 28),
            Text(
              headings[_step],
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              captions[_step],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            if (_step == 0) ..._riderFields(),
            if (_step == 1) ..._vehicleFields(),
            if (_step == 2) ..._documentFields(),
            const SizedBox(height: 30),
            if (_step > 0) ...[
              OutlinedButton(
                key: const ValueKey('registration-back-step'),
                onPressed: () => _setStep(_step - 1),
                child: const Text('Back'),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton(
              key: const ValueKey('registration-next'),
              onPressed: _step < 2 ? () => _setStep(_step + 1) : _submitPreview,
              child: Text(_step == 2 ? 'Submit application' : 'Continue'),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  key: const ValueKey('register-sign-in-link'),
                  onPressed: _backToLogin,
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _riderFields() {
    const gap = SizedBox(height: 20);
    return [
      AuthField(
        label: 'Full name',
        controller: _name,
        hint: 'Your full name',
        icon: Icons.person_outline_rounded,
        autofillHints: const [AutofillHints.name],
      ),
      gap,
      AuthField(
        label: 'Email address',
        controller: _email,
        hint: 'you@example.com',
        icon: Icons.mail_outline_rounded,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
      ),
      gap,
      AuthField(
        label: 'Mobile number',
        controller: _phone,
        hint: '09XXXXXXXXX',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumber],
      ),
      gap,
      const Text(
        'Birthday',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: RiderColors.ink,
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        key: const ValueKey('birthday-picker'),
        onPressed: _chooseBirthday,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: RiderColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _birthday == null
                    ? 'Choose your birthday'
                    : '${_birthday!.day.toString().padLeft(2, '0')} / '
                          '${_birthday!.month.toString().padLeft(2, '0')} / '
                          '${_birthday!.year}',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Rider applicants must be 18 or older.',
        style: TextStyle(fontSize: 12, color: RiderColors.muted),
      ),
      gap,
      AuthField(
        label: 'Street address',
        controller: _address,
        hint: 'House number, street or subdivision',
        icon: Icons.home_outlined,
        autofillHints: const [AutofillHints.streetAddressLine1],
      ),
      gap,
      AuthField(
        label: 'City or municipality',
        controller: _city,
        hint: 'Your operating city',
        icon: Icons.location_city_outlined,
        autofillHints: const [AutofillHints.addressCity],
      ),
      gap,
      AuthField(
        label: 'Barangay',
        controller: _barangay,
        hint: 'Your barangay',
        icon: Icons.location_on_outlined,
        textInputAction: TextInputAction.done,
      ),
    ];
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
          final width = singleColumn
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;
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
                  width: width,
                  child: Semantics(
                    button: true,
                    selected: _vehicle == vehicle.$1,
                    child: InkWell(
                      onTap: () => setState(() => _vehicle = vehicle.$1),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 96),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _vehicle == vehicle.$1
                              ? RiderColors.rose
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _vehicle == vehicle.$1
                                ? RiderColors.accentText
                                : RiderColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      AuthField(
        label: 'Plate or registration number',
        controller: _plate,
        hint: 'Enter the vehicle reference',
        icon: Icons.pin_outlined,
      ),
      const SizedBox(height: 20),
      AuthField(
        label: 'Driver’s license number',
        controller: _license,
        hint: 'Enter your license number',
        icon: Icons.badge_outlined,
        textInputAction: TextInputAction.done,
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: RiderColors.rose,
          borderRadius: BorderRadius.circular(8),
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
        selectedName: _documentNames['identity'],
        onChanged: (name) => setState(() => _documentNames['identity'] = name),
      ),
      const SizedBox(height: 12),
      _DocumentCard(
        key: const ValueKey('license-document'),
        title: 'Driver’s license',
        description: 'Your current driver’s license document.',
        selectedName: _documentNames['license'],
        onChanged: (name) => setState(() => _documentNames['license'] = name),
      ),
      const SizedBox(height: 12),
      _DocumentCard(
        key: const ValueKey('vehicle-document'),
        title: 'Vehicle registration',
        description: 'Your vehicle OR / CR document.',
        selectedName: _documentNames['vehicle'],
        onChanged: (name) => setState(() => _documentNames['vehicle'] = name),
      ),
      const SizedBox(height: 8),
      const Text(
        'Images or PDF, up to 5 MB each. Files stay local in this preview.',
        style: TextStyle(fontSize: 12, color: RiderColors.muted),
      ),
      const SizedBox(height: 26),
      AuthField(
        label: 'Create password',
        controller: _password,
        hint: 'Choose a strong password',
        password: true,
        icon: Icons.lock_outline_rounded,
        autofillHints: const [AutofillHints.newPassword],
        helper: 'Use 12–128 characters.',
        validator: (value) {
          if (value == null || value.length < 12 || value.length > 128) {
            return 'Use between 12 and 128 characters.';
          }
          return null;
        },
      ),
      const SizedBox(height: 20),
      AuthField(
        label: 'Confirm password',
        controller: _confirmation,
        hint: 'Enter your password again',
        password: true,
        icon: Icons.lock_outline_rounded,
        autofillHints: const [AutofillHints.newPassword],
        textInputAction: TextInputAction.done,
        validator: (value) => value == _password.text && value!.isNotEmpty
            ? null
            : 'Your passwords need to match.',
      ),
    ];
  }
}

class _StepNavigation extends StatelessWidget {
  const _StepNavigation({required this.step, required this.onSelect});
  final int step;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = MediaQuery.textScalerOf(context).scale(12) > 18;
        Widget item(int index, String label) {
          final active = index == step;
          return Semantics(
            button: true,
            selected: active,
            label: 'Step ${index + 1}: $label',
            child: InkWell(
              key: ValueKey('registration-step-$index'),
              onTap: () => onSelect(index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: active ? RiderColors.rose : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? RiderColors.accentText : RiderColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: active
                            ? RiderColors.accentText
                            : RiderColors.muted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? RiderColors.accentText
                            : RiderColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final index in [0, 1, 2]) ...[
                item(index, ['Your details', 'Vehicle', 'Documents'][index]),
                if (index != 2) const SizedBox(height: 8),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (final index in [0, 1, 2]) ...[
              Expanded(
                child: item(
                  index,
                  ['Your details', 'Vehicle', 'Documents'][index],
                ),
              ),
              if (index != 2) const SizedBox(width: 8),
            ],
          ],
        );
      },
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
  final ValueChanged<String?> onChanged;

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
        widget.onChanged(file.name);
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RiderColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RiderColors.rose,
                  borderRadius: BorderRadius.circular(8),
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
              OutlinedButton.icon(
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
              if (widget.selectedName != null)
                TextButton(
                  onPressed: () {
                    widget.onChanged(null);
                    setState(() => _error = null);
                  },
                  child: const Text('Remove'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
