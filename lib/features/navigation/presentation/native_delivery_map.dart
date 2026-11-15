import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../data/geoapify_client.dart';
import '../data/map_tile_source.dart';
import '../data/saved_delivery_stop.dart';
import '../data/route_geometry.dart';
import 'geoapify_tiles.dart';
import 'navigation_providers.dart';

const _defaultStandbyCenter = LatLng(14.5547, 121.0244);

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
final deliveryTilesProvider = Provider<TileProvider Function()>((ref) {
  final routes = ref.watch(roadRoutingProvider);
  if (routes is GeoapifyClient && routes.configured) {
    return () => GeoapifyTiles(
      routes,
      source: const MapTileSource(style: MapTileStyle.carto, retina: true),
      clipToPhilippines: true,
    );
  }
  return NetworkTileProvider.new;
});

// A native Flutter surface scales and clips with Device Preview and gives
// Android direct GPU map rendering with Geoapify tiles and caching.
class NativeDeliveryMap extends ConsumerStatefulWidget {
  const NativeDeliveryMap({
    super.key,
    this.stop,
    this.road,
    this.riderPoint,
    this.standby = false,
    this.recenterVersion = 0,
    this.onUserPan,
  });
  final SavedDeliveryStop? stop;
  final RoadRoute? road;
  final LatLng? riderPoint;
  final bool standby;
  final int recenterVersion;
  final VoidCallback? onUserPan;
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

  List<LatLng> _currentPoints() {
    if (widget.road != null) {
      return [
        if (widget.riderPoint != null) widget.riderPoint!,
        ...widget.road!.lines.expand((line) => line),
        if (widget.stop != null)
          LatLng(widget.stop!.latitude, widget.stop!.longitude),
      ];
    }
    if (widget.stop != null) {
      return [
        if (widget.riderPoint != null) widget.riderPoint!,
        LatLng(widget.stop!.latitude, widget.stop!.longitude),
      ];
    }
    if (widget.standby) {
      return [widget.riderPoint ?? _defaultStandbyCenter];
    }
    return const [];
  }

  @override
  void didUpdateWidget(covariant NativeDeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;
    final fitPoints = _currentPoints();
    if (fitPoints.isEmpty) return;
    if (widget.recenterVersion != oldWidget.recenterVersion ||
        (widget.road != oldWidget.road && widget.road != null) ||
        widget.stop != oldWidget.stop ||
        (widget.riderPoint != oldWidget.riderPoint &&
            widget.riderPoint != null &&
            widget.road == null)) {
      _fit(fitPoints);
    }
  }

