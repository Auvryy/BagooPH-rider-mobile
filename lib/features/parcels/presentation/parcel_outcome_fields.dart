import 'package:flutter/material.dart';

import '../../../core/commands/parcel_proof.dart';
import '../../../core/commands/parcel_validation.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/ui/private_image.dart';
import '../../home/data/operations_models.dart';
import '../../workspace/presentation/workspace_widgets.dart';
import '../data/parcel_photo_service.dart';

class ParcelOutcomeFields extends StatefulWidget {
  const ParcelOutcomeFields({
    super.key,
    required this.task,
    required this.action,
    required this.enabled,
    required this.privateVisible,
    required this.photos,
    required this.onChanged,
    required this.onEdited,
    required this.revalidate,
    this.errors = const {},
  });
  final OperationTask task;
  final ParcelAction action;
  final bool enabled, privateVisible;
  final ParcelPhotoService? photos;
  final VoidCallback onChanged;
  final void Function(String field) onEdited;
  final Future<void> Function() revalidate;
  final Map<String, String> errors;
  @override
  State<ParcelOutcomeFields> createState() => ParcelOutcomeFieldsState();
}

class ParcelOutcomeFieldsState extends State<ParcelOutcomeFields> {
  final recipient = TextEditingController(), received = TextEditingController();
  final change = TextEditingController(), location = TextEditingController();
  final proofField = GlobalKey<FormFieldState<ParcelProof>>();
  String? relationship, reason, notice;
  bool cashConfirmed = false, choosing = false, validImage = true;
  ParcelProof? get proof => proofField.currentState?.value;
  bool get ready =>
      proof != null && validImage && !choosing && widget.photos?.busy != true;

  @override
  void initState() {
    super.initState();
    widget.photos?.addListener(_photoChanged);
  }

