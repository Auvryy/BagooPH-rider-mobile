import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../home/data/operations_models.dart';
import '../data/route_geometry.dart';
import 'navigation_controller.dart';
import 'navigation_providers.dart';

class NavigationControls extends StatefulWidget {
  const NavigationControls({
    super.key,
    required this.task,
    required this.navigation,
  });
  final OperationTask task;
  final NavigationController navigation;
  @override
  State<NavigationControls> createState() => _NavigationControlsState();
}

class _NavigationControlsState extends State<NavigationControls> {
  final _latitude = TextEditingController(),
      _longitude = TextEditingController();
  NavigationProfile? _profile;
  String? _error;
  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.navigation,
    builder: (context, _) {
      final nav = widget.navigation, stop = widget.task.stop;
      final coords = stop.latitude != null && stop.longitude != null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!coords)
            const Text(
              'No coordinates are saved for this stop. Use the server address.',
            ),
          if (coords) ...[
            DropdownButtonFormField<NavigationProfile>(
              initialValue: _profile,
              decoration: const InputDecoration(
                labelText: 'Navigation profile (if vehicle is unknown)',
              ),
              items: [
                for (final profile in NavigationProfile.values)
                  DropdownMenuItem(value: profile, child: Text(profile.label)),
              ],
              onChanged: nav.starting
                  ? null
                  : (value) => setState(() => _profile = value),
            ),
            if (nav.manual) ...[
              const SizedBox(height: 12),
              const Text('Manual preview origin · Linux does not track GPS'),
              TextField(
                controller: _latitude,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Origin latitude'),
              ),
              TextField(
                controller: _longitude,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Origin longitude',
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: nav.starting
                  ? null
                  : () async {
                      LatLng? origin;
                      if (nav.manual) {
                        final lat = double.tryParse(_latitude.text.trim()),
                            lon = double.tryParse(_longitude.text.trim());
                        if (lat == null ||
                            lon == null ||
                            !validPoint(LatLng(lat, lon))) {
                          setState(
                            () => _error =
                                'Enter valid origin latitude and longitude.',
                          );
                          return;
                        }
                        origin = LatLng(lat, lon);
                      }
                      setState(() => _error = null);
                      await nav.start(
                        widget.task,
                        chosenProfile: _profile,
                        manualOrigin: origin,
                      );
                    },
              child: Text(nav.starting ? 'Starting…' : 'Navigate'),
            ),
          ],
          if (_error != null) Text(_error!),
          if (nav.message != null) Text(nav.message!),
          if (nav.active)
            OutlinedButton(
              onPressed: nav.stop,
              child: const Text('Stop navigation'),
            ),
          if (stop.address?.trim().isNotEmpty == true || coords)
            TextButton.icon(
              icon: const Icon(Icons.directions_outlined),
              label: const Text('External directions'),
              onPressed: () async {
                try {
                  final refreshed = await nav.authorize(widget.task.id);
                  if (!mounted || refreshed.preview) return;
                  final currentStop = refreshed.stop;
                  final target =
                      currentStop.latitude != null &&
                          currentStop.longitude != null
                      ? '${currentStop.latitude},${currentStop.longitude}'
                      : currentStop.address;
                  if (target == null || target.trim().isEmpty) {
                    setState(
                      () => _error = 'This stop has no address or coordinates.',
                    );
                    return;
                  }
                  final uri = Uri.https('www.google.com', '/maps/dir/', {
                    'api': '1',
                    'destination': target,
                  });
                  final ok = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (mounted && !ok) {
                    setState(
                      () => _error = 'Could not open external directions. Use the stop address.',
                    );
                  }
                } catch (_) {
                  if (mounted) {
                    setState(
                      () => _error = 'Revalidate this task before opening external directions.',
                    );
                  }
                }
              },
            ),
        ],
      );
    },
  );
}

class NavigationBanner extends ConsumerWidget {
  const NavigationBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    return ListenableBuilder(
      listenable: nav,
      builder: (context, _) => !nav.active && !nav.starting
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    nav.manual ? 'Manual route preview' : 'Navigation active',
                  ),
                  TextButton(
                    onPressed: nav.calculating ? null : nav.refreshRoute,
                    child: const Text('Refresh route'),
                  ),
                  FilledButton(
                    onPressed: nav.stop,
                    child: const Text('Stop navigation'),
                  ),
                ],
              ),
            ),
    );
  }
}
