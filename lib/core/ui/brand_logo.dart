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
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(RiderRadii.brand + 3),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFFFFFFF),
                    blurRadius: 8,
                    offset: Offset(-3, -3),
                  ),
                  BoxShadow(
                    color: Color(0x22E00D42),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(RiderRadii.brand),
                child: Image.asset(
                  'assets/branding/gooriders-icon.png',
                  width: size,
                  height: size,
                  filterQuality: FilterQuality.high,
                ),
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
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: RiderColors.rose,
                      borderRadius: BorderRadius.circular(RiderRadii.pill),
                    ),
                    child: const Text(
                      'RIDER OS',
                      style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w800,
                        color: RiderColors.accentText,
                      ),
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
