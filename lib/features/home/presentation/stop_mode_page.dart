import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/platform/stop_actions.dart';
import '../../../core/ui/argon_widgets.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../../app/theme.dart';
import '../../navigation/presentation/navigation_controller.dart';
import '../../navigation/presentation/navigation_controls.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';
import '../data/operations_models.dart';
import 'home_task_panel.dart' show stopKindLabel;
import 'task_payment_instruction.dart';
import 'stop_guidance.dart';
import 'task_stage_label.dart';
import '../../handover/presentation/handover_entry.dart';
import '../../../core/commands/parcel_validation.dart';
import '../../parcels/presentation/parcel_action_page.dart';
import '../../messages/presentation/task_messages_page.dart';
import '../../parcel_finder/data/parcel_location_labels.dart';
import '../../parcel_finder/presentation/parcel_finder_card.dart';

class StopModePage extends StatefulWidget {
  const StopModePage({
    super.key,
    required this.initialTask,
    required this.controller,
    this.navigation,
    this.actions = const PlatformStopActions(),
  });

  final RiderTask initialTask;
  final WorkspaceController controller;
  final NavigationController? navigation;
  final StopActions actions;

  @override
  State<StopModePage> createState() => _StopModePageState();
}

class _StopModePageState extends State<StopModePage>
    with WidgetsBindingObserver {
  bool _opening = true, _refreshing = false, _busy = false;
  bool _foreground = true, _resumeRefresh = false;
  late bool _owned;
  int _epoch = 0;
  ModalRoute<dynamic>? _route;
  bool _covered = false;
  String? _notice;
  WorkspaceController get work => widget.controller;
  String get id => widget.initialTask.id;
  OperationTask? get current =>
      !_opening && work.hasWorkAccess && work.selectedTask?.id == id
      ? work.selectedTask
      : null;
  bool get canAct =>
      !_refreshing &&
      !_busy &&
      _foreground &&
      !_covered &&
      (_route?.isCurrent ?? true) &&
      work.canUseSelectedStop(id);

  @override
  void initState() {
    super.initState();
    _owned = widget.initialTask.operation?.preview != true;
    work.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    unawaited(Future.microtask(() => _refresh(initial: true)));
  }

  void _changed() {
    if (!mounted) return;
    if (work.selectedTask?.id == id && work.selectedTask?.preview == false) {
      _owned = true;
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (identical(route, _route)) return;
    _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
    _route = route;
    _route?.secondaryAnimation?.addStatusListener(_routeChanged);
  }

  void _routeChanged(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.forward) {
      _epoch++;
      setState(() => _covered = true);
    } else if (status == AnimationStatus.dismissed && _covered) {
      setState(() => _covered = false);
      _resumeRefresh = true;
      _refreshAfterResume();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _epoch++;
    setState(() => _foreground = state == AppLifecycleState.resumed);
    if (_foreground) {
      _resumeRefresh = true;
      _refreshAfterResume();
    }
  }

  void _refreshAfterResume() {
    if (_resumeRefresh &&
        _foreground &&
        !_covered &&
        !_busy &&
        !_refreshing &&
        mounted) {
      _resumeRefresh = false;
      unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    _epoch++;
    work.removeListener(_changed);
    _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh({bool initial = false}) async {
    if (_refreshing || _busy || !_foreground || !mounted) return;
    final epoch = ++_epoch;
    setState(() {
      _refreshing = true;
      _notice = null;
    });
    try {
      if (work.coolingDown) {
        _notice = 'Wait for the work refresh cooldown, then try again.';
        return;
      }
      if (work.homeData.status != FeatureStatus.ready) {
        await work.refreshHome();
      }
      if (!mounted || epoch != _epoch || !_foreground) return;
      if (!_owned && !initial) {
        await work.refreshTasks();
        if (!mounted || epoch != _epoch || !_foreground) return;
        final matches = work.taskData.data?.where((task) => task.id == id);
        if (matches == null || matches.isEmpty) {
          work.closeTask();
          return;
        }
        await work.openTask(matches.first);
      } else {
        final original = widget.initialTask;
        await work.openTask(
          RiderTask(
            id: id,
            tracking: original.tracking,
            stage: original.stage,
            stop: original.stop,
            address: original.address,
            nextStep: original.nextStep,
            operation: _owned ? null : original.operation,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
          _refreshing = false;
        });
        _refreshAfterResume();
      }
    }
  }

  Future<OperationTask?> _check(OperationTask reviewed, int epoch) async {
    final fresh = await work.revalidateSelectedStop(id);
    if (!mounted ||
        epoch != _epoch ||
        !_foreground ||
        _covered ||
        !(_route?.isCurrent ?? true)) {
      return null;
    }
    if (fresh == null) {
      _report(
        'This stop could not be revalidated. Refresh before using its actions.',
      );
      return null;
    }
    if (!sameReviewedStop(reviewed, fresh)) {
      _report('The stop changed. Review its current details and try again.');
      return null;
    }
    return fresh;
  }

  Future<OperationTask?> _authorizeNavigation() async {
    if (!canAct || current == null) return null;
    final reviewed = current!, epoch = _epoch;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      return await _check(reviewed, epoch);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _refreshAfterResume();
      }
    }
  }

  Future<void> _act(
    Future<String> Function(OperationTask) action,
    String failure,
  ) async {
    if (!canAct || current == null) return;
    final reviewed = current!, epoch = _epoch;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final fresh = await _check(reviewed, epoch);
      if (fresh == null) return;
      final message = await action(fresh);
      if (mounted && epoch == _epoch && _foreground) _report(message);
    } catch (_) {
      if (mounted && epoch == _epoch) _report(failure);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _refreshAfterResume();
      }
    }
  }

  void _report(String message) {
    _notice = message;
  }

  Future<String?> _setParcelLocation(OperationTask reviewed, ParcelSlot? slot) {
    final epoch = _epoch;
    return work.setParcelLocation(
      reviewed,
      slot,
      mayApply: () => mounted && epoch == _epoch && canAct,
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = current;
    final preview = task?.preview ?? !_owned;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => Navigator.of(context).maybePop(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            key: const ValueKey('stop-mode-page'),
            appBar: AppBar(
              toolbarHeight:
                  (MediaQuery.textScalerOf(context).scale(22) * 1.4 + 16).clamp(
                    56.0,
                    96.0,
                  ),
              title: const Text('Stop Mode'),
              leading: IconButton(
                key: const ValueKey('stop-back'),
                tooltip: 'Back to tasks',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ),
            body: RiderCanvas(
              child: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: ListView(
                      key: const ValueKey('stop-mode-scroll'),
                      padding: const EdgeInsets.all(16),
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const LiquidGlassOrb(size: 36, blurSigma: 10),
                            DieCutStickerWidget.speechBubble(
                              text: preview ? 'PICKUP PREVIEW' : 'STOP MODE',
                              backgroundColor: RiderColors.accent,
                              rotationDegrees: 0,
                              leadingIcon: Icons.location_on_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          preview ? 'Pickup preview' : 'Work this stop',
                          key: const ValueKey('stop-mode-heading'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const ValueKey('stop-refresh'),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed:
                                _refreshing ||
                                    _busy ||
                                    !_foreground ||
                                    work.selectingTask
                                ? null
                                : _refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(
                              _refreshing ? 'Checking stop…' : 'Refresh stop',
                            ),
                          ),
                        ),
                        if (_refreshing || work.selectingTask)
                          const Text(
                            'Checking the current stop. Actions are paused.',
                          ),
                        if (!_foreground)
                          const Text(
                            'Return to Rider to revalidate this stop.',
                          ),
                        if (_notice != null && (task == null || preview)) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _notice!,
                              key: const ValueKey('stop-notice'),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (task == null) ...[
                          if (!_refreshing && !work.selectingTask)
                            const WorkspaceEmpty(
                              'Stop unavailable',
                              'This parcel could not be revalidated. Refresh the stop or return to your tasks.',
                            ),
                          if (widget.navigation != null) _fallbackStop(),
                        ] else ...[
                          _details(task),
                          if (!preview && work.parcelFinderAvailable) ...[
                            const SizedBox(height: 16),
                            ParcelFinderCard(
                              key: ValueKey(
                                'parcel-finder-${task.id}-${task.assignmentReference}',
                              ),
                              task: task,
                              location: work.parcelLocationFor(task),
                              suffix: distinguishingTrackingSuffix(
                                task.tracking,
                                (work.taskData.data ?? []).map(
                                  (item) => item.tracking,
                                ),
                              ),
                              enabled:
                                  canAct && work.canSetParcelLocation(task),
                              save: (slot) => _setParcelLocation(task, slot),
                            ),
                          ],
                          if (!preview && work.operations != null)
                            HandoverEntry(
                              home: work.homeData.data,
                              accountId: work.operations!.accountId,
                              barcode: task.tracking,
                              enabled: canAct,
                            ),
                          const SizedBox(height: 16),
                          _guidance(task),
                          const SizedBox(height: 16),
                          if (preview) ...[
                            const Text(
                              'Claim this pickup before using private contact or navigation.',
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              key: const ValueKey('stop-claim'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed:
                                  !_refreshing &&
                                      _foreground &&
                                      work.canWrite &&
                                      work.homeData.data?.canClaim == true &&
                                      task.actions['claim'] == true
                                  ? () => work.claimTask(task)
                                  : null,
                              child: Text(
                                work.working
                                    ? 'Checking claim…'
                                    : 'Claim pickup',
                              ),
                            ),
                          ] else ...[
                            if (!canAct &&
                                !_refreshing &&
                                !work.selectingTask &&
                                !_busy)
                              const Text(
                                'Refresh work and this stop before using its actions.',
                              ),
                            if (task.actions['pickup'] == true ||
                                task.actions['depart'] == true) ...[
                              FilledButton.icon(
                                key: const ValueKey('stop-parcel-action'),
                                onPressed: canAct && work.canWriteParcel
                                    ? () => Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: (_) => ParcelActionPage(
                                            work: work,
                                            taskId: task.id,
                                            action:
                                                task.actions['pickup'] == true
                                                ? ParcelAction.pickup
                                                : ParcelAction.depart,
                                          ),
                                        ),
                                      )
                                    : null,
                                icon: const Icon(Icons.qr_code_scanner_rounded),
                                label: Text(
                                  task.actions['pickup'] == true
                                      ? 'Scan and collect parcel'
                                      : 'Scan and start delivery',
                                ),
                              ),
                              if (!work.canWriteParcel)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Parcel actions are awaiting live acceptance verification or a current work check.',
                                  ),
                                ),
                              const SizedBox(height: 16),
                            ],
                            if (task.actions['deliver'] == true) ...[
                              FilledButton.icon(
                                key: const ValueKey('stop-deliver'),
                                onPressed: canAct && work.canWriteParcel
                                    ? () => Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: (_) => ParcelActionPage(
                                            work: work,
                                            taskId: task.id,
                                            action: ParcelAction.deliver,
                                          ),
                                        ),
                                      )
                                    : null,
                                icon: const Icon(Icons.inventory_2_outlined),
                                label: const Text('Record recipient delivery'),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (task.actions['fail'] == true) ...[
                              OutlinedButton.icon(
                                key: const ValueKey('stop-fail'),
                                onPressed: canAct && work.canWriteParcel
                                    ? () => Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: (_) => ParcelActionPage(
                                            work: work,
                                            taskId: task.id,
                                            action: ParcelAction.fail,
                                          ),
                                        ),
                                      )
                                    : null,
                                icon: const Icon(Icons.report_problem_outlined),
                                label: const Text('Report failed attempt'),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (task.actionDenials['deliver'] ==
                                'UNSUPPORTED_PAYMENT_OUTCOME')
                              const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'Recording this payment type is not supported in the app yet. Contact your hub for the next step.',
                                ),
                              ),
                            _stopActions(task),
                            const SizedBox(height: 16),
                            if (widget.navigation != null &&
                                !widget.navigation!.isDisposed)
                              NavigationControls(
                                key: ValueKey(
                                  'stop-navigation-${task.id}-${task.stop.kind}',
                                ),
                                task: task,
                                navigation: widget.navigation!,
                                enabled:
                                    canAct &&
                                    task.actionDenials['handover'] == null,
                                revalidateTask: _authorizeNavigation,
                                launchDirections: widget.actions.open,
                              ),
                          ],
                        ],
                        if (work.workFailure != null) ...[
                          const SizedBox(height: 12),
                          Semantics(
                            liveRegion: true,
                            child: Text(work.workFailure!.message),
                          ),
                        ],
                        if (work.pendingIntent != null)
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: work.working
                                ? null
                                : () => work.checkPending(),
                            child: const Text('Check saved request'),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(OperationTask task) => RiderSurface(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [WorkspaceBadge(taskStageLabel(task.stage), accent: true)],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(
              Icons.place_outlined,
              size: 18,
              color: RiderColors.accentText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stopKindLabel(task.stop.kind),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: RiderColors.accentText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _text(task.stop.name) ?? 'Stop name unavailable',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 8),
        SelectableText(
          _text(task.stop.address) ?? 'Address unavailable',
          key: const ValueKey('stop-address'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (task.stop.latitude == null || task.stop.longitude == null) ...[
          const SizedBox(height: 8),
          Text(
            'Address only · no saved map pin',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),
        Text('Tracking number', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        SelectableText(
          task.tracking,
          key: const ValueKey('stop-tracking'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text('Order number', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        SelectableText(task.order, key: const ValueKey('stop-order')),
        const SizedBox(height: 16),
        Text(
          custodyLabel(task),
          key: const ValueKey('stop-custody'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TaskPaymentInstruction(
          task: task,
          codPrefix: 'Recorded COD to collect',
        ),
      ],
    ),
  );

  Widget _guidance(OperationTask task) => RiderSurface(
    color: RiderColors.rose,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Next step', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(task.nextInstruction, key: const ValueKey('stop-instruction')),
        const SizedBox(height: 12),
        Text('Next responsible actor: ${nextActorLabel(task)}'),
        const SizedBox(height: 12),
        Text(legGuide(task)),
        if (!task.preview && _text(task.stop.instructions) != null) ...[
          const SizedBox(height: 20),
          Text(
            task.stop.kind == 'buyer' ? 'Doorstep Guide' : 'Stop instructions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(
            task.stop.instructions!,
            key: const ValueKey('stop-notes'),
          ),
        ],
      ],
    ),
  );

  Widget _stopActions(OperationTask task) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_text(task.stop.phone) != null)
        SelectableText(task.stop.phone!, key: const ValueKey('stop-phone')),
      if (stopPhoneUri(task.stop.phone) == null)
        const Text('Phone number unavailable for calling.'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (!task.preview &&
              work.homeData.data?.capabilities['messages'] == true)
            _button(
              'stop-message',
              task.phase == 'pickup' ? 'Message seller' : 'Message buyer',
              Icons.chat_bubble_outline_rounded,
              true,
              () => _act((fresh) async {
                await openTaskMessages(context, work, fresh);
                return 'Parcel conversation closed.';
              }, 'Could not open this parcel conversation.'),
            ),
          _button(
            'stop-copy-tracking',
            'Copy tracking ID',
            Icons.copy_rounded,
            _text(task.tracking) != null,
            () => _act((fresh) async {
              await widget.actions.copy(fresh.tracking);
              return 'Tracking ID copied.';
            }, 'Could not copy the tracking ID.'),
          ),
          _button(
            'stop-copy-order',
            'Copy order ID',
            Icons.copy_rounded,
            _text(task.order) != null,
            () => _act((fresh) async {
              await widget.actions.copy(fresh.order);
              return 'Order ID copied.';
            }, 'Could not copy the order ID.'),
          ),
          _button(
            'stop-copy-address',
            'Copy address',
            Icons.content_copy_rounded,
            _text(task.stop.address) != null,
            () => _act((fresh) async {
              await widget.actions.copy(fresh.stop.address!);
              return 'Address copied.';
            }, 'Could not copy the address.'),
          ),
          _button(
            'stop-call',
            'Call current stop',
            Icons.call_outlined,
            stopPhoneUri(task.stop.phone) != null,
            () => _act((fresh) async {
              final uri = stopPhoneUri(fresh.stop.phone);
              if (uri == null) return 'Phone number unavailable for calling.';
              return await widget.actions.open(uri)
                  ? 'Phone app opened.'
                  : 'Could not open the phone app. Use the recorded number.';
            }, 'Could not open the phone app. Use the recorded number.'),
          ),
        ],
      ),
      if (_notice != null) ...[
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(_notice!, key: const ValueKey('stop-notice')),
        ),
      ],
    ],
  );

  Widget _button(
    String key,
    String label,
    IconData icon,
    bool available,
    VoidCallback action,
  ) => TextButton.icon(
    key: ValueKey(key),
    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    onPressed: canAct && available ? action : null,
    icon: Icon(icon, size: 20),
    label: Text(label),
  );

  Widget _fallbackStop() {
    final nav = widget.navigation!;
    if (nav.isDisposed) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: nav,
      builder: (context, _) {
        return nav.active || nav.starting || nav.paused
            ? OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: nav.stop,
                child: const Text('Stop navigation'),
              )
            : const SizedBox.shrink();
      },
    );
  }

  String? _text(String? value) =>
      value?.trim().isNotEmpty == true ? value : null;
}
