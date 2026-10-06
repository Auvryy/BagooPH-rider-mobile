import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/brand_logo.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    required this.registering,
    this.scrollController,
  });
  final Widget child;
  final bool registering;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 1024 &&
                MediaQuery.textScalerOf(context).scale(16) <= 23;
            final pagePadding = constraints.maxWidth < 600 ? 16.0 : 24.0;
            final form = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x070F172A),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(constraints.maxWidth < 420 ? 16 : 32),
                  child: child,
                ),
              ),
            );
            return SingleChildScrollView(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.all(pagePadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - pagePadding * 2).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              const BrandLogo(),
                              Semantics(
                                label: 'Interface preview',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: RiderColors.rose,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Preview',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: RiderColors.accentText,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _BrandStory(registering: registering),
                              ),
                              const SizedBox(width: 72),
                              Expanded(child: form),
                            ],
                          )
                        else
                          form,
                        const SizedBox(height: 24),
                        const Text(
                          'Design preview. No information is submitted.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: RiderColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandStory extends StatelessWidget {
  const _BrandStory({required this.registering});
  final bool registering;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RiderColors.rose,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              registering ? Icons.route_outlined : Icons.inventory_2_outlined,
              size: 36,
              color: RiderColors.accentText,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            registering
                ? 'Your next chapter,\none clear step at a time.'
                : 'A clear next step.\nEvery parcel,\nevery handoff.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 20),
          Text(
            registering
                ? 'Join the rider workspace built around thoughtful pickups, '
                      'clear destinations and responsible deliveries.'
                : 'Your pickups, assigned deliveries and parcel details, '
                      'together in one rider workspace.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: RiderColors.muted),
          ),
          const SizedBox(height: 32),
          for (final item in [
            (Icons.local_shipping_outlined, 'Pickup and delivery, one app'),
            (Icons.location_on_outlined, 'The right stop, clearly shown'),
            (Icons.task_alt_outlined, 'A useful next action at every step'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(item.$1, size: 20, color: RiderColors.accentText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                        fontSize: 14,
                        color: RiderColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
