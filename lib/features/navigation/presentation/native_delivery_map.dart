import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../data/saved_delivery_stop.dart';

final deliveryRoadPointsProvider = FutureProvider<List<LatLng>>((ref) async {
  final data = jsonDecode(
    await rootBundle.loadString('assets/maps/rider-delivery-sample.json'),
  ) as Map;
  final points = (data['coordinates'] as List)
      .map((value) {
        final pair = value as List;
        final latitude = (pair[0] as num).toDouble(),
            longitude = (pair[1] as num).toDouble();
        if (!latitude.isFinite ||
            !longitude.isFinite ||
            latitude.abs() > 85 ||
            longitude.abs() > 180) {
          throw const FormatException('Invalid sample road coordinates.');
        }
        return LatLng(latitude, longitude);
      })
      .toList(growable: false);
  if (points.length < 2) {
    throw const FormatException('The sample road path is incomplete.');
  }
  return points;
});

// Create a provider for each map mount: TileLayer owns and disposes its provider.
final deliveryTilesProvider = Provider<TileProvider Function()>(
  (ref) => NetworkTileProvider.new,
);

// A native Flutter surface scales and clips with Device Preview. A GTK WebView
// is a separate native overlay and cannot reliably share its simulated viewport.
class NativeDeliveryMap extends ConsumerStatefulWidget {
  const NativeDeliveryMap({super.key, this.stop});
  final SavedDeliveryStop? stop;
  @override
  ConsumerState<NativeDeliveryMap> createState() => _NativeDeliveryMapState();
}

class _NativeDeliveryMapState extends ConsumerState<NativeDeliveryMap> {
  final _controller = MapController();
  bool _ready = false;
  bool _tilesFailed = false;
  int _attempt = 0;
  TileProvider? _tiles;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fit(List<LatLng> points) {
    if (widget.stop != null) {
      _controller.move(points.first, 16);
      return;
    }
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(48),
        maxZoom: 16,
      ),
    );
  }

  void _tileError() {
    if (_tilesFailed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_tilesFailed) setState(() => _tilesFailed = true);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Widget _pin(String label, Color color) => Tooltip(
    message: label,
    child: Semantics(
      label: label,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) =>
      (widget.stop == null
              ? ref.watch(deliveryRoadPointsProvider)
              : AsyncData<List<LatLng>>([
                  LatLng(widget.stop!.latitude, widget.stop!.longitude),
                ]))
          .when(
            loading: () => const Center(child: Text('Loading street map…')),
            error: (_, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('The sample map could not open.'),
                  TextButton(
                    onPressed: () => ref.invalidate(deliveryRoadPointsProvider),
                    child: const Text('Retry map'),
                  ),
                ],
              ),
            ),
            data: (points) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _controller,
                          options: MapOptions(
                            initialCenter: points.first,
                            initialZoom: widget.stop == null ? 13 : 16,
                            initialCameraFit: widget.stop == null
                                ? CameraFit.coordinates(
                                    coordinates: points,
                                    padding: const EdgeInsets.all(48),
                                    maxZoom: 16,
                                  )
                                : null,
                            minZoom: 2,
                            maxZoom: 19,
                            backgroundColor: const Color(0xFFF2F1ED),
                            interactionOptions: const InteractionOptions(
                              flags:
                                  InteractiveFlag.drag |
                                  InteractiveFlag.pinchZoom |
                                  InteractiveFlag.doubleTapZoom,
                            ),
                            onMapReady: () {
                              if (mounted) setState(() => _ready = true);
                            },
                          ),
                          children: [
                            TileLayer(
                              key: ValueKey(_attempt),
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.bagoo_rider_mobile',
                              maxNativeZoom: 19,
                              tileProvider: _tiles ??= ref.read(
                                deliveryTilesProvider,
                              )(),
                              errorTileCallback: (_, _, _) => _tileError(),
                            ),
                            if (widget.stop == null)
                              PolylineLayer(
                                simplificationTolerance: 0,
                                polylines: [
                                  Polyline(
                                    points: points,
                                    strokeWidth: 5,
                                    borderStrokeWidth: 2,
                                    color: const Color(0xFFE00D42),
                                    borderColor: Colors.white,
                                    strokeCap: StrokeCap.round,
                                    strokeJoin: StrokeJoin.round,
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                if (widget.stop == null)
                                  Marker(
                                    point: points.first,
                                    width: 22,
                                    height: 22,
                                    child: _pin(
                                      'Sample rider',
                                      const Color(0xFF18181B),
                                    ),
                                  ),
                                Marker(
                                  point: points.last,
                                  width: 22,
                                  height: 22,
                                  child: _pin(
                                    widget.stop?.label ??
                                        'Sample delivery point',
                                    const Color(0xFFE00D42),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          right: 8,
                          bottom: 42,
                          child: Material(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: RiderColors.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Zoom in',
                                  onPressed: !_ready
                                      ? null
                                      : () => _controller.move(
                                          _controller.camera.center,
                                          (_controller.camera.zoom + 1).clamp(
                                            2,
                                            19,
                                          ),
                                        ),
                                  icon: const Icon(Icons.add),
                                ),
                                IconButton(
                                  tooltip: 'Zoom out',
                                  onPressed: !_ready
                                      ? null
                                      : () => _controller.move(
                                          _controller.camera.center,
                                          (_controller.camera.zoom - 1).clamp(
                                            2,
                                            19,
                                          ),
                                        ),
                                  icon: const Icon(Icons.remove),
                                ),
                                IconButton(
                                  tooltip: widget.stop == null
                                      ? 'Show sample route'
                                      : 'Recenter current stop',
                                  onPressed: !_ready
                                      ? null
                                      : () => _fit(points),
                                  icon: const Icon(Icons.route_outlined),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: RiderColors.ink,
                                minimumSize: const Size(0, 28),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                textStyle: const TextStyle(fontSize: 10),
                              ),
                              onPressed: () => launchUrl(
                                Uri.parse(
                                  'https://www.openstreetmap.org/copyright',
                                ),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: const Text('© OpenStreetMap contributors'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_tilesFailed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.stop == null
                              ? 'Street tiles could not load. The sample road line remains available.'
                              : 'Street tiles could not load. Use the recorded stop address.',
                          style: TextStyle(
                            fontSize: 12,
                            color: RiderColors.muted,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _tilesFailed = false;
                            _tiles = null;
                            _attempt++;
                          }),
                          child: const Text('Retry map'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
}
