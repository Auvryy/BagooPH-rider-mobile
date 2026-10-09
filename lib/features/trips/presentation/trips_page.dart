import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../core/platform/rider_website.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key, required this.controller, required this.preview});
  final WorkspaceController controller;
  final bool preview;
  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void clear() {
    search.clear();
    widget.controller.searchTrips('');
    widget.controller.filterPayment(PaymentFilter.all);
    widget.controller.filterDates(null, null);
  }

  Future<void> dates() async {
    final controller = widget.controller;
    final now = manilaTime(DateTime.now());
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: controller.fromDate == null
          ? null
          : DateTimeRange(start: controller.fromDate!, end: controller.toDate!),
    );
    if (range != null && mounted) {
      controller.filterDates(range.start, range.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final ready = c.tripData.data != null;
    return WorkspaceBody(
      storageKey: 'trips-scroll',
      children: [
        WorkspaceHeading(
          'Trips',
          'Your recorded journeys, one parcel at a time.',
          action: IconButton(
            tooltip: 'Refresh trips',
            onPressed: c.refreshTrips,
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
                  : 'History scope unavailable',
            ),
            const WorkspaceBadge('Philippine dates'),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('trip-search'),
          controller: search,
          enabled: ready,
          onChanged: c.searchTrips,
          decoration: const InputDecoration(
            labelText: 'Search trips',
            hintText: 'Parcel reference, recipient or address',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in PaymentFilter.values)
              Semantics(
                selected: c.payment == filter,
                child: OutlinedButton(
                  key: ValueKey('trip-payment-${filter.name}'),
                  onPressed: ready ? () => c.filterPayment(filter) : null,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: c.payment == filter
                        ? RiderColors.rose
                        : Colors.white,
                  ),
                  child: Text(switch (filter) {
                    PaymentFilter.all => 'All payments',
                    PaymentFilter.cod => 'COD',
                    PaymentFilter.prepaid => 'Prepaid',
                  }),
                ),
              ),
            OutlinedButton.icon(
              key: const ValueKey('trip-date-filter'),
              onPressed: ready ? dates : null,
              icon: const Icon(Icons.date_range_outlined, size: 18),
              label: Text(
                c.fromDate == null
                    ? 'Date range'
                    : '${calendarDateLabel(c.fromDate!)} – ${calendarDateLabel(c.toDate!)}',
              ),
            ),
            if (c.fromDate != null ||
                c.payment != PaymentFilter.all ||
                c.tripSearch.isNotEmpty)
              TextButton(onPressed: clear, child: const Text('Clear filters')),
          ],
        ),
        const SizedBox(height: 24),
        FeatureStateView<List<RiderTrip>>(
          data: c.tripData,
          icon: Icons.route_outlined,
          title: 'Trips',
          onRetry: c.refreshTrips,
          website: RiderWebsitePage.trips,
          ready: (all) {
            final records = c.visibleTrips;
            if (records.isEmpty) {
              return WorkspaceEmpty(
                all.isEmpty
                    ? 'No recorded trips'
                    : 'No trips match these filters',
                all.isEmpty
                    ? 'Recorded journeys appear here within the history supplied for your account.'
                    : 'Try another reference, payment type or date range.',
                onClear: all.isEmpty ? null : clear,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < records.length; i++) ...[
                  if (i == 0 ||
                      dayLabel(records[i].recordedAt) !=
                          dayLabel(records[i - 1].recordedAt))
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 12),
                      child: Text(
                        dayLabel(records[i].recordedAt),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  WorkspacePanel(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      key: ValueKey('trip-${records[i].id}'),
                      borderRadius: BorderRadius.circular(RiderRadii.media),
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        sheetAnimationStyle: RiderMotion.sheetStyle(context),
                        isScrollControlled: true,
                        showDragHandle: true,
                        backgroundColor: RiderColors.canvas,
                        builder: (_) => _TripDetails(
                          trip: records[i],
                          preview: widget.preview,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    records[i].tracking,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                WorkspaceBadge(
                                  records[i].outcome,
                                  accent: records[i].outcome == 'Delivered',
                                ),
                                WorkspaceBadge(
                                  records[i].payment == PaymentFilter.cod
                                      ? 'COD record'
                                      : 'Prepaid',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              records[i].recipient,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(records[i].address),
                            const SizedBox(height: 12),
                            Text(
                              'Recorded at ${timeLabel(records[i].recordedAt)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
                Text(
                  'Showing ${c.tripPage * WorkspaceController.pageSize + 1}–${c.tripPage * WorkspaceController.pageSize + records.length} of ${c.filteredTrips.length} matching records',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('trips-previous'),
                      onPressed: c.tripPage > 0 ? c.previousTripPage : null,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Previous'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('trips-next'),
                      onPressed: c.hasNextTripPage ? c.nextTripPage : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'A delivery record is separate from buyer receipt, cash remittance and rider earnings.',
        ),
      ],
    );
  }
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
                Text(trip.recipient),
                const SizedBox(height: 8),
                Text(trip.address),
                const SizedBox(height: 16),
                Text('Final-mile record · ${dayLabel(trip.recordedAt)}'),
                if (trip.cashCentavos != null) ...[
                  const SizedBox(height: 12),
                  Text('Recorded collection: ${pesos(trip.cashCentavos!)}'),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(ClipboardData(text: trip.tracking));
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Parcel reference copied.')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy reference'),
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
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to trips'),
          ),
        ],
      ),
    ),
  );
}