  void _fit(List<LatLng> points) {
    if (widget.road != null) {
      final coords = [
        if (widget.riderPoint != null) widget.riderPoint!,
        ...widget.road!.lines.expand((line) => line),
        if (widget.stop != null)
          LatLng(widget.stop!.latitude, widget.stop!.longitude),
      ];
      _controller.fitCamera(
        CameraFit.coordinates(
          coordinates: coords,
          padding: const EdgeInsets.all(48),
          maxZoom: 16,
        ),
      );
      return;
    }
    if (widget.stop != null && points.length > 1) {
      _controller.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(48),
          maxZoom: 16,
        ),
      );
      return;
    }
    if (!widget.standby && widget.stop == null && points.length > 1) {
      _controller.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(48),
          maxZoom: 16,
        ),
      );
      return;
    }
    final zoom = widget.standby && widget.riderPoint == null ? 11.0 : 16.0;
    _controller.move(points.first, zoom);
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
  Widget build(BuildContext context) {
    final AsyncValue<List<LatLng>> pointsAsync;
    if (widget.stop != null) {
      pointsAsync = AsyncData<List<LatLng>>([
        if (widget.riderPoint != null) widget.riderPoint!,
        LatLng(widget.stop!.latitude, widget.stop!.longitude),
      ]);
    } else if (widget.standby) {
      pointsAsync = AsyncData<List<LatLng>>([
        widget.riderPoint ?? _defaultStandbyCenter,
      ]);
    } else {
      pointsAsync = ref.watch(deliveryRoadPointsProvider);
    }
    return pointsAsync.when(
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
                            initialZoom: widget.standby &&
                                    widget.stop == null &&
                                    widget.riderPoint == null
                                ? 11
                                : 16,
                            initialCameraFit: widget.road != null
                                ? CameraFit.coordinates(
                                    coordinates: [
                                      if (widget.riderPoint != null)
                                        widget.riderPoint!,
                                      ...widget.road!.lines.expand((line) => line),
                                      if (widget.stop != null)
                                        LatLng(
                                          widget.stop!.latitude,
                                          widget.stop!.longitude,
                                        ),
                                    ],
                                    padding: const EdgeInsets.all(48),
                                    maxZoom: 16,
                                  )
                                : ((widget.stop != null && points.length > 1) ||
                                      (!widget.standby &&
                                          widget.stop == null &&
                                          points.length > 1))
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
                            onPositionChanged: (_, hasGesture) {
                              if (hasGesture) widget.onUserPan?.call();
                            },
                            onMapReady: () {
                              if (mounted) setState(() => _ready = true);
                            },
                          ),
                          children: [
                            Builder(
                              builder: (_) {
                                final tiles = _tiles ??= ref.read(
                                  deliveryTilesProvider,
                                )();
                                return TileLayer(
                                  key: ValueKey(_attempt),
                                  urlTemplate: tiles is GeoapifyTiles
                                      ? null
                                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.bagoo_rider_mobile',
                                  maxNativeZoom: 19,
                                  tileProvider: tiles,
                                  errorTileCallback: (_, _, _) => _tileError(),
                                );
                              },
                            ),
                            if (widget.road != null || (!widget.standby && widget.stop == null))
                              PolylineLayer(
                                simplificationTolerance: 0,
                                polylines: [
                                  if (widget.road != null)
                                    for (final line in widget.road!.lines)
                                      Polyline(
                                        points: line,
                                        strokeWidth: 5,
                                        borderStrokeWidth: 2,
                                        color: const Color(0xFFE00D42),
                                        borderColor: Colors.white,
                                        strokeCap: StrokeCap.round,
                                        strokeJoin: StrokeJoin.round,
                                      )
                                  else
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
                                if ((widget.standby && widget.riderPoint != null) ||
                                    (!widget.standby && widget.stop == null) ||
                                    widget.riderPoint != null ||
                                    widget.road != null)
                                  Marker(
                                    point:
                                        widget.riderPoint ??
                                        widget.road?.lines.first.first ??
                                        points.first,
                                    width: 22,
                                    height: 22,
                                    child: _pin(
                                      widget.riderPoint != null
                                          ? 'Your location'
                                          : widget.road != null
                                          ? 'Route start'
                                          : 'Your location',
                                      const Color(0xFF18181B),
                                    ),
                                  ),
                                if (widget.stop != null || (!widget.standby && points.length > 1))
                                  Marker(
                                    point: widget.stop != null
                                        ? LatLng(
                                            widget.stop!.latitude,
                                            widget.stop!.longitude,
                                          )
                                        : points.last,
                                    width: 22,
                                    height: 22,
                                    child: _pin(
                                      widget.stop?.label ?? 'Delivery destination',
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
                                  tooltip: widget.standby
                                      ? 'Recenter your location'
                                      : widget.stop == null
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
                          widget.standby || widget.stop != null
                              ? 'Street tiles could not load. Use the recorded stop address.'
                              : 'Street tiles could not load. The sample road line remains available.',
                          style: TextStyle(
                            fontSize: 12,
                            color: RiderColors.muted,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final routes = ref.read(roadRoutingProvider);
                            if (routes is GeoapifyClient && routes.configured) {
                              routes.retryTiles();
                            }
                            setState(() {
                              _tilesFailed = false;
                              _tiles = null;
                              _attempt++;
                            });
                          },
                          child: const Text('Retry map'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
  }
}
