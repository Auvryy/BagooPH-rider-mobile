import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ui/rider_surfaces.dart';

import '../../home/data/operations_models.dart';
import '../../home/presentation/stop_guidance.dart';
import '../data/route_geometry.dart';
import 'navigation_controller.dart';
import 'navigation_providers.dart';

class NavigationControls extends StatefulWidget {
  const NavigationControls({
    super.key,
    required this.task,
    required this.navigation,
    this.enabled = true,
    this.revalidateTask,
    this.launchDirections,
  });
  final OperationTask task;
  final NavigationController navigation;
  final bool enabled;
  final Future<OperationTask?> Function()? revalidateTask;
  final Future<bool> Function(Uri)? launchDirections;
  @override
  State<NavigationControls> createState() => _NavigationControlsState();
}

class _NavigationControlsState extends State<NavigationControls> {
  final _latitude = TextEditingController(),
      _longitude = TextEditingController();
  NavigationProfile? _profile;
  String? _error;
  bool _checking = false;
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
      final enabled = widget.enabled && !_checking && !nav.starting;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!coords)
            const Text(
              'No coordinates are saved for this stop. Use the server address.',
            ),
          if (coords) ...[
            DropdownButtonFormField<NavigationProfile>(
              isExpanded: true,
              initialValue: _profile,
              decoration: const InputDecoration(
                labelText: 'Navigation profile',
                helperText: 'Choose only if the registered vehicle is unknown.',
                helperMaxLines: 3,
              ),
              items: [
                for (final profile in NavigationProfile.values)
                  DropdownMenuItem(value: profile, child: Text(profile.label)),
              ],
              onChanged: enabled
                  ? (value) => setState(() => _profile = value)
                  : null,
            ),
            if (nav.manual) ...[
              const SizedBox(height: 12),
              const Text('Manual preview origin · Linux does not track GPS'),
              TextField(
                controller: _latitude,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Origin latitude'),
              ),
              TextField(
                controller: _longitude,
                enabled: enabled,
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
              key: const ValueKey('stop-navigate'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: enabled
                  ? () async {
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
                      final profile = _profile;
                      var selection = widget.task;
                      setState(() {
                        _error = null;
                        _checking = true;
                      });
                      if (widget.revalidateTask != null) {
                        final fresh = await widget.revalidateTask!();
                        if (!mounted) return;
                        if (fresh == null) {
                          setState(() {
                            _checking = false;
                            _error = 'Review or refresh the current stop before navigating.';
                          });
                          return;
                        }
                        selection = fresh;
                      }
                      await nav.start(
                        selection,
                        chosenProfile: profile,
                        manualOrigin: origin,
                      );
                      if (mounted) setState(() => _checking = false);
                    }
                  : null,
              child: Text(
                nav.starting
                    ? 'Starting…'
                    : _checking
                    ? 'Checking stop…'
                    : 'Navigate',
              ),
            ),
          ],
          if (_error != null) Text(_error!),
          if (nav.message != null) Text(nav.message!),
          if (nav.active || nav.starting || nav.paused)
            OutlinedButton(
              key: const ValueKey('stop-navigation-stop'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: nav.stop,
              child: const Text('Stop navigation'),
            ),
          if (stop.address?.trim().isNotEmpty == true || coords)
            TextButton.icon(
              key: const ValueKey('stop-external-directions'),
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.directions_outlined),
              label: const Text('External directions'),
              onPressed: !enabled
                  ? null
                  : () async {
                      final reviewed = widget.task;
                      setState(() {
                        _checking = true;
                        _error = null;
                      });
                      var authorized = false;
                      try {
                        final refreshed = widget.revalidateTask == null
                            ? await nav.authorize(reviewed.id)
                            : await widget.revalidateTask!();
                        if (!mounted) return;
                        if (refreshed == null || refreshed.preview) {
                          setState(
                            () => _error = 'Review or refresh the current stop before opening directions.',
                          );
                          return;
                        }
                        if (!sameReviewedStop(reviewed, refreshed)) {
                          setState(
                            () => _error = 'The stop changed. Review its current details before opening directions.',
                          );
                          return;
                        }
                        final currentStop = refreshed.stop;
                        final target =
                            currentStop.latitude != null &&
                                currentStop.longitude != null
                            ? '${currentStop.latitude},${currentStop.longitude}'
                            : currentStop.address;
                        if (target == null || target.trim().isEmpty) {
                          setState(
                            () => _error =
                                'This stop has no address or coordinates.',
                          );
                          return;
                        }
                        final uri = Uri.https('www.google.com', '/maps/dir/', {
                          'api': '1',
                          'destination': target,
                        });
                        authorized = true;
                        final ok = widget.launchDirections == null
                            ? await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              )
                            : await widget.launchDirections!(uri);
                        if (mounted && !ok) {
                          setState(
                            () => _error = 'Could not open external directions. Use the stop address.',
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          setState(
                            () => _error = authorized
                                ? 'Could not open external directions. Use the stop address.'
                                : 'Revalidate this task before opening external directions.',
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _checking = false);
                      }
                    },
            ),
        ],
      );
    },
  );
}

class NavigationBanner extends ConsumerWidget {
  const NavigationBanner({super.key, this.onRevalidated});
  final ValueChanged<OperationTask>? onRevalidated;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    return ListenableBuilder(
      listenable: nav,
      builder: (context, _) => !nav.active && !nav.starting && !nav.paused
          ? const SizedBox.shrink()
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    ((MediaQuery.sizeOf(context).height -
                                MediaQuery.viewInsetsOf(context).bottom) *
                            .25)
                        .clamp(64.0, 160.0),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: RiderSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (nav.paused) ...[
                          const Text(
                            'Navigation paused',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            nav.message ??
                                'Revalidate your task before navigating again.',
                          ),
                        ],
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (!nav.paused)
                              Text(
                                nav.manual
                                    ? 'Manual route preview'
                                    : 'Navigation active',
                              ),
                            if (nav.paused)
                              TextButton(
                                key: const ValueKey('navigation-revalidate'),
                                onPressed: nav.revalidating
                                    ? null
                                    : () async {
                                        final task = await nav
                                            .revalidatePausedTask();
                                        if (context.mounted && task != null) {
                                          onRevalidated?.call(task);
                                        }
                                      },
                                child: Text(
                                  nav.revalidating
                                      ? 'Checking task…'
                                      : 'Revalidate task',
                                ),
                              ),
                            if (!nav.paused)
                              TextButton(
                                onPressed: nav.calculating
                                    ? null
                                    : nav.refreshRoute,
                                child: const Text('Refresh route'),
                              ),
                            FilledButton(
                              onPressed: nav.stop,
                              child: Text(
                                nav.paused ? 'Dismiss' : 'Stop navigation',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
