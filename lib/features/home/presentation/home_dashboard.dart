import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../auth/data/account.dart';
import '../../navigation/presentation/geoapify_tiles.dart';
import '../../navigation/presentation/navigation_controls.dart';
import '../../navigation/presentation/navigation_providers.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';
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
  bool _ready = false;
  LatLng? _lastCameraPoint;
  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider),
        geo = ref.watch(geoapifyProvider);
    return LayoutBuilder(
      builder: (context, constraints) => ListenableBuilder(
        listenable: Listenable.merge([nav, geo, widget.controller]),
        builder: (context, _) {
          final controller = widget.controller;
          final tasks = controller.visibleTasks;
          final panel = TasksPage(
            account: widget.account,
            controller: controller,
            preview: false,
            panelOnly: true,
            onTaskSelected: (task) {
              if (nav.task?.id != task.id) unawaited(nav.stop());
            },
            navigationActions: (task) =>
                NavigationControls(task: task, navigation: nav),
          );
          final point = nav.fix?.point;
          if (_ready &&
              nav.following &&
              point != null &&
              point != _lastCameraPoint) {
            _lastCameraPoint = point;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && nav.following) _map.move(point, 16);
            });
          }
          if (constraints.maxHeight < 360) {
            return TasksPage(
              account: widget.account,
              controller: controller,
              preview: false,
              navigationActions: panel.navigationActions,
              onTaskSelected: panel.onTaskSelected,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (constraints.maxHeight * .25).clamp(70.0, 180.0),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Welcome, ${widget.account.name}.',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: controller.refreshAll,
                            tooltip: 'Refresh Home',
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      const WorkspaceBadge(
                        'Rider account approved',
                        accent: true,
                      ),
                      WorkSummary(controller: controller),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _map,
                      options: MapOptions(
                        initialCenter: const LatLng(12.8, 121.7),
                        initialZoom: 5,
                        minZoom: 3,
                        maxZoom: 19,
                        backgroundColor: RiderColors.canvas,
                        onMapReady: () => _ready = true,
                        onPositionChanged: (camera, hasGesture) {
                          if (hasGesture) nav.pan();
                        },
                      ),
                      children: [
                        if (geo.configured)
                          TileLayer(
                            tileProvider: GeoapifyTiles(geo),
                            urlTemplate: 'https://api.geoapify.com/v1/tile/positron/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.example.bagoo_rider_mobile',
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
                              if (task.operation?.stop.latitude != null &&
                                  task.operation?.stop.longitude != null)
                                Marker(
                                  point: LatLng(
                                    task.operation!.stop.latitude!,
                                    task.operation!.stop.longitude!,
                                  ),
                                  width: 48,
                                  height: 48,
                                  child: IconButton(
                                    tooltip: 'Select ${task.tracking}',
                                    onPressed: () =>
                                        panel.openParcel(context, task),
                                    icon: Icon(
                                      Icons.location_on_rounded,
                                      color:
                                          controller.selectedTask?.id == task.id
                                          ? RiderColors.accent
                                          : RiderColors.ink,
                                      size: 36,
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
                            if (point != null)
                              Marker(
                                point: point,
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
                      top: 8,
                      left: 12,
                      right: 68,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!geo.configured || geo.failure != null)
                            RiderSurface(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                geo.failure ?? 'Map and routes need a Geoapify key. Task addresses remain available.',
                              ),
                            ),
                          if (nav.manual)
                            const RiderSurface(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Manual preview origin · no GPS tracking',
                              ),
                            ),
                          if (nav.message != null)
                            RiderSurface(
                              padding: const EdgeInsets.all(8),
                              child: Text(nav.message!),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: RiderSurface(
                        child: IconButton(
                          tooltip: 'Recenter',
                          onPressed: () {
                            nav.recenter();
                            final selected = controller.selectedTask?.stop;
                            final center =
                                nav.fix?.point ??
                                nav.target ??
                                (selected?.latitude != null &&
                                        selected?.longitude != null
                                    ? LatLng(
                                        selected!.latitude!,
                                        selected.longitude!,
                                      )
                                    : null);
                            if (_ready && center != null) _map.move(center, 16);
                          },
                          icon: const Icon(Icons.my_location_rounded),
                        ),
                      ),
                    ),
                    DraggableScrollableSheet(
                      initialChildSize: .35,
                      minChildSize: .18,
                      maxChildSize: .82,
                      builder: (context, scroll) => RiderSurface(
                        radius: RiderRadii.sheet,
                        child: TasksPage(
                          account: widget.account,
                          controller: controller,
                          preview: false,
                          panelOnly: true,
                          scrollController: scroll,
                          onTaskSelected: panel.onTaskSelected,
                          navigationActions: panel.navigationActions,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  _credit('Powered by Geoapify', 'https://www.geoapify.com/'),
                  _credit(
                    '© OpenStreetMap contributors',
                    'https://www.openstreetmap.org/copyright',
                  ),
                  _credit('© OpenMapTiles', 'https://openmaptiles.org/'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _credit(String label, String url) => TextButton(
    style: TextButton.styleFrom(
      textStyle: const TextStyle(fontSize: 10),
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 5),
    ),
    onPressed: () =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    child: Text(label),
  );
}
