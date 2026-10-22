import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../navigation/data/philippines_map_region.dart';

class HomeMapOriginDialog extends StatefulWidget {
  const HomeMapOriginDialog({super.key, required this.region, this.initial});
  final PhilippinesMapRegion region;
  final LatLng? initial;
  @override
  State<HomeMapOriginDialog> createState() => _HomeMapOriginDialogState();
}

class _HomeMapOriginDialogState extends State<HomeMapOriginDialog> {
  late final _latitude = TextEditingController(
    text: widget.initial?.latitude.toString(),
  );
  late final _longitude = TextEditingController(
    text: widget.initial?.longitude.toString(),
  );
  String? _error;

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Preview an area'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Manual preview origin only. This does not locate the rider or start navigation.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _latitude,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: const InputDecoration(labelText: 'Preview latitude'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _longitude,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: const InputDecoration(labelText: 'Preview longitude'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final lat = double.tryParse(_latitude.text.trim());
          final lng = double.tryParse(_longitude.text.trim());
          final point = lat == null || lng == null ? null : LatLng(lat, lng);
          if (point == null || !widget.region.containsLand(point)) {
            setState(
              () => _error = 'Enter valid coordinates on the Philippines map.',
            );
            return;
          }
          Navigator.pop(context, point);
        },
        child: const Text('Show area'),
      ),
    ],
  );
}
