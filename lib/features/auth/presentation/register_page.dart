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
            const SizedBox(height: 24),
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
    const gap = SizedBox(height: 24);
    return [
      _FormSection(
        title: 'About you',
        child: _FieldPair(
          first: AuthField(
            label: 'Full name',
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
            controller: _email,
            hint: 'Your email',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          second: AuthField(
            label: 'Mobile number',
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
              controller: _address,
              hint: 'House number, street or subdivision',
              autofillHints: const [AutofillHints.streetAddressLine1],
            ),
            const SizedBox(height: 16),
            _FieldPair(
              first: AuthField(
                label: 'City / municipality',
                controller: _city,
                hint: 'Your city',
                autofillHints: const [AutofillHints.addressCity],
              ),
              second: AuthField(
                label: 'Barangay',
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
        OutlinedButton(
          key: const ValueKey('birthday-picker'),
          onPressed: _chooseBirthday,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
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
      _FormSection(
        title: 'Vehicle details',
        child: _FieldPair(
          minimumWidth: 480,
          first: AuthField(
            label: 'Plate or registration number',
            controller: _plate,
            hint: 'Enter the vehicle reference',
          ),
          second: AuthField(
            label: 'Driver’s license number',
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
      const SizedBox(height: 24),
      _FormSection(
        title: 'Secure your account',
        child: _FieldPair(
          minimumWidth: 480,
          first: AuthField(
            label: 'Create password',
            controller: _password,
            hint: 'Choose a strong password',
            password: true,
            autofillHints: const [AutofillHints.newPassword],
            helper: 'Use 12–128 characters.',
            validator: (value) {
              if (value == null || value.length < 12 || value.length > 128) {
                return 'Use between 12 and 128 characters.';
              }
              return null;
            },
          ),
          second: AuthField(
            label: 'Confirm password',
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
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 16),
          Expanded(child: second),
        ],
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
            color: active ? RiderColors.accent : Colors.white,
            border: Border.all(
              color: active ? RiderColors.accent : RiderColors.border,
            ),
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
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => onSelect(index),
            excludeFromSemantics: true,
            borderRadius: BorderRadius.circular(8),
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
