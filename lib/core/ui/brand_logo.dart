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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(RiderRadii.brand + 3),
                  border: Border.all(color: RiderColors.outline, width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0E111827),
                      blurRadius: 10,
                      offset: Offset(0, 3),
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
