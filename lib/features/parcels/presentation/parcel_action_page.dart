import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/commands/parcel_validation.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../home/presentation/stop_guidance.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';
import 'parcel_action_controller.dart';
import 'parcel_outcome_fields.dart';
import 'waybill_scanner_page.dart';

typedef ParcelScanLauncher = Future<String?> Function(
  BuildContext context,
  String expectedWaybill,
);

class ParcelActionPage extends StatefulWidget {
  const ParcelActionPage({
    super.key,
    required this.work,
    required this.taskId,
    required this.action,
    this.scan,
    this.cameraAvailable,
  });
  final WorkspaceController work;
  final String taskId;
  final ParcelAction action;
  final ParcelScanLauncher? scan;
  final bool? cameraAvailable;
  @override
  State<ParcelActionPage> createState() => _ParcelActionPageState();
}

class _ParcelActionPageState extends State<ParcelActionPage>
    with WidgetsBindingObserver {
  late final ParcelActionController controller;
  final notes = TextEditingController();
  final form = GlobalKey<FormState>();
  final outcome = GlobalKey<ParcelOutcomeFieldsState>();
  final validationSummary = GlobalKey();
  final validationFocus = FocusNode();
  bool capturing = false,
      validationFailed = false,
      _proofCleanupStarted = false;
  bool get cameraAvailable => widget.cameraAvailable ?? supportsParcelCamera;
  @override
  void initState() {
    super.initState();
    controller = ParcelActionController(
      work: widget.work,
      taskId: widget.taskId,
      action: widget.action,
    );
    controller.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  void _changed() {
    if (!mounted) return;
    if (!widget.work.hasWorkAccess) notes.clear();
    if (controller.result != null && !_proofCleanupStarted) {
      _proofCleanupStarted = true;
      final photos = widget.work.operations?.photos;
      final draft = photos?.recovered;
      if (draft != null &&
          draft.context.taskId == widget.taskId &&
          draft.context.action == widget.action) {
        unawaited(
          photos!
              .discard(expectedKey: draft.context.key)
              .catchError((Object _) {}),
        );
      }
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      controller.setForeground(state == AppLifecycleState.resumed);
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_changed);
    controller.dispose();
    notes.dispose();
    validationFocus.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (!controller.canCapture || capturing || !cameraAvailable) return;
    setState(() => capturing = true);
    try {
      final reviewed = controller.task!;
      final actual =
          await (widget.scan?.call(context, reviewed.tracking) ??
              Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => WaybillScannerPage(
                    expectedWaybill: reviewed.tracking,
                    orderReference: reviewed.order,
                    authorization: widget.work,
                    isAuthorized: () =>
                        widget.work.hasWorkAccess &&
                        widget.work.selectedTask?.id == reviewed.id &&
                        widget.work.selectedTask?.version == reviewed.version,
                  ),
                ),
              ));
      if (!mounted) return;
      await controller.refresh();
      if (mounted && actual != null) controller.acceptScan(actual);
    } catch (_) {
      if (mounted) controller.captureFailed();
    } finally {
      if (mounted) setState(() => capturing = false);
    }
  }

  Future<void> _submit() async {
    if (form.currentState?.validate() != true) {
      setState(() => validationFailed = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        validationFocus.requestFocus();
        final target = validationSummary.currentContext;
        if (target != null) unawaited(Scrollable.ensureVisible(target));
      });
      return;
    }
    setState(() => validationFailed = false);
    final fields = <String, dynamic>{};
    if (widget.action.requiresProof) {
      fields.addAll(outcome.currentState!.fields());
    }
    if (notes.text.trim().isNotEmpty) {
      fields['notes'] = parcelText(notes.text, 'notes');
    }
    await controller.submit(fields: fields, proof: outcome.currentState?.proof);
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final task = c.task;
    final action = widget.action;
    return Scaffold(
      key: const ValueKey('parcel-action-page'),
      appBar: AppBar(
        title: Text(action.label, maxLines: 2),
        toolbarHeight: (MediaQuery.textScalerOf(context).scale(22) * 1.4 + 16)
            .clamp(56.0, 96.0),
      ),
      body: RiderCanvas(
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  key: const ValueKey('parcel-action-scroll'),
                  padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 32),
                  children: [
                    if (c.result != null)
                      _success()
                    else
                      Form(
                        key: form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // The app bar names the step; one short line says what to do.
                            Text(
                              switch (action) {
                                ParcelAction.pickup => 'Scan the waybill, then confirm you have the parcel.',
                                ParcelAction.depart => 'Scan the waybill, then confirm you are leaving the hub with it.',
                                ParcelAction.deliver => 'Scan the waybill, add a photo and the cash, then record the delivery.',
                                ParcelAction.fail => 'Scan the waybill, then record why the delivery did not happen.',
                              },
                              style: const TextStyle(color: RiderColors.muted),
                            ),
                            if (validationFailed)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Focus(
                                  key: validationSummary,
                                  focusNode: validationFocus,
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      'Check the highlighted fields before recording this action.',
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            if (c.loading)
                              const LinearProgressIndicator(
                                semanticsLabel: 'Checking parcel',
                              ),
                            if (task != null) ...[
                              WorkspacePanel(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'WAYBILL TO SCAN',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                              color: RiderColors.muted,
                                            ),
                                          ),
                                        ),
                                        if (action == ParcelAction.deliver &&
                                            task.stop.latitude != null &&
                                            task.stop.longitude != null)
                                          const WorkspaceBadge(
                                            'Within 100 m of the pin',
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText(
                                      task.tracking,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    SelectableText(
                                      task.order,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: RiderColors.muted,
                                      ),
                                    ),
                                    const Divider(height: 24),
                                    Text(
                                      task.stop.name ?? 'Stop name unavailable',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      task.stop.address ??
                                          'Address unavailable',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '1. Scan the waybill',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              if (c.barcode != null) ...[
                                Semantics(
                                  liveRegion: true,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF15803D),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Waybill matched: ${c.barcode}',
                                          key: const ValueKey(
                                            'parcel-matched-scan',
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              OutlinedButton.icon(
                                key: const ValueKey('parcel-scan'),
                                onPressed:
                                    c.canCapture &&
                                        !capturing &&
                                        cameraAvailable
                                    ? _scan
                                    : null,
                                icon: const Icon(Icons.qr_code_scanner_rounded),
                                label: Text(
                                  capturing
                                      ? 'Scanning…'
                                      : c.barcode == null
                                      ? 'Scan parcel waybill'
                                      : 'Scan again',
                                ),
                              ),
                              if (!cameraAvailable) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Waybill scanning requires an Android phone. Task browsing remains available on this device.',
                                ),
                              ],
                              const SizedBox(height: 24),
                              if (action.requiresProof)
                                ParcelOutcomeFields(
                                  key: outcome,
                                  task: task,
                                  action: action,
                                  enabled: c.canCapture && !capturing,
                                  privateVisible: c.foreground,
                                  photos: widget.work.operations?.photos,
                                  errors: c.failure?.fields ?? const {},
                                  onChanged: () {
                                    if (mounted) setState(() {});
                                  },
                                  onEdited: c.clearFieldError,
                                  revalidate: c.refresh,
                                ),
                              if (!action.requiresProof)
                                Text(
                                  '2. Confirm the handoff',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              const SizedBox(height: 12),
                              TextFormField(
                                key: const ValueKey('parcel-notes'),
                                controller: notes,
                                enabled: c.canCapture,
                                forceErrorText: c.failure?.fields['notes'],
                                onChanged: (_) => c.clearFieldError('notes'),
                                maxLength: 500,
                                minLines: 2,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: action == ParcelAction.fail
                                      ? 'Attempt notes'
                                      : 'Notes',
                                  helperText: action == ParcelAction.fail
                                      ? null
                                      : 'Optional details about this handoff',
                                  helperMaxLines: 3,
                                  hintText: 'Useful details about this handoff',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return action == ParcelAction.fail
                                        ? 'Describe what happened during this attempt.'
                                        : null;
                                  }
                                  try {
                                    parcelText(value, 'notes');
                                    return null;
                                  } catch (_) {
                                    return 'Use plain notes up to 500 characters.';
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                switch (action) {
                                  ParcelAction.pickup => 'Confirm only once the parcel is in your hands.',
                                  ParcelAction.depart => 'Confirm only once the hub has handed you the parcel.',
                                  ParcelAction.deliver => 'Confirm only after handing the parcel over.',
                                  ParcelAction.fail => 'Keep the parcel until the hub receives it back.',
                                },
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: RiderColors.muted,
                                ),
                              ),
                              if (validationFailed) ...[
                                const SizedBox(height: 12),
                                const _ErrorBox(
                                  'Some details need fixing. Check the fields marked in red above.',
                                ),
                              ],
                              const SizedBox(height: 24),
                              FilledButton(
                                key: const ValueKey('parcel-submit'),
                                onPressed:
                                    c.canSubmit &&
                                        !capturing &&
                                        (!action.requiresProof ||
                                            outcome.currentState?.ready == true)
                                    ? _submit
                                    : null,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: Text(
                                  c.submitting ? 'Confirming…' : action.label,
                                ),
                              ),
                            ],
                            if (c.unavailableReason != null) ...[
                              const SizedBox(height: 16),
                              Text(c.unavailableReason!),
                            ],
                            if (c.failure != null) ...[
                              const SizedBox(height: 16),
                              Semantics(
                                liveRegion: true,
                                child: _ErrorBox(
                                  c.failure!.message,
                                  textKey: const ValueKey('parcel-error'),
                                ),
                              ),
                              for (final error in c.failure!.fields.values)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(error),
                                ),
                            ],
                            const SizedBox(height: 12),
                            TextButton.icon(
                              key: const ValueKey('parcel-refresh'),
                              onPressed:
                                  c.loading || c.submitting || !c.foreground
                                  ? null
                                  : c.refresh,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Refresh parcel'),
                            ),
                            if (widget.work.pendingIntent != null) ...[
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'The saved request keeps its original values and proof. Rechecking or retrying uses that exact request.',
                                ),
                              ),
                              OutlinedButton(
                                onPressed: widget.work.working
                                    ? null
                                    : () => widget.work.checkPending(),
                                child: const Text('Check saved request'),
                              ),
                              TextButton(
                                onPressed: widget.work.working
                                    ? null
                                    : () => widget.work.checkPending(
                                        retryUnknown: true,
                                      ),
                                child: const Text(
                                  'Check and retry original request',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _success() => WorkspacePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: RiderColors.accentText,
          size: 40,
        ),
        const SizedBox(height: 16),
        Text(switch (widget.action) {
          ParcelAction.pickup => 'Collection recorded',
          ParcelAction.depart => 'Departure recorded',
          ParcelAction.deliver => 'Delivery recorded',
          ParcelAction.fail => 'Attempt recorded',
        }, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(
          widget.action == ParcelAction.deliver
              ? deliveryRecordedNotice(controller.result?['commercial_status'])
              : widget.work.selectedTask == null
              ? 'Refresh your tasks to see the current responsibility.'
              : taskInstruction(widget.work.selectedTask!),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => widget.action == ParcelAction.deliver
              ? Navigator.of(context).popUntil((route) => route.isFirst)
              : Navigator.of(context).pop(),
          child: Text(
            widget.action == ParcelAction.deliver
                ? 'Back to tasks'
                : 'Continue to current stop',
          ),
        ),
      ],
    ),
  );
}

/// A visible red message box so errors are not missed below the fold.
class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message, {this.textKey});
  final String message;
  final Key? textKey;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFB91C1C),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            key: textKey,
            style: const TextStyle(
              color: Color(0xFFB91C1C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
