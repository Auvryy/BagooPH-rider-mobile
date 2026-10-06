import 'package:flutter/material.dart';

import '../../app/theme.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 42});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BagooPH Rider',
      image: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/branding/bagoo-mark.png',
                width: size,
                height: size,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      fontSize: 21,
                      color: RiderColors.ink,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'RIDER',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w600,
                      color: RiderColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