  void _photoChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(ParcelOutcomeFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos != widget.photos) {
      oldWidget.photos?.removeListener(_photoChanged);
      widget.photos?.addListener(_photoChanged);
    }
    if (oldWidget.task.version != widget.task.version) {
      cashConfirmed = false;
      proofField.currentState?.didChange(null);
      notice = 'This parcel changed. Review the current amount and capture or select proof for this review.';
    }
  }

  @override
  void dispose() {
    widget.photos?.removeListener(_photoChanged);
    recipient.dispose();
    received.dispose();
    change.dispose();
    location.dispose();
    super.dispose();
  }

  void _edit(String field) {
    widget.onEdited(field);
    widget.onChanged();
  }

  void _useProof(ParcelProof file) {
    validImage = true;
    proofField.currentState?.didChange(file);
    notice = null;
    _edit('proof_image_file');
    setState(() {});
  }

  Future<void> _choose(bool camera) async {
    final photos = widget.photos;
    if (!widget.enabled || choosing || photos == null || photos.busy) return;
    final reviewed = widget.task;
    setState(() {
      choosing = true;
      notice = null;
    });
    widget.onChanged();
    try {
      final image = await photos.choose(
        taskId: reviewed.id,
        version: reviewed.version,
        action: widget.action,
        camera: camera,
      );
      if (!mounted) return;
      await widget.revalidate();
      if (!mounted) return;
      if (widget.task.version != reviewed.version || !widget.enabled) {
        setState(
          () => notice = 'Check the current parcel before using a photo. Nothing was submitted.',
        );
      } else if (image != null) {
        _useProof(image);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => notice = error is AccountFailure ? error.message : 'Could not select that image. Check photo permission or choose another original image.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => choosing = false);
        widget.onChanged();
      }
    }
  }

  Map<String, dynamic> fields() => widget.action == ParcelAction.deliver
      ? {
          'recipient_name': parcelText(
            recipient.text,
            'recipient_name',
            min: 2,
            max: 255,
          ),
          'recipient_relationship': relationship,
          'cash_received': received.text.trim(),
          'change_given': change.text.trim(),
          'cash_confirmed': cashConfirmed,
        }
      : {
          'reason': reason,
          'location_name': parcelText(location.text, 'location_name', max: 255),
        };

  String? _plain(String? value, String field, {int min = 1, int max = 255}) {
    try {
      parcelText(value ?? '', field, min: min, max: max);
      return null;
    } on AccountFailure catch (error) {
      return error.fields[field];
    }
  }

  String? _money(String? value, String field) {
    try {
      pesoInputCents((value ?? '').trim(), field: field);
      return null;
    } on AccountFailure catch (error) {
      return error.fields[field];
    }
  }

  String? get _cashDifference {
    if (received.text.trim().isEmpty || change.text.trim().isEmpty) return null;
    try {
      final net =
          pesoInputCents(received.text.trim()) -
          pesoInputCents(change.text.trim(), field: 'change_given');
      if (net.isNegative) return 'Change cannot exceed the cash received.';
      return 'Cash retained for this handoff: ${exactPesos(net)}';
    } on AccountFailure {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isDelivery = widget.action == ParcelAction.deliver;
    final restored = widget.photos?.forTask(
      task.id,
      task.version,
      widget.action,
    );
    final busy = choosing || widget.photos?.busy == true;
    final enabled = widget.enabled && !busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          '2. Record the handoff evidence',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        FormField<ParcelProof>(
          key: proofField,
          validator: (file) => file == null || !validImage
              ? 'Choose a valid original proof image.'
              : null,
          builder: (field) => WorkspacePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isDelivery
                      ? 'Proof of recipient handoff'
                      : 'Proof of the failed attempt',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use an actual JPG, PNG or WebP image, up to 5 MB. The original bytes are kept for any uncertain request.',
                ),
                if (field.value != null) ...[
                  const SizedBox(height: 16),
                  if (widget.privateVisible)
                    PrivateImage(
                      key: ValueKey('parcel-proof-${field.value!.digest}'),
                      bytes: field.value!.bytes,
                      label: 'Selected private parcel proof image',
                      onInvalid: () {
                        if (mounted) {
                          setState(() => validImage = false);
                          widget.onChanged();
                        }
                      },
                    )
                  else
                    const Text('Return to Rider to view this private image.'),
                  const SizedBox(height: 8),
                  Text(
                    'Original ${field.value!.extension.toUpperCase()} · ${(field.value!.bytes.length + 1023) ~/ 1024} KB',
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.photos?.picker.supportsCamera == true)
                      OutlinedButton.icon(
                        key: const ValueKey('parcel-photo-camera'),
                        onPressed: enabled ? () => _choose(true) : null,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Take proof photo'),
                      ),
                    OutlinedButton.icon(
                      key: const ValueKey('parcel-photo-choose'),
                      onPressed: enabled && widget.photos != null
                          ? () => _choose(false)
                          : null,
                      icon: const Icon(Icons.photo_outlined),
                      label: Text(
                        field.value == null
                            ? 'Choose proof image'
                            : 'Replace image',
                      ),
                    ),
                    if (restored != null && field.value == null)
                      TextButton(
                        key: const ValueKey('parcel-photo-restore'),
                        onPressed: enabled ? () => _useProof(restored) : null,
                        child: const Text('Restore unfinished photo'),
                      ),
                  ],
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(
                      semanticsLabel: 'Preparing original proof image',
                    ),
                  ),
                if (notice != null || widget.photos?.notice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(notice ?? widget.photos!.notice!),
                    ),
                  ),
                if (field.errorText != null ||
                    widget.errors['proof_image_file'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.errors['proof_image_file'] ?? field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (isDelivery) ...[
          TextFormField(
            key: const ValueKey('parcel-recipient'),
            controller: recipient,
            enabled: enabled,
            maxLength: 255,
            textCapitalization: TextCapitalization.words,
            forceErrorText: widget.errors['recipient_name'],
            decoration: const InputDecoration(
              labelText: 'Recipient name',
              helperText: 'The person who actually receives this parcel',
            ),
            validator: (value) => _plain(value, 'recipient_name', min: 2),
            onChanged: (_) => _edit('recipient_name'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('parcel-relationship-${task.version}'),
            initialValue: relationship,
            isExpanded: true,
            itemHeight: null,
            decoration: InputDecoration(
              labelText: 'Relationship to buyer',
              errorText: widget.errors['recipient_relationship'],
            ),
            items: [
              for (final entry in recipientRelationships.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: enabled
                ? (value) {
                    setState(() => relationship = value);
                    _edit('recipient_relationship');
                  }
                : null,
            validator: (value) =>
                value == null ? 'Choose who received the parcel.' : null,
          ),
          const SizedBox(height: 24),
          Text(
            '3. Confirm the exact COD',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          WorkspacePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Recorded amount due'),
                const SizedBox(height: 8),
                Text(
                  task.codDueCents == null
                      ? 'COD amount unavailable'
                      : exactPesos(task.codDueCents!),
                  key: const ValueKey('parcel-cod-due'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Received cash minus change must equal this amount.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final inputs = [
                TextFormField(
                  key: const ValueKey('parcel-cash-received'),
                  controller: received,
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  forceErrorText: widget.errors['cash_received'],
                  decoration: const InputDecoration(
                    labelText: 'Cash received',
                    prefixText: '₱ ',
                    hintText: 'Amount actually received',
                  ),
                  validator: (value) {
                    final error = _money(value, 'cash_received');
                    if (error != null) return error;
                    if (_money(change.text, 'change_given') == null &&
                        task.codDueCents != null &&
                        pesoInputCents((value ?? '').trim()) -
                                pesoInputCents(
                                  change.text.trim(),
                                  field: 'change_given',
                                ) !=
                            task.codDueCents) {
                      return 'Received cash minus change must equal COD.';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    setState(() {});
                    _edit('cash_received');
                  },
                ),
                TextFormField(
                  key: const ValueKey('parcel-change-given'),
                  controller: change,
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  forceErrorText: widget.errors['change_given'],
                  decoration: const InputDecoration(
                    labelText: 'Change given',
                    prefixText: '₱ ',
                    hintText: 'Enter 0 if no change was given',
                  ),
                  validator: (value) => _money(value, 'change_given'),
                  onChanged: (_) {
                    setState(() {});
                    _edit('change_given');
                  },
                ),
              ];
              return constraints.maxWidth >= 560 &&
                      MediaQuery.textScalerOf(context).scale(16) <= 20
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: inputs[0]),
                        const SizedBox(width: 16),
                        Expanded(child: inputs[1]),
                      ],
                    )
                  : Column(
                      children: [
                        inputs[0],
                        const SizedBox(height: 16),
                        inputs[1],
                      ],
                    );
            },
          ),
          if (_cashDifference != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_cashDifference!),
            ),
          const SizedBox(height: 16),
          FormField<bool>(
            initialValue: cashConfirmed,
            validator: (_) => cashConfirmed
                ? null
                : 'Confirm the cash you actually received and change given.',
            builder: (field) => Column(
              children: [
                Material(
                  type: MaterialType.transparency,
                  child: CheckboxListTile(
                    key: const ValueKey('parcel-cash-confirmed'),
                    value: cashConfirmed,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'I received this cash and gave the stated change.',
                    ),
                    subtitle: const Text(
                      'This records cash held by me. Remittance and earnings are separate.',
                    ),
                    onChanged: enabled
                        ? (value) {
                            setState(() => cashConfirmed = value == true);
                            field.didChange(cashConfirmed);
                            _edit('cash_confirmed');
                          }
                        : null,
                  ),
                ),
                if (field.errorText != null ||
                    widget.errors['cash_confirmed'] != null)
                  Text(
                    widget.errors['cash_confirmed'] ?? field.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ] else ...[
          Text(
            'Attempt ${task.failurePolicy!.recordedAttempts + 1} of ${task.failurePolicy!.attemptLimit}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Record what happened. Keep the parcel with you until the destination hub records its return.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('parcel-failure-reason-${task.version}'),
            initialValue: reason,
            isExpanded: true,
            itemHeight: null,
            decoration: InputDecoration(
              labelText: 'Failure reason',
              errorText: widget.errors['reason'],
            ),
            items: [
              for (final entry in task.failurePolicy!.reasons.entries.where(
                (entry) => failureReasonCodes.contains(entry.key),
              ))
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: enabled
                ? (value) {
                    setState(() => reason = value);
                    _edit('reason');
                  }
                : null,
            validator: (value) => value == null
                ? 'Choose the actual reason for this attempt.'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('parcel-failure-location'),
            controller: location,
            enabled: enabled,
            maxLength: 255,
            forceErrorText: widget.errors['location_name'],
            decoration: const InputDecoration(
              labelText: 'Attempt location',
              hintText: 'Where this delivery attempt happened',
            ),
            validator: (value) => _plain(value, 'location_name'),
            onChanged: (_) => _edit('location_name'),
          ),
        ],
      ],
    );
  }
}
