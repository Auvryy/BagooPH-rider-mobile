import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class OnboardingArt extends StatelessWidget {
  const OnboardingArt({super.key, required this.page});
  final int page;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 250,
      width: double.infinity,
      child: CustomPaint(painter: _IntroPainter(page)),
    ),
  );
}

class _IntroPainter extends CustomPainter {
  const _IntroPainter(this.page);
  final int page;
  static const tint = Color(0xFFFFF0F4);
  static const white = Colors.white;
  static const red = RiderColors.accent;
  static const border = RiderColors.border;

  void box(
    Canvas canvas,
    Rect rect,
    Color color,
    double radius, {
    bool outlined = false,
  }) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color,
    );
    if (outlined) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void line(Canvas canvas, double x, double y, double width, Color color) =>
      box(canvas, Rect.fromLTWH(x, y, width, 8), color, 5);
  void text(
    Canvas canvas,
    String value,
    Offset position,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w600,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: RiderTypography.family,
          fontSize: size,
          fontWeight: weight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position);
    painter.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    box(canvas, bounds.deflate(.5), tint, 24, outlined: true);
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(24)),
    );
    if (page == 0) {
      final width = size.width * .72;
      canvas.translate(size.width / 2, 125);
      canvas.rotate(-3 * math.pi / 180);
      canvas.translate(-width / 2, -92);
      box(canvas, Rect.fromLTWH(0, 0, width, 184), white, 16, outlined: true);
      box(canvas, Rect.fromLTWH(12, 12, width - 24, 112), tint, 10);
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(12, 12, width - 24, 112),
          const Radius.circular(10),
        ),
      );
      canvas.drawCircle(Offset(width - 45, 41), 13.5, Paint()..color = red);
      canvas.save();
      canvas.translate(-4, 100);
      canvas.rotate(-10 * math.pi / 180);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width + 12, 34),
        Paint()..color = white,
      );
      canvas.restore();
      final parcel = Rect.fromLTWH(width * .39, 54, 46, 43);
      box(canvas, parcel, white, 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(parcel.deflate(2), const Radius.circular(5)),
        Paint()
          ..color = red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      canvas.drawLine(
        Offset(parcel.center.dx, parcel.top + 2),
        Offset(parcel.center.dx, parcel.top + 14),
        Paint()
          ..color = red
          ..strokeWidth = 3,
      );
      canvas.restore();
      line(canvas, 12, 134, (width - 24) * .72, RiderColors.ink);
      line(canvas, 12, 152, (width - 24) * .48, border);
      box(canvas, const Rect.fromLTWH(12, 170, 68, 7), tint, 5);
      box(canvas, const Rect.fromLTWH(87, 170, 54, 7), border, 5);
    } else if (page == 1) {
      final width = size.width * .78;
      canvas.translate((size.width - width) / 2, 41);
      final card = Rect.fromLTWH(0, 0, width, 168);
      box(canvas, card, white, 18, outlined: true);
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(card, const Radius.circular(18)),
      );
      for (final road in [
        [-22.0, 50.0, -22.0, width * 1.2],
        [width * .1, 104.0, 18.0, width * .95],
        [width - 48, 31.0, 70.0, width * .72],
      ]) {
        canvas.save();
        canvas.translate(road[0], road[1]);
        canvas.rotate(road[2] * math.pi / 180);
        box(canvas, Rect.fromLTWH(0, 0, road[3], 11), border, 6);
        canvas.restore();
      }
      canvas.drawCircle(Offset(width * .56, 57), 17, Paint()..color = white);
      canvas.drawCircle(Offset(width * .56, 57), 13, Paint()..color = red);
      canvas.drawCircle(Offset(width * .56, 57), 3, Paint()..color = white);
      box(canvas, Rect.fromLTWH(12, 112, width - 24, 44), white, 11);
      canvas.drawCircle(const Offset(28, 134), 5, Paint()..color = red);
      line(canvas, 43, 123, math.min(90.0, width - 70), RiderColors.ink);
      line(canvas, 43, 137, math.min(62.0, width - 70), border);
      canvas.restore();
    } else {
      final width = size.width * .82;
      canvas.translate(size.width / 2, 125);
      canvas.rotate(2 * math.pi / 180);
      canvas.translate(-width / 2, -90);
      box(canvas, Rect.fromLTWH(0, 0, width, 180), white, 16, outlined: true);
      canvas.drawCircle(const Offset(28, 28), 15, Paint()..color = tint);
      line(canvas, 52, 19, math.max(35.0, width - 147), RiderColors.ink);
      line(canvas, 52, 33, math.max(25.0, width - 166), border);
      box(canvas, Rect.fromLTWH(width - 82, 17, 69, 23), tint, 7);
      text(
        canvas,
        'IN TRANSIT',
        Offset(width - 75, 24),
        8,
        red,
        weight: FontWeight.w800,
      );
      final cover = Rect.fromLTWH(13, 56, width - 26, 85);
      box(canvas, cover, tint, 10);
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(cover, const Radius.circular(10)),
      );
      canvas.translate(-10, 112);
      canvas.rotate(-11 * math.pi / 180);
      box(canvas, Rect.fromLTWH(0, 0, width * 1.2, 19), red, 0);
      canvas.restore();
      canvas.drawCircle(const Offset(18, 160), 5, Paint()..color = red);
      box(canvas, const Rect.fromLTWH(31, 158, 25, 3), border, 2);
      text(
        canvas,
        'Handover recorded',
        const Offset(64, 153),
        10,
        RiderColors.muted,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IntroPainter oldDelegate) => page != oldDelegate.page;
}
