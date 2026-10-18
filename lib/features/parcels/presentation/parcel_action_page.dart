import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/commands/parcel_validation.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';
import 'parcel_action_controller.dart';
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
  bool capturing = false;
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
    if (form.currentState?.validate() != true) return;
    final fields = <String, dynamic>{};
    if (notes.text.trim().isNotEmpty) {
      fields['notes'] = parcelText(notes.text, 'notes');
    }
    await controller.submit(fields: fields);
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final task = c.task;
    final action = widget.action;
    return Scaffold(
      key: const ValueKey('parcel-action-page'),
      appBar: AppBar(
        title: Text(action.label),
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
                            Text(
                              action == ParcelAction.pickup
                                  ? 'Collect from the seller'
                                  : 'Leave the destination hub',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              action == ParcelAction.pickup
                                  ? 'Verify this parcel, scan its waybill and confirm the handoff. Your next stop will be its origin hub.'
                                  : 'Verify the hub-assigned parcel and scan its waybill before starting the buyer delivery.',
                            ),
                            const SizedBox(height: 24),
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
                                    const WorkspaceBadge(
                                      'Current parcel',
                                      accent: true,
                                    ),
                                    const SizedBox(height: 12),
                                    SelectableText(
                                      task.tracking,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(task.order),
                                    const SizedBox(height: 16),
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
                              const SizedBox(height: 24),
                              Text(
                                '1. Verify the waybill',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              if (c.barcode != null) ...[
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    'Waybill matched: ${c.barcode}',
                                    key: const ValueKey('parcel-matched-scan'),
                                  ),
                                ),
                                const SizedBox(height: 12),
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
                              Text(
                                '2. Review the handoff',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                key: const ValueKey('parcel-notes'),
                                controller: notes,
                                enabled: !c.submitting,
                                maxLength: 500,
                                minLines: 2,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Notes (optional)',
                                  hintText: 'Useful details about this handoff',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return null;
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
                                action == ParcelAction.pickup
                                    ? 'Confirm only after receiving this parcel from the seller. The origin hub records its own intake.'
                                    : 'Confirm only after receiving this parcel from the assigned destination hub.',
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                key: const ValueKey('parcel-submit'),
                                onPressed: c.canSubmit && !capturing
                                    ? _submit
                                    : null,
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
                                child: Text(
                                  c.failure!.message,
                                  key: const ValueKey('parcel-error'),
                                  style: const TextStyle(
                                    color: RiderColors.accentText,
                                  ),
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
        Text(
          widget.action == ParcelAction.pickup
              ? 'Collection recorded'
              : 'Departure recorded',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          widget.work.selectedTask?.nextInstruction ??
              'Refresh your tasks to see the current responsibility.',
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continue to current stop'),
        ),
      ],
    ),
  );
}
