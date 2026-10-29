import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/platform/rider_website.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/data/operations_models.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';
import 'trip_detail_page.dart';
import 'trip_detail_controller.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key, required this.controller, required this.preview});
  final WorkspaceController controller;
  final bool preview;
  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  late final search = TextEditingController(text: widget.controller.tripSearch);
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void clear() {
    search.clear();
    widget.controller.clearTripFilters();
  }

  Future<void> dates() async {
    final controller = widget.controller;
    final now = manilaTime(DateTime.now());
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: controller.fromDate == null || controller.toDate == null
          ? null
          : DateTimeRange(start: controller.fromDate!, end: controller.toDate!),
    );
    if (range != null && mounted) {
      controller.filterDates(range.start, range.end);
    }
  }

  Future<void> openTrip(RiderTrip trip) async {
    if (trip.operation == null) {
      await showRiderSheet<void>(
        context: context,
        sheetAnimationStyle: RiderMotion.sheetStyle(context),
        isScrollControlled: true,
        builder: (_) => _TripDetails(trip: trip, preview: widget.preview),
      );
      return;
    }
    final details = TripDetailController(work: widget.controller, id: trip.id);
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => Consumer(
            builder: (context, ref, _) {
              ref.listen(
                authControllerProvider.select(
                  (session) => (
                    id: session.user?.id,
                    approved: session.user?.approved,
                    version: session.user?.operationsApiVersion,
                    initialized: !session.initializing,
                  ),
                ),
                (previous, next) {
                  if (previous == null ||
                      !previous.initialized ||
                      previous == next) {
                    return;
                  }
                  details.revokeAccess();
                  final route = ModalRoute.of(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted && route != null && route.isActive) {
                      final navigator = Navigator.of(context);
                      navigator.popUntil(
                        (candidate) => identical(candidate, route),
                      );
                      navigator.removeRoute(route);
                    }
                  });
                },
              );
              return TripDetailPage(
                work: widget.controller,
                id: trip.id,
                controller: details,
              );
            },
          ),
        ),
      );
    } finally {
      details.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final live = c.operations != null;
    final enabled = live
        ? c.canReadTrips && !c.coolingDown
        : c.tripData.data != null;
    final hasFilters =
        c.fromDate != null ||
        c.toDate != null ||
        c.payment != PaymentFilter.all ||
        c.tripSearch.isNotEmpty ||
        c.tripPhase != null;
    final records = c.visibleTrips;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 808),
        child: CustomScrollView(
          key: const PageStorageKey('trips-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverList.list(
                children: [
                  WorkspaceHeading(
                    'Trips',
                    'Your work, recorded.',
                    action: IconButton(
                      tooltip: 'Refresh trips',
                      onPressed: c.loadingTrips || c.coolingDown
                          ? null
                          : () => c.refreshTrips(),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      WorkspaceBadge(
                        widget.preview
                            ? 'Sample final-mile history'
                            : live
                            ? 'Your retained assignments'
                            : 'History scope unavailable',
                      ),
                      WorkspaceBadge(
                        live ? 'Manila assignment dates' : 'Philippine dates',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const ValueKey('trip-search'),
                    controller: search,
                    enabled: enabled,
                    onChanged: c.searchTrips,
                    maxLength: live ? 100 : null,
                    decoration: InputDecoration(
                      labelText: 'Search trips',
                      hintText: live
                          ? 'Tracking or order number'
                          : 'Parcel reference, recipient or address',
                      prefixIcon: const Icon(Icons.search_rounded),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (live) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final phase in <String?>[
                          null,
                          'pickup',
                          'final_mile',
                        ])
                          _FilterButton(
                            label: phase == null
                                ? 'All work'
                                : phase == 'pickup'
                                ? 'Pickup'
                                : 'Final mile',
                            selected: c.tripPhase == phase,
                            key: ValueKey('trip-phase-$phase'),
                            onPressed: enabled
                                ? () => c.filterTripPhase(phase)
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final filter in PaymentFilter.values)
                        _FilterButton(
                          key: ValueKey('trip-payment-${filter.name}'),
                          label: switch (filter) {
                            PaymentFilter.all => 'All payments',
                            PaymentFilter.cod => 'COD',
                            PaymentFilter.prepaid =>
                              live ? 'Non-COD' : 'Prepaid',
                          },
                          selected: c.payment == filter,
                          onPressed: enabled
                              ? () => c.filterPayment(filter)
                              : null,
                        ),
                      OutlinedButton.icon(
                        key: const ValueKey('trip-date-filter'),
                        onPressed: enabled ? dates : null,
                        icon: const Icon(Icons.date_range_outlined, size: 18),
                        label: Text(
                          c.fromDate == null && c.toDate == null
                              ? 'Date range'
                              : '${c.fromDate == null ? 'Any start' : calendarDateLabel(c.fromDate!)} – ${c.toDate == null ? 'Any end' : calendarDateLabel(c.toDate!)}',
                        ),
                      ),
                      if (hasFilters)
                        TextButton(
                          onPressed: clear,
                          child: const Text('Clear filters'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FeatureStateView<List<RiderTrip>>(
                    data: c.tripData,
                    icon: Icons.route_outlined,
                    title: 'Trips',
                    onRetry: () => c.refreshTrips(),
                    website: RiderWebsitePage.trips,
                    ready: (all) => records.isEmpty
                        ? WorkspaceEmpty(
                            hasFilters
                                ? 'No trips match these filters'
                                : 'No recorded trips',
                            hasFilters
                                ? 'Try another reference, payment type or date range.'
                                : 'Your assigned pickup and final-mile records will appear here.',
                            onClear: hasFilters ? clear : null,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            if (c.tripData.data != null && records.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: records.length,
                  itemBuilder: (context, i) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (i == 0 ||
                          dayLabel(records[i].recordedAt) !=
                              dayLabel(records[i - 1].recordedAt))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            dayLabel(records[i].recordedAt),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      _TripCard(
                        trip: records[i],
                        onTap: () => openTrip(records[i]),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList.list(
                  children: [
                    Text(
                      live
                          ? 'Showing ${records.length} of ${c.retainedTrips?.total ?? records.length} retained assignments'
                          : 'Showing ${c.tripPage * WorkspaceController.pageSize + 1}–${c.tripPage * WorkspaceController.pageSize + records.length} of ${c.filteredTrips.length} matching records',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (!live)
                          OutlinedButton.icon(
                            key: const ValueKey('trips-previous'),
                            onPressed: c.tripPage > 0
                                ? c.previousTripPage
                                : null,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                            label: const Text('Previous'),
                          ),
                        if (!live || c.hasNextTripPage)
                          OutlinedButton.icon(
                            key: const ValueKey('trips-next'),
                            onPressed:
                                c.hasNextTripPage &&
                                    !c.loadingTrips &&
                                    !c.coolingDown
                                ? c.nextTripPage
                                : null,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            label: Text(live ? 'Load more' : 'Next'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                48 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: const SliverToBoxAdapter(
                child: Text(
                  'A delivery record is separate from buyer receipt, cash remittance and rider earnings.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: RiderPressFeedback(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: selected
              ? RiderColors.rose
              : RiderColors.neumorphicSurface,
          foregroundColor: selected ? RiderColors.accentText : RiderColors.ink,
        ),
        child: Text(label),
      ),
    ),
  );
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});
  final RiderTrip trip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => WorkspacePanel(
    padding: EdgeInsets.zero,
    child: RiderPressFeedback(
      child: InkWell(
        key: ValueKey('trip-${trip.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: RiderColors.rose,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.route_outlined,
                      size: 22,
                      color: RiderColors.accentText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.operation == null
                              ? trip.recipient
                              : trip.tracking,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trip.operation == null
                              ? trip.tracking
                              : '${trip.operation!.phase == 'pickup' ? 'Pickup' : 'Final mile'} · ${trip.operation!.order}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: RiderColors.muted,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (trip.operation == null || trip.operation!.address != null)
                Text(
                  trip.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (trip.operation?.collectedCents != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Recorded collection: ${exactPesos(trip.operation!.collectedCents!)}',
                ),
              ],
              if (trip.operation?.earnings.available == true) ...[
                const SizedBox(height: 8),
                Text(
                  'Released earnings: ${exactPesos(trip.operation!.earnings.confirmed!)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: RiderColors.accentText,
                  ),
                ),
                if (trip.operation!.earnings.pending! > BigInt.zero)
                  Text(
                    'Pending earnings: ${exactPesos(trip.operation!.earnings.pending!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  WorkspaceBadge(
                    trip.outcome,
                    accent: trip.outcome == 'Delivered',
                  ),
                  WorkspaceBadge(
                    trip.payment == PaymentFilter.cod
                        ? 'COD record'
                        : trip.operation == null
                        ? 'Prepaid'
                        : 'Recorded non-COD',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${trip.operation == null ? 'Recorded' : 'Assigned'} at ${timeLabel(trip.recordedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TripDetails extends StatelessWidget {
  const _TripDetails({required this.trip, required this.preview});
  final RiderTrip trip;
  final bool preview;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Trip details',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          WorkspacePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WorkspaceBadge(trip.outcome, accent: true),
                const SizedBox(height: 16),
                SelectableText(
                  trip.tracking,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  trip.recipient,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(trip.address),
                const SizedBox(height: 16),
                Text(
                  'Final-mile record · ${dayLabel(trip.recordedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (trip.cashCentavos != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Recorded collection: ${pesos(trip.cashCentavos!)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 16),
                RiderPressFeedback(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(
                        ClipboardData(text: trip.tracking),
                      );
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Parcel reference copied.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy reference'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recorded journey',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          for (final checkpoint in trip.checkpoints)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.radio_button_checked_rounded,
                    size: 18,
                    color: RiderColors.accentText,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checkpoint.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          checkpoint.recordedAt == null
                              ? 'Time not recorded'
                              : '${dayLabel(checkpoint.recordedAt!)} · ${timeLabel(checkpoint.recordedAt!)}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(
            preview
                ? 'Sample history only. No proof, buyer receipt, remittance or payout is confirmed by this preview.'
                : 'This journey records delivery events. Buyer receipt and cash reconciliation are separate records.',
          ),
          const SizedBox(height: 20),
          RiderPressFeedback(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to trips'),
            ),
          ),
        ],
      ),
    ),
  );
}
