import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Map-only chrome keeps the light application theme and its text scaling intact.
class HomeMapChrome extends StatelessWidget {
  const HomeMapChrome({
    super.key,
    required this.focusLabel,
    required this.dark,
    required this.following,
    required this.locating,
    required this.positionLabel,
    required this.onStyle,
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final String focusLabel;
  final bool dark, following, locating;
  final String? positionLabel;
  final VoidCallback onStyle, onRecenter, onZoomIn, onZoomOut;

  @override
  Widget build(BuildContext context) {
    final ink = dark ? RiderMapColors.ink : RiderColors.ink;
    final muted = dark ? RiderMapColors.muted : RiderColors.muted;
    final surface = dark ? RiderMapColors.surface : RiderColors.surface;
    final border = dark ? RiderMapColors.border : RiderColors.border;
    Widget control(
      String label,
      IconData icon,
      VoidCallback onTap, {
      bool active = false,
    }) => IconButton(
      tooltip: label,
      onPressed: onTap,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        fixedSize: const Size(48, 48),
        foregroundColor: active ? Colors.white : ink,
        backgroundColor: active ? RiderColors.accent : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 22, semanticLabel: label),
    );
    Widget shell(Widget child) => Material(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 116,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark
                      ? [
                          RiderMapColors.canvas.withValues(alpha: .88),
                          RiderMapColors.canvas.withValues(alpha: 0),
                        ]
                      : [
                          Colors.white.withValues(alpha: .94),
                          Colors.white.withValues(alpha: 0),
                        ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 20,
          right: 84,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(Icons.public_rounded, size: 14, color: muted),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'PHILIPPINES',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  focusLabel,
                  key: const ValueKey('home-map-focus-label'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: shell(
            control(
              dark ? 'Use daylight map' : 'Use dark map',
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              onStyle,
            ),
          ),
        ),
        Positioned(
          right: 14,
          bottom: 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              shell(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    control('Zoom in', Icons.add_rounded, onZoomIn),
                    SizedBox(
                      width: 24,
                      child: Divider(height: 1, color: border),
                    ),
                    control('Zoom out', Icons.remove_rounded, onZoomOut),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              shell(
                control(
                  'Recenter',
                  locating
                      ? Icons.location_searching_rounded
                      : Icons.my_location_rounded,
                  onRecenter,
                  active: following,
                ),
              ),
            ],
          ),
        ),
        if (positionLabel != null)
          Positioned(
            left: 14,
            right: 78,
            bottom: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: shell(
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 15,
                          color: ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          positionLabel!,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class HomeMapStopPin extends StatelessWidget {
  const HomeMapStopPin({
    super.key,
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: Center(
            child: AnimatedScale(
              duration: RiderMotion.reduced(context)
                  ? Duration.zero
                  : RiderMotion.pressed,
              scale: selected ? 1.15 : 1,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? RiderColors.accent : RiderColors.surface,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: RiderMapColors.markerShadow,
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: 19,
                    color: selected ? Colors.white : RiderColors.accentText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class HomeMapPositionMarker extends StatelessWidget {
  const HomeMapPositionMarker({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .16),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: Center(
        child: Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(
            color: RiderColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(color: RiderMapColors.markerShadow, blurRadius: 8),
            ],
          ),
        ),
      ),
    ),
  );
}
