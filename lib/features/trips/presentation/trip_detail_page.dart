import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ui/private_image.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../home/data/operations_models.dart';
import '../../cash/presentation/financial_summary.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';
import '../data/trip_models.dart';
import 'trip_detail_controller.dart';

class TripDetailPage extends StatefulWidget {
  const TripDetailPage({
    super.key,
    required this.work,
    required this.id,
    this.controller,
  });
  final WorkspaceController work;
  final String id;
  final TripDetailController? controller;
  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage>
    with WidgetsBindingObserver {
  late final TripDetailController controller;
  @override
  void initState() {
    super.initState();
    controller =
        widget.controller ??
        TripDetailController(work: widget.work, id: widget.id);
    WidgetsBinding.instance.addObserver(this);
    unawaited(controller.refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      controller.setForeground(state == AppLifecycleState.resumed);
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  Future<void> openProof(String path) async {
    unawaited(controller.loadProof(path));
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => _TripProofPage(controller: controller)),
    );
    if (mounted) controller.clearProof();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 28
            ? 96
            : 56,
        title: const Text('Trip details', maxLines: 2),
        actions: [
          IconButton(
            tooltip: 'Refresh assignment',
            onPressed: controller.accessible && !widget.work.coolingDown
                ? controller.refresh
                : null,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RiderCanvas(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  FeatureStateView<RetainedTrip>(
                    data: controller.detail,
                    icon: Icons.history_rounded,
                    title: 'Recorded assignment',
                    onRetry: controller.refresh,
                    ready: (trip) =>
                        _RecordedAssignment(trip: trip, onProof: openProof),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RecordedAssignment extends StatelessWidget {
  const _RecordedAssignment({required this.trip, required this.onProof});
  final RetainedTrip trip;
  final ValueChanged<String> onProof;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          WorkspaceBadge(trip.phase == 'pickup' ? 'Pickup' : 'Final mile'),
          WorkspaceBadge(
            tripOutcomeLabel(trip.outcome),
            accent: trip.outcome == 'delivered',
          ),
        ],
      ),
      const SizedBox(height: 20),
      SelectableText(
        trip.tracking,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      SelectableText('Order ${trip.order}'),
      const SizedBox(height: 24),
      WorkspacePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your original assignment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SelectableText(trip.assignmentReference),
            const SizedBox(height: 8),
            Text(
              'Assigned ${dayLabel(trip.assignedAt)} · ${timeLabel(trip.assignedAt)} (Manila)',
            ),
            if (trip.lastRecordedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last recorded ${dayLabel(trip.lastRecordedAt!)} · ${timeLabel(trip.lastRecordedAt!)} (Manila)',
              ),
            ],
            const SizedBox(height: 16),
            Text(
              trip.recipient == null
                  ? 'Recipient details are unavailable for this assignment.'
                  : 'Recorded recipient: ${trip.recipient}',
            ),
            const SizedBox(height: 8),
            Text(
              trip.address == null
                  ? 'Handoff address was not recorded for this assignment.'
                  : 'Recorded handoff: ${trip.address}',
            ),
            const SizedBox(height: 16),
            Text(
              'Payment: ${switch (trip.paymentMethod) {
                'cod' => 'COD',
                'wallet' => 'Bagoo Wallet',
                _ => 'Recorded non-COD',
              }}',
            ),
            const SizedBox(height: 8),
            Text(
              trip.collectedCents == null
                  ? 'No cash collection is recorded for this assignment.'
                  : 'Recorded collection: ${exactPesos(trip.collectedCents!)}',
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      RiderEarningsSummary(
        earnings: trip.earnings,
        title: 'Earnings for this assignment',
      ),
      const SizedBox(height: 24),
      Text('Recorded journey', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text(
        'Events and proof belong to your retained assignment. Later riders’ work is not included.',
      ),
      const SizedBox(height: 16),
      if (trip.checkpoints.isEmpty) const Text('No checkpoints were returned.'),
      for (final checkpoint in trip.checkpoints)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _HistoryEvent(
            label: tripOutcomeLabel(checkpoint.kind),
            reference: checkpoint.reference,
            at: checkpoint.recordedAt,
            description: checkpoint.waybillMatched
                ? 'Waybill matched'
                : 'No matching waybill recorded',
            proofPath: checkpoint.proofPath,
            onProof: onProof,
          ),
        ),
      if (trip.attempts.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(
          'Delivery attempts',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        for (final attempt in trip.attempts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HistoryEvent(
              label: 'Attempt ${attempt.number}',
              reference: attempt.reference,
              at: attempt.recordedAt,
              description: attempt.reason.replaceAll('_', ' '),
              proofPath: attempt.proofPath,
              onProof: onProof,
            ),
          ),
      ],
      const SizedBox(height: 16),
      WorkspacePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Parcel now', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Operational stage: ${trip.currentStage.replaceAll('_', ' ')}',
            ),
            Text('Order status: ${trip.commercialStatus.replaceAll('_', ' ')}'),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Buyer receipt, cash remittance and rider earnings are separate records. No earnings are confirmed here.',
      ),
      const SizedBox(height: 28),
    ],
  );
}

class _HistoryEvent extends StatelessWidget {
  const _HistoryEvent({
    required this.label,
    required this.reference,
    required this.at,
    required this.description,
    required this.proofPath,
    required this.onProof,
  });
  final String label, reference, description;
  final DateTime at;
  final String? proofPath;
  final ValueChanged<String> onProof;
  @override
  Widget build(BuildContext context) => WorkspacePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SelectableText(reference),
        const SizedBox(height: 8),
        Text('${dayLabel(at)} · ${timeLabel(at)} (Manila)'),
        const SizedBox(height: 8),
        Text(description),
        if (proofPath != null) ...[
          const SizedBox(height: 12),
          RiderPressFeedback(
            child: OutlinedButton.icon(
              key: ValueKey('proof-$proofPath'),
              onPressed: () => onProof(proofPath!),
              icon: const Icon(Icons.lock_outline_rounded),
              label: const Text('View private proof'),
            ),
          ),
        ],
      ],
    ),
  );
}

class _TripProofPage extends StatelessWidget {
  const _TripProofPage({required this.controller});
  final TripDetailController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 28
            ? 96
            : 56,
        title: const Text('Private proof', maxLines: 2),
      ),
      body: RiderCanvas(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('Private image from your original assignment'),
                  const SizedBox(height: 20),
                  if (controller.proof.data != null)
                    PrivateImage(
                      bytes: controller.proof.data!.bytes,
                      label: 'Recorded parcel proof',
                      height: 480,
                      onInvalid: controller.invalidProof,
                    )
                  else if (controller.proof.status == FeatureStatus.loading)
                    const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading private proof',
                      ),
                    )
                  else
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        controller.proof.message ??
                            'Private proof is unavailable.',
                      ),
                    ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed:
                        controller.accessible &&
                            !controller.work.coolingDown &&
                            controller.proofPath != null &&
                            controller.proof.status != FeatureStatus.loading
                        ? () => controller.loadProof(controller.proofPath!)
                        : null,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh proof'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Proof is cleared when you close it or leave the app. Return to the assignment to revalidate after leaving.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
