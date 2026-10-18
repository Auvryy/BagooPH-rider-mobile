import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../home/data/operations_models.dart';
import '../data/parcel_location_labels.dart';

class ParcelFinderCard extends StatefulWidget {
  const ParcelFinderCard({
    super.key,
    required this.task,
    required this.location,
    required this.suffix,
    required this.enabled,
    required this.save,
  });

  final OperationTask task;
  final ParcelSlot? location;
  final String suffix;
  final bool enabled;
  final Future<String?> Function(ParcelSlot?) save;

  @override
  State<ParcelFinderCard> createState() => _ParcelFinderCardState();
}

class _ParcelFinderCardState extends State<ParcelFinderCard> {
  bool _editing = false, _saving = false;
  String? _notice;

  @override
  void didUpdateWidget(ParcelFinderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id ||
        oldWidget.task.assignmentReference != widget.task.assignmentReference ||
        oldWidget.task.tracking != widget.task.tracking) {
      _editing = false;
      _notice = null;
    }
  }

  Future<void> _save(ParcelSlot? slot) async {
    if (_saving || !widget.enabled) return;
    final original = widget.task;
    setState(() {
      _saving = true;
      _notice = null;
    });
    try {
      final error = await widget.save(slot);
      if (!mounted ||
          original.id != widget.task.id ||
          original.assignmentReference != widget.task.assignmentReference) {
        return;
      }
      setState(() {
        _notice =
            error ??
            (slot == null
                ? 'Location label cleared.'
                : '${slot.label} saved for this session.');
        if (error == null) _editing = false;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final canEdit = widget.enabled && !_saving;
    final slot = widget.location;
    return RiderSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const ExcludeSemantics(
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: RiderColors.accentText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Parcel Finder', style: theme.titleLarge)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Session only · clears on sign-out or app restart',
            style: theme.bodySmall,
          ),
          const SizedBox(height: 20),
          Text('Tracking ends in', style: theme.bodySmall),
          const SizedBox(height: 4),
          Semantics(
            label:
                'Tracking ends in ${widget.suffix}. Full tracking number ${widget.task.tracking}.',
            excludeSemantics: true,
            child: Text(
              widget.suffix,
              key: const ValueKey('parcel-finder-suffix'),
              style: theme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slot == null
                ? 'Location not set'
                : widget.task.heldByMe
                ? slot.label
                : 'Planned: ${slot.label}',
            key: const ValueKey('parcel-finder-location'),
            style: theme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'A personal label, separate from recorded custody.',
            style: theme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (_saving)
            Semantics(
              liveRegion: true,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Verifying this parcel…'),
              ),
            )
          else if (!_editing)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const ValueKey('parcel-finder-edit'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: canEdit
                    ? () => setState(() => _editing = true)
                    : null,
                icon: const Icon(Icons.place_outlined),
                label: Text(
                  slot != null
                      ? 'Change location'
                      : widget.task.heldByMe
                      ? 'Set location'
                      : 'Plan location',
                ),
              ),
            ),
          if (_editing) ...[
            _picker(canEdit),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (slot != null)
                  TextButton.icon(
                    key: const ValueKey('parcel-finder-clear'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: canEdit ? () => _save(null) : null,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Clear location'),
                  ),
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: _saving
                      ? null
                      : () => setState(() => _editing = false),
                  child: const Text('Close picker'),
                ),
              ],
            ),
          ],
          if (!widget.enabled && !_saving) ...[
            const SizedBox(height: 8),
            const Text('Refresh this owned stop to manage its location label.'),
          ],
          if (_notice != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                _notice!,
                key: const ValueKey('parcel-finder-notice'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _picker(bool enabled) => LayoutBuilder(
    builder: (context, constraints) {
      final singleColumn =
          constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1) <
          180;
      Widget pair(List<ParcelSlot> slots) => singleColumn
          ? Column(
              children: [
                for (final slot in slots)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _slot(slot, enabled),
                  ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _slot(slots[0], enabled)),
                const SizedBox(width: 12),
                Expanded(child: _slot(slots[1], enabled)),
              ],
            );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: RiderColors.canvas,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RiderColors.border),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Top box',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                pair([ParcelSlot.topBoxLeft, ParcelSlot.topBoxRight]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          pair([ParcelSlot.bag1, ParcelSlot.bag2]),
        ],
      );
    },
  );

  Widget _slot(ParcelSlot slot, bool enabled) {
    final selected = widget.location == slot;
    final short = switch (slot) {
      ParcelSlot.topBoxLeft => 'Left',
      ParcelSlot.topBoxRight => 'Right',
      _ => slot.label,
    };
    return OutlinedButton(
      key: ValueKey('parcel-slot-${slot.name}'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 80),
        padding: const EdgeInsets.all(12),
        backgroundColor: selected ? RiderColors.rose : RiderColors.surface,
        side: BorderSide(
          color: selected ? RiderColors.accent : RiderColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: enabled ? () => _save(slot) : null,
      child: Semantics(
        label: slot.label,
        selected: selected,
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : slot == ParcelSlot.bag1 || slot == ParcelSlot.bag2
                  ? Icons.backpack_outlined
                  : Icons.inventory_2_outlined,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(short, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
