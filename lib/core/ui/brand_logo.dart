import 'package:flutter/material.dart';

import '../../app/theme.dart';

class BagooBrandMark extends StatelessWidget {
  const BagooBrandMark({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/branding/bagoo-mark.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => ColoredBox(
          color: RiderColors.accent,
          child: Icon(
            Icons.shopping_bag_outlined,
            color: Colors.white,
            size: size * .62,
          ),
        ),
      ),
    ),
  );
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 42});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BagooPH Rider',
      image: true,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BagooBrandMark(size: size),
              const SizedBox(width: 10),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Bagoo'),
                    TextSpan(
                      text: 'PH',
                      style: TextStyle(color: RiderColors.accent),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 20,
                  color: RiderColors.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
