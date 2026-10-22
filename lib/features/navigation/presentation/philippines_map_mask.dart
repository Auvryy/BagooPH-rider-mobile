import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../app/theme.dart';
import '../data/philippines_map_region.dart';

class PhilippinesMapMask extends StatefulWidget {
  const PhilippinesMapMask({
    super.key,
    required this.region,
    this.color = RiderColors.canvas,
  });
  final PhilippinesMapRegion region;
  final Color color;
  @override
  State<PhilippinesMapMask> createState() => _PhilippinesMapMaskState();
}

class _PhilippinesMapMaskState extends State<PhilippinesMapMask> {
  late List<Polygon> _polygons;
  void _prepare() => _polygons = List.unmodifiable([
    for (final rings in widget.region.polygons)
      Polygon(
        points: rings.first,
        holePointsList: rings.skip(1).toList(),
        color: Colors.transparent,
      ),
  ]);
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(PhilippinesMapMask oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.region, widget.region)) _prepare();
  }

  @override
  Widget build(BuildContext context) => PolygonLayer(
    polygons: _polygons,
    invertedFill: widget.color,
    // The generated MultiPolygon is validated, disjoint and has no overlapping
    // holes. evenOdd avoids thousands of native path-union operations per pan.
    painterFillMethod: PolygonPainterFillMethod.evenOdd,
    polygonLabels: false,
    simplificationTolerance: .2,
  );
}
