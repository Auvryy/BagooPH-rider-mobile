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
import '../../navigation/presentation/geoapify_tiles.dart';
import '../../navigation/presentation/navigation_controller.dart';
import '../../navigation/presentation/navigation_controls.dart';
import '../../navigation/presentation/navigation_providers.dart';
import '../../workspace/data/workspace_models.dart';
import '../data/operations_repository.dart';
import '../data/operations_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import 'home_task_panel.dart';
import 'tasks_page.dart';
import 'work_summary.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({
    super.key,
    required this.account,
    required this.controller,
  });
  final RiderAccount account;
  final WorkspaceController controller;
  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  final _map = MapController();
  final _sheet = DraggableScrollableController();
  GeoapifyTiles? _tiles;
  GeoapifyClient? _tileClient;
  bool _ready = false, _wide = false, _cameraQueued = false;
  Size _mapSize = Size.zero;
  LatLng? _lastCameraPoint;
  String? _focusedTask;
  TaskQueue? _fittedQueue;
  static const _overview = LatLng(12.8, 121.7);
  @override
  void dispose() {
    _sheet.dispose();
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
        LatLng(_mapTask(t)!.stop.latitude!, _mapTask(t)!.stop.longitude!),
  ];
  double get _coveredHeight =>
      _wide ? 0 : (_sheet.isAttached ? _sheet.size : .5) * _mapSize.height;
  String? _stopKey(OperationTask? task) => task == null
      ? null
      : '${task.id}:${task.stop.kind}:${task.stop.latitude}:${task.stop.longitude}';
  void _moveTo(LatLng p, {double zoom = 15}) {
    if (!_ready || _mapSize.isEmpty) return;
    _map.move(p, zoom, offset: Offset(0, -_coveredHeight / 2));
  }

  void _fit(List<LatLng> points) {
    if (!_ready || _mapSize.isEmpty) return;
    if (points.isEmpty) {
      _map.move(_overview, 5);
      return;
    }
    if (points.length == 1) {
      _moveTo(points.first);
      return;
    }
    final top = (76.0).clamp(0.0, _mapSize.height * .2);
    final maxBottom = (_mapSize.height - top - 72).clamp(0.0, _mapSize.height);
    final bottom = (_coveredHeight + 28).clamp(0.0, maxBottom);
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: EdgeInsets.fromLTRB(36, top, 36, bottom),
        maxZoom: 15,
        minZoom: 3,
      ),
    );
  }

  void _queueCamera(NavigationController nav) {
    if (_cameraQueued) return;
    _cameraQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cameraQueued = false;
      if (!mounted || !_ready) return;
      final selected = widget.controller.selectedTask;
      if (nav.active &&
          (widget.controller.unavailableTaskId == nav.task?.id ||
              (selected != null &&
                  selected.id == nav.task?.id &&
                  (_stopKey(selected) != _stopKey(nav.task) ||
                      selected.stop.address != nav.task?.stop.address ||
                      selected.assignmentReference !=
                          nav.task?.assignmentReference)))) {
        unawaited(
          nav.stop(
            reason: 'This task or stop changed. Refresh it before navigating again.',
          ),
        );
        return;
      }
      final fix = nav.fix?.point;
      if (nav.active &&
          nav.following &&
          fix != null &&
          fix != _lastCameraPoint) {
        _lastCameraPoint = fix;
        _moveTo(fix, zoom: 16);
        return;
      }
      if (selected != null &&
          selected.stop.latitude != null &&
          selected.stop.longitude != null &&
          _focusedTask != _stopKey(selected)) {
        _focusedTask = _stopKey(selected);
        _fittedQueue = widget.controller.queue;
        _moveTo(LatLng(selected.stop.latitude!, selected.stop.longitude!));
        return;
      }
      if (!nav.active &&
          _fittedQueue != widget.controller.queue &&
          _queuePoints.isNotEmpty) {
        _fittedQueue = widget.controller.queue;
        _fit(_queuePoints);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _select(RiderTask task, NavigationController nav) async {
    if (nav.task?.id != task.id) await nav.stop();
    await widget.controller.openTask(task);
    if (!mounted) return;
    if (nav.active &&
        widget.controller.selectedTask?.id == nav.task?.id &&
        _stopKey(widget.controller.selectedTask) != _stopKey(nav.task)) {
      await nav.checkAuthorization();
    }
    if (!mounted) return;
    if (!_wide && _sheet.isAttached && widget.controller.selectedTask != null) {
      await _sheet.animateTo(
        .64,
        duration: RiderMotion.reduced(context)
            ? Duration.zero
            : RiderMotion.sheet,
        curve: Curves.easeOutCubic,
      );
    }
    final selected = widget.controller.selectedTask;
    if (selected != null &&
        selected.stop.latitude != null &&
        selected.stop.longitude != null) {
      _focusedTask = _stopKey(selected);
      _fittedQueue = widget.controller.queue;
      _moveTo(LatLng(selected.stop.latitude!, selected.stop.longitude!));
    }
  }

  void _togglePanel() {
    if (!_sheet.isAttached) return;
    _sheet.animateTo(
      _sheet.size > 0.6 ? 0.3 : 0.84,
      duration: RiderMotion.reduced(context)
          ? Duration.zero
          : RiderMotion.sheet,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _panel(
    NavigationController nav, {
    ScrollController? scroll,
    bool draggable = false,
  }) => HomeTaskPanel(
    controller: widget.controller,
    scrollController: scroll,
    onSelect: (task) => unawaited(_select(task, nav)),
    onDetails: (task) {
      final display = OperationsRepository.asRiderTask(task);
      TasksPage(
        account: widget.account,
        controller: widget.controller,
        preview: false,
        navigationActions: (task) =>
            NavigationControls(task: task, navigation: nav),
      ).openParcel(context, display);
    },
    onTogglePanel: draggable ? _togglePanel : null,
    onQueueChanged: (_) {
      _fittedQueue = null;
      _focusedTask = null;
    },
    onShowStop: () {
      nav.pan();
      final stop = widget.controller.selectedTask?.stop;
      if (stop?.latitude != null && stop?.longitude != null) {
        if (_sheet.isAttached) _sheet.jumpTo(.3);
        _moveTo(LatLng(stop!.latitude!, stop.longitude!));
      }
    },
  );
  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider),
        geo = ref.watch(geoapifyProvider);
    if (!identical(_tileClient, geo)) {
      _tileClient = geo;
      _tiles = GeoapifyTiles(geo);
    }
    return LayoutBuilder(
      builder: (context, constraints) => ListenableBuilder(
        listenable: Listenable.merge([nav, geo, widget.controller]),
        builder: (context, _) {
          _wide = constraints.maxWidth >= 1000;
          _queueCamera(nav);
          final header = ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (constraints.maxHeight * .3).clamp(72.0, 180.0),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome, ${widget.account.name}.',
                    style: Theme.of(context).textTheme.titleMedium,
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
                  const SizedBox(height: 4),
                  WorkSummary(controller: widget.controller, compact: true),
                ],
              ),
            ),
          );
          if (constraints.maxHeight < 360) {
            _ready = false;
            _mapSize = Size.zero;
            return Column(
              children: [
                header,
                Expanded(child: _panel(nav)),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
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
                            Expanded(child: _mapArea(nav, geo)),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 390,
                              child: RiderSurface(child: _panel(nav)),
                            ),
                          ],
                        )
                      : _mapArea(nav, geo),
                ),
              ),
              _attribution(),
            ],
          );
        },
      ),
    );
  }

  Widget _mapArea(
    NavigationController nav,
    GeoapifyClient geo,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      _mapSize = constraints.biggest;
      final tasks = widget.controller.visibleTasks;
      return ClipRRect(
        borderRadius: BorderRadius.circular(_wide ? RiderRadii.media : 0),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _overview,
                initialZoom: 5,
                minZoom: 3,
                maxZoom: 19,
                backgroundColor: RiderColors.canvas,
                onMapReady: () {
                  _ready = true;
                  _fittedQueue = null;
                  _focusedTask = null;
                  _lastCameraPoint = null;
                  _queueCamera(nav);
                },
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture) nav.pan();
                },
              ),
              children: [
                if (geo.configured)
                  TileLayer(
                    tileProvider: _tiles!,
                    urlTemplate: 'https://api.geoapify.com/v1/tile/positron/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.bagoo_rider_mobile',
                    panBuffer: 0,
                  ),
                if (nav.road != null)
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
                      if (_mapTask(task)?.stop.latitude != null &&
                          _mapTask(task)?.stop.longitude != null)
                        Marker(
                          key: ValueKey('home-marker-${task.id}'),
                          point: LatLng(
                            _mapTask(task)!.stop.latitude!,
                            _mapTask(task)!.stop.longitude!,
                          ),
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
                                    widget.controller.selectedTask?.id ==
                                        task.id
                                    ? RiderColors.accent
                                    : Colors.white,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => unawaited(_select(task, nav)),
                                  child: Icon(
                                    stopKindIcon(_mapTask(task)?.stop.kind),
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
                    if (nav.target != null &&
                        !tasks.any((t) => t.id == nav.task?.id))
                      Marker(
                        point: nav.target!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.flag_rounded,
                          color: RiderColors.accent,
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
            Positioned(
              top: 12,
              left: 12,
              right: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!geo.configured || geo.failure != null)
                    _mapNote(
                      geo.failure ?? 'Map unavailable · add a Geoapify key to load streets.',
                      Icons.map_outlined,
                    ),
                  if (geo.configured &&
                      _queuePoints.isEmpty &&
                      nav.target == null)
                    _mapNote(
                      'No saved map pins in this queue. Task addresses are still available.',
                      Icons.location_off_outlined,
                    ),
                  if (nav.manual)
                    _mapNote(
                      'Manual preview origin',
                      Icons.edit_location_alt_outlined,
                    ),
                  if (nav.message != null)
                    _mapNote(nav.message!, Icons.info_outline_rounded),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: RiderSurface(
                radius: RiderRadii.control,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Recenter',
                      onPressed: () {
                        nav.recenter();
                        final p = nav.fix?.point ?? nav.target;
                        if (p != null) {
                          _lastCameraPoint = p;
                          _moveTo(p, zoom: 16);
                        } else {
                          final stop = widget.controller.selectedTask?.stop;
                          if (stop?.latitude != null &&
                              stop?.longitude != null) {
                            _moveTo(LatLng(stop!.latitude!, stop.longitude!));
                          } else {
                            _fit(_queuePoints);
                          }
                        }
                      },
                      icon: const Icon(Icons.my_location_rounded),
                    ),
                    if (nav.road != null)
                      IconButton(
                        tooltip: 'Show full route',
                        onPressed: () {
                          nav.pan();
                          _fit([for (final line in nav.road!.lines) ...line]);
                        },
                        icon: const Icon(Icons.route_rounded),
                      ),
                    IconButton(
                      tooltip: 'Show queue stops',
                      onPressed: () {
                        nav.pan();
                        _fit(_queuePoints);
                      },
                      icon: const Icon(Icons.crop_free_rounded),
                    ),
                  ],
                ),
              ),
            ),
            if (!_wide)
              DraggableScrollableSheet(
                controller: _sheet,
                initialChildSize: .5,
                minChildSize: .22,
                maxChildSize: .84,
                snap: true,
                snapSizes: const [.3, .64],
                builder: (context, scroll) => RiderSurface(
                  radius: RiderRadii.sheet,
                  child: _panel(nav, scroll: scroll, draggable: true),
                ),
              ),
          ],
        ),
      );
    },
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
