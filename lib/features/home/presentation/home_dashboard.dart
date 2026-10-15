import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../auth/data/account.dart';
import '../../navigation/data/geoapify_client.dart';
import '../../navigation/data/map_tile_source.dart';
import '../../navigation/data/philippines_map_region.dart';
import '../../navigation/data/route_geometry.dart';
import '../../navigation/presentation/geoapify_tiles.dart';
import '../../navigation/presentation/philippines_map_mask.dart';
import '../../navigation/presentation/navigation_controller.dart';
import '../../navigation/presentation/navigation_providers.dart';
import '../../workspace/data/workspace_models.dart';
import '../data/operations_repository.dart';
import '../data/operations_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import 'home_task_panel.dart';
import 'home_map_focus.dart';
import 'tasks_page.dart';
import 'work_summary.dart';
import '../../handover/presentation/handover_entry.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({
    super.key,
    required this.account,
    required this.controller,
    this.active = true,
  });
  final RiderAccount account;
  final WorkspaceController controller;
  final bool active;
  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  final _map = MapController();
  final _pageScroll = ScrollController();
  GeoapifyTiles? _tiles;
  GeoapifyClient? _tileClient;
  PhilippinesMapRegion? _region;
  bool _outlineFailed = false, _retinaTiles = false;
  MapTileSource get _tileSource =>
      MapTileSource(style: MapTileStyle.bright, retina: _retinaTiles);
  bool _ready = false, _wide = false, _mapVisible = false;
  int _mapEpoch = 0;
  int? _queuedCameraEpoch;
  int? _tileRevision;
  LatLng? _savedCenter;
  double? _savedZoom;
  double _savedRotation = 0;
  Size _mapSize = Size.zero;
  LatLng? _lastCameraPoint;
  String? _lastFocusKey;
  RoadRoute? _lastFocusRoad;
  @override
  void didUpdateWidget(HomeDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) _setMapVisible(false);
  }

  void _setMapVisible(bool visible) {
    if (_mapVisible == visible) return;
    _mapVisible = visible;
    _mapEpoch++;
    _ready = false;
    _tiles?.suspend();
    if (visible && _tileClient != null) _tiles = _newTiles(_tileClient!);
  }

  GeoapifyTiles _newTiles(GeoapifyClient client) =>
      GeoapifyTiles(client, source: _tileSource, clipToPhilippines: true);

  @override
  void dispose() {
    _tiles?.suspend();
    _pageScroll.dispose();
    _map.dispose();
    super.dispose();
  }

  OperationTask? _mapTask(RiderTask task) {
    final selected = widget.controller.selectedTask;
    return selected?.id == task.id ? selected : task.operation;
  }

  List<LatLng> get _queuePoints => [
    for (final t in widget.controller.visibleTasks)
      if (_mapTask(t)?.stop.latitude != null &&
          _mapTask(t)?.stop.longitude != null)
        if (HomeMapFocus.pointFor(_mapTask(t)) case final point?
            when _region?.containsLand(point) == true)
          point,
  ];
  List<OperationTask> get _queueTasks => widget.controller.visibleTasks
      .map(_mapTask)
      .whereType<OperationTask>()
      .toList(growable: false);
  HomeMapFocus _focus(NavigationController nav, {bool selectedOnly = false}) =>
      HomeMapFocus.resolve(
        region: _region!,
        navigatingTask: !selectedOnly && nav.active ? nav.task : null,
        fix: !selectedOnly && nav.active ? nav.fix : null,
        road: !selectedOnly && nav.active ? nav.road : null,
        selectedTask: widget.controller.selectedTask,
        queuedTasks: _queueTasks,
      );
  String? _stopKey(OperationTask? task) => task == null
      ? null
      : '${task.id}:${task.stop.kind}:${task.stop.latitude}:${task.stop.longitude}';
  void _moveTo(LatLng p, {double zoom = 15}) {
    if (!_ready || _mapSize.isEmpty || !PhilippinesMapRegion.inCameraArea(p)) {
      return;
    }
    _map.move(p, zoom);
  }

  void _fit(List<LatLng> points) {
    if (!_ready || _mapSize.isEmpty) return;
    if (points.isEmpty) {
      _map.fitCamera(
        CameraFit.bounds(
          bounds: PhilippinesMapRegion.cameraBounds,
          padding: const EdgeInsets.all(24),
          maxZoom: 6,
          minZoom: PhilippinesMapRegion.minimumZoom,
        ),
      );
      return;
    }
    if (points.length == 1) {
      _moveTo(points.first);
      return;
    }
    final top = (76.0).clamp(0.0, _mapSize.height * .2);
    final maxBottom = (_mapSize.height - top - 72).clamp(0.0, _mapSize.height);
    final bottom = 28.0.clamp(0.0, maxBottom);
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: EdgeInsets.fromLTRB(36, top, 36, bottom),
        maxZoom: 16,
        minZoom: PhilippinesMapRegion.minimumZoom,
      ),
    );
  }

  void _queueCamera(NavigationController nav) {
    if (!widget.active ||
        !_ready ||
        !_mapVisible ||
        _queuedCameraEpoch == _mapEpoch) {
      return;
    }
    final epoch = _mapEpoch;
    _queuedCameraEpoch = epoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_queuedCameraEpoch == epoch) _queuedCameraEpoch = null;
      if (!mounted || !widget.active || !_ready || epoch != _mapEpoch) return;
      if (!nav.following || _region == null) return;
      final focus = _focus(nav), fix = nav.fix?.point;
      final key = '${widget.controller.queue.name}:${focus.key}';
      if (key == _lastFocusKey &&
          fix == _lastCameraPoint &&
          identical(_lastFocusRoad, nav.road)) {
        return;
      }
      _lastFocusKey = key;
      _lastCameraPoint = fix;
      _lastFocusRoad = nav.road;
      _fit(focus.points);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _select(RiderTask task, NavigationController nav) async {
    final wasFollowing = nav.following;
    if (nav.task?.id != task.id) await nav.stop();
    if (!wasFollowing) nav.pan();
    await widget.controller.openTask(task);
    if (!mounted) return;
    if (nav.active &&
        widget.controller.selectedTask?.id == nav.task?.id &&
        _stopKey(widget.controller.selectedTask) != _stopKey(nav.task)) {
      await nav.checkAuthorization();
    }
    if (!mounted) return;
    final selected = widget.controller.selectedTask;
    if (selected != null && nav.following && _region != null) {
      _lastFocusKey = null;
      _queueCamera(nav);
    }
  }

  Widget _panel(NavigationController nav, {bool asSliver = false}) =>
      HomeTaskPanel(
        controller: widget.controller,
        asSliver: asSliver,
        onSelect: (task) => unawaited(_select(task, nav)),
        onDetails: (task) {
          final display = OperationsRepository.asRiderTask(task);
          TasksPage(
            account: widget.account,
            controller: widget.controller,
            preview: false,
            navigation: nav,
          ).openParcel(context, display);
        },
        onQueueChanged: (_) {
          _lastFocusKey = null;
        },
        onShowStop: () {
          nav.pan();
          final stop = widget.controller.selectedTask?.stop;
          if (stop?.latitude != null && stop?.longitude != null) {
            if (!_wide && _pageScroll.hasClients) {
              unawaited(
                _pageScroll.animateTo(
                  0,
                  duration: RiderMotion.reduced(context)
                      ? Duration.zero
                      : RiderMotion.sheet,
                  curve: Curves.easeOutCubic,
                ),
              );
            }
            if (_region != null) _fit(_focus(nav, selectedOnly: true).points);
          }
        },
      );
  @override
  Widget build(BuildContext context) {
    if (!widget.active || ModalRoute.isCurrentOf(context) == false) {
      _setMapVisible(false);
      return const SizedBox.shrink();
    }
    final nav = ref.watch(navigationProvider),
        geo = ref.watch(geoapifyProvider);
    final outline = ref.watch(philippinesMapRegionProvider);
    _region = outline.asData?.value;
    _outlineFailed = outline.hasError;
    return LayoutBuilder(
      builder: (context, constraints) => ListenableBuilder(
        listenable: Listenable.merge([nav, geo, widget.controller]),
        builder: (context, _) {
          if (!identical(_tileClient, geo) ||
              _tileRevision != geo.tileRevision ||
              _tiles?.source != _tileSource) {
            _tiles?.suspend();
            _tileClient = geo;
            _tileRevision = geo.tileRevision;
            _tiles = _newTiles(geo);
          }
          _wide = constraints.maxWidth >= 1000;
          final focus = _region == null ? null : _focus(nav);
          _queueCamera(nav);
          final handover = HandoverEntry(
            home: widget.controller.homeData.data,
            accountId: widget.account.id,
            enabled: widget.controller.homeData.status == FeatureStatus.ready,
          );
          final header = Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome, ${widget.account.name}.',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontSize: 24),
                ),
                if (widget.controller.homeData.data == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Rider account approved',
                      style: TextStyle(
                        fontSize: 11,
                        color: RiderColors.accentText,
                      ),
                    ),
                  ),
                WorkDutyControl(controller: widget.controller),
              ],
            ),
          );
          if (!_wide || constraints.maxHeight < 360) {
            final showMap = constraints.maxHeight >= 360;
            _setMapVisible(
              showMap &&
                  _region != null &&
                  widget.controller.taskData.status != FeatureStatus.loading,
            );
            return CustomScrollView(
              key: const ValueKey('home-page-scroll'),
              controller: _pageScroll,
              slivers: [
                SliverToBoxAdapter(child: header),
                if (showMap)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.textScalerOf(context).scale(14) > 20
                              ? (constraints.maxHeight * .33).clamp(
                                  160.0,
                                  240.0,
                                )
                              : (constraints.maxHeight * .42).clamp(
                                  200.0,
                                  320.0,
                                ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _mapArea(nav, geo, focus),
                          ),
                        ),
                        _attribution(),
                      ],
                    ),
                  ),
                SliverToBoxAdapter(child: _mapStatus(nav, geo, focus)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: WorkSummary(
                      controller: widget.controller,
                      compact: true,
                      showDuty: false,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: handover,
                  ),
                ),
                if (!showMap) SliverToBoxAdapter(child: _attribution()),
                _panel(nav, asSliver: true),
              ],
            );
          }
          _setMapVisible(
            _region != null &&
                widget.controller.taskData.status != FeatureStatus.loading,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (constraints.maxHeight * .3).clamp(72.0, 180.0),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      header,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: WorkSummary(
                          controller: widget.controller,
                          compact: true,
                          showDuty: false,
                        ),
                      ),
                      handover,
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _wide ? 16 : 0,
                    0,
                    _wide ? 16 : 0,
                    0,
                  ),
                  child: _wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _mapArea(nav, geo, focus)),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 390,
                              child: RiderSurface(child: _panel(nav)),
                            ),
                          ],
                        )
                      : _mapArea(nav, geo, focus),
                ),
              ),
              _attribution(),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * .25,
                ),
                child: SingleChildScrollView(
                  child: _mapStatus(nav, geo, focus),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mapArea(
    NavigationController nav,
    GeoapifyClient geo,
    HomeMapFocus? resolvedFocus,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      _mapSize = constraints.biggest;
      if (!_mapVisible) {
        return Center(
          child: Text(
            _outlineFailed
                ? 'Philippines map unavailable. Use task addresses.'
                : _region == null
                ? 'Loading Philippines map…'
                : 'Loading current stops…',
          ),
        );
      }
      final epoch = _mapEpoch;
      final focus = resolvedFocus!, points = focus.points;
      final tasks = HomeMapFocus.pins(
        queuedTasks: _queueTasks,
        selectedTask: widget.controller.selectedTask,
        navigatingTask: nav.active ? nav.task : null,
      );
      final start =
          _savedCenter ??
          (points.isNotEmpty
              ? points.first
              : PhilippinesMapRegion.cameraBounds.center);
      return ClipRRect(
        borderRadius: BorderRadius.circular(RiderRadii.media),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: start,
                initialZoom: _savedZoom ?? (points.length == 1 ? 15 : 5),
                initialRotation: _savedRotation,
                initialCameraFit: _savedCenter == null && points.length != 1
                    ? CameraFit.bounds(
                        bounds: points.isEmpty
                            ? PhilippinesMapRegion.cameraBounds
                            : LatLngBounds.fromPoints(points),
                        padding: const EdgeInsets.all(36),
                        maxZoom: 15,
                        minZoom: PhilippinesMapRegion.minimumZoom,
                      )
                    : null,
                minZoom: PhilippinesMapRegion.minimumZoom,
                maxZoom: PhilippinesMapRegion.maximumZoom,
                cameraConstraint: CameraConstraint.containCenter(
                  bounds: PhilippinesMapRegion.cameraBounds,
                ),
                backgroundColor: RiderColors.canvas,
                onMapReady: () {
                  if (!mounted || !widget.active || epoch != _mapEpoch) return;
                  _ready = true;
                  if (_savedCenter == null) {
                    _lastFocusKey =
                        '${widget.controller.queue.name}:${focus.key}';
                  }
                  if (nav.following) _lastCameraPoint = null;
                  _queueCamera(nav);
                },
                onPositionChanged: (camera, hasGesture) {
                  if (!widget.active || epoch != _mapEpoch) return;
                  _savedCenter = camera.center;
                  _savedZoom = camera.zoom;
                  _savedRotation = camera.rotation;
                  if (hasGesture) nav.pan();
                },
              ),
              children: [
                if (geo.configured)
                  TileLayer(
                    key: ValueKey(_tiles!.scope),
                    tileProvider: _tiles!,
                    urlTemplate: _tileSource.template,
                    userAgentPackageName: 'com.example.bagoo_rider_mobile',
                    panBuffer: 0,
                  ),
                PhilippinesMapMask(region: _region!),
                if (nav.road != null && !focus.outsideOutline)
                  PolylineLayer(
                    polylines: [
                      for (final line in nav.road!.lines)
                        Polyline(
                          points: line,
                          strokeWidth: 5,
                          color: RiderColors.accent,
                        ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (final task in tasks)
                      Marker(
                        key: ValueKey('home-marker-${task.id}'),
                        point: HomeMapFocus.pointFor(task)!,
                        width: 56,
                        height: 56,
                        child: Tooltip(
                          message: 'Select ${task.tracking}',
                          child: Semantics(
                            button: true,
                            label: 'Select ${task.tracking}',
                            child: Material(
                              shape: const CircleBorder(),
                              elevation: 3,
                              color:
                                  widget.controller.selectedTask?.id == task.id
                                  ? RiderColors.accent
                                  : Colors.white,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => unawaited(
                                  _select(
                                    OperationsRepository.asRiderTask(task),
                                    nav,
                                  ),
                                ),
                                child: Icon(
                                  stopKindIcon(task.stop.kind),
                                  color:
                                      widget.controller.selectedTask?.id ==
                                          task.id
                                      ? Colors.white
                                      : RiderColors.accentText,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (nav.fix != null)
                      Marker(
                        point: nav.fix!.point,
                        width: 28,
                        height: 28,
                        child: Semantics(
                          label: nav.manual
                              ? 'Manual preview origin'
                              : 'Rider position',
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: RiderColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  Widget _mapStatus(
    NavigationController nav,
    GeoapifyClient geo,
    HomeMapFocus? focus,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (focus != null) ...[
          Text(
            focus.label,
            key: const ValueKey('home-map-focus-label'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Wrap(
            children: [
              IconButton(
                tooltip: 'Recenter',
                onPressed: !_mapVisible
                    ? null
                    : () {
                        nav.recenter();
                        _lastFocusKey = null;
                        _queueCamera(nav);
                      },
                icon: const Icon(Icons.my_location_rounded),
              ),
              if (nav.road != null && !focus.outsideOutline)
                IconButton(
                  tooltip: 'Show full route',
                  onPressed: !_mapVisible
                      ? null
                      : () {
                          nav.pan();
                          _fit(focus.points);
                        },
                  icon: const Icon(Icons.route_rounded),
                ),
              IconButton(
                tooltip: 'Show queue stops',
                onPressed: !_mapVisible
                    ? null
                    : () {
                        nav.pan();
                        _fit(_queuePoints);
                      },
                icon: const Icon(Icons.crop_free_rounded),
              ),
              IconButton(
                key: const ValueKey('home-sharper-labels'),
                tooltip: _retinaTiles
                    ? 'Use standard map detail'
                    : 'Sharper labels (larger images)',
                isSelected: _retinaTiles,
                onPressed: !_mapVisible
                    ? null
                    : () => setState(() => _retinaTiles = !_retinaTiles),
                icon: const Icon(Icons.hd_outlined),
              ),
            ],
          ),
          if (focus.outsideOutline)
            _mapNote(
              'The saved stop is outside this PH outline. Its address and external directions remain available.',
              Icons.location_off_outlined,
            ),
          if (focus.missingCoordinates)
            _mapNote(
              'This stop has no saved coordinates. Use its address for directions.',
              Icons.location_off_outlined,
            ),
          if (widget.controller.selectedTask != null &&
              !widget.controller.visibleTasks.any(
                (t) => t.id == widget.controller.selectedTask!.id,
              ))
            _mapNote(
              'Your selected stop stays on the map while you browse this list.',
              Icons.filter_alt_outlined,
            ),
        ],
        if (_outlineFailed)
          _mapNote(
            'Philippines outline could not load. Task addresses remain available.',
            Icons.map_outlined,
          ),
        if (!geo.configured || geo.failure != null)
          _mapNote(
            geo.failure ??
                'Map unavailable. Task addresses are still available.',
            Icons.map_outlined,
          ),
        if (geo.configured && geo.loadingTiles)
          const LinearProgressIndicator(semanticsLabel: 'Loading map streets'),
        if (geo.failure != null && geo.configured)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('home-retry-map'),
              onPressed: _mapVisible && geo.canRetryTiles
                  ? geo.retryTiles
                  : null,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                geo.coolingDown ? 'Map provider is cooling down' : 'Retry map',
              ),
            ),
          ),
        if (_region != null &&
            geo.configured &&
            widget.controller.taskData.status != FeatureStatus.loading &&
            _queuePoints.isEmpty &&
            (focus?.points.isEmpty ?? true))
          _mapNote(
            'No stops in this list can be mapped here. Task addresses are still available.',
            Icons.location_off_outlined,
          ),
        if (nav.manual)
          _mapNote('Manual preview origin', Icons.edit_location_alt_outlined),
        if (nav.message != null)
          _mapNote(nav.message!, Icons.info_outline_rounded),
      ],
    ),
  );
  Widget _mapNote(String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: RiderSurface(
      radius: RiderRadii.control,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: RiderColors.muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: RiderColors.muted),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _attribution() => Wrap(
    alignment: WrapAlignment.center,
    children: [
      _credit('Powered by Geoapify', 'https://www.geoapify.com/'),
      _credit(
        '© OpenStreetMap contributors',
        'https://www.openstreetmap.org/copyright',
      ),
      _credit('© OpenMapTiles', 'https://openmaptiles.org/'),
      TextButton(
        style: TextButton.styleFrom(
          textStyle: Theme.of(context).textTheme.labelSmall
              ?.copyWith(fontSize: 10),
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 5),
        ),
        onPressed: () => showRiderDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Philippines outline credits'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Philippines administrative boundary (2020): OCHA Philippines / NAMRIA, via geoBoundaries. Simplified for this map; all source islands retained. The outline is a display approximation.',
                  ),
                  _credit(
                    'OCHA / NAMRIA source',
                    'https://data.humdata.org/dataset/philippines-administrative-levels-0-to-3',
                  ),
                  _credit('geoBoundaries', 'https://www.geoboundaries.org/'),
                  _credit(
                    'CC BY 3.0 IGO',
                    'https://creativecommons.org/licenses/by/3.0/igo/',
                  ),
                  _credit(
                    'CC BY 4.0',
                    'https://creativecommons.org/licenses/by/4.0/',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
        child: const Text('PH outline credits'),
      ),
    ],
  );
  Widget _credit(String label, String url) => TextButton(
    style: TextButton.styleFrom(
      textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 5),
    ),
    onPressed: () =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    child: Text(label),
  );
}
