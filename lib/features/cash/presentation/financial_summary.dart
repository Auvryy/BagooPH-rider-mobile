import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../data/cash_models.dart';

class RiderEarningsSummary extends StatelessWidget {
  const RiderEarningsSummary({
    super.key,
    required this.earnings,
    this.title = 'Your earnings',
  });
  final RiderEarnings earnings;
  final String title;

  @override
  Widget build(BuildContext context) => RiderSurface(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(
          icon: Icons.account_balance_wallet_outlined,
          title: earnings.available ? title : 'Earnings unavailable',
        ),
        const SizedBox(height: 12),
        if (earnings.available) ...[
          _Amounts(
            values: [
              ('Released earnings', earnings.confirmed!),
              ('Pending earnings', earnings.pending!),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Original pickup and delivery shares. These are earned amounts, not a record of money paid out.',
            style: TextStyle(
              fontSize: 12,
              color: RiderColors.muted,
              height: 1.5,
            ),
          ),
        ] else
          const Text(
            'Confirmed rider earnings are not provided by this service. COD, shipping, discounts and remitted cash are not earnings.',
          ),
      ],
    ),
  );
}

class RiderShiftSummaryPanel extends StatelessWidget {
  const RiderShiftSummaryPanel({super.key, required this.shift, this.onCash});
  final RiderShiftSummary shift;
  final VoidCallback? onCash;

  @override
  Widget build(BuildContext context) {
    final message = shift.unresolvedDifferences > 0
        ? 'A cash difference needs your hub’s review.'
        : shift.pendingHandovers > 0
        ? 'Your hub still needs to confirm the cash handover.'
        : shift.held > BigInt.zero
        ? 'Hand over the cash you collected at your assigned hub.'
        : 'Your recorded cash handovers are clear.';
    return RiderSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(
            icon: Icons.receipt_long_outlined,
            title: shift.id == null
                ? 'Cash responsibility'
                : 'Current duty shift',
          ),
          const SizedBox(height: 12),
          _Amounts(
            values: [
              ('Collected', shift.collected),
              ('Received by hub', shift.remitted),
              ('Still held by you', shift.held),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            key: const ValueKey('shift-cash-status'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: shift.canClose ? RiderColors.ink : RiderColors.accentText,
            ),
          ),
          if (!shift.canClose) ...[
            const SizedBox(height: 8),
            Text(
              'Pending handovers: ${shift.pendingHandovers}. Differences needing review: ${shift.unresolvedDifferences}.',
              style: const TextStyle(fontSize: 12, color: RiderColors.muted),
            ),
            const SizedBox(height: 8),
            const Text(
              'Duty cannot close until your hub confirms the counted cash and any differences are resolved.',
              style: TextStyle(
                fontSize: 12,
                color: RiderColors.muted,
                height: 1.5,
              ),
            ),
            if (onCash != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onCash,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Review cash handovers'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: RiderColors.accentText),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _Amounts extends StatelessWidget {
  const _Amounts({required this.values});
  final List<(String, BigInt)> values;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final columns =
          size.maxWidth < 320 || MediaQuery.textScalerOf(context).scale(14) > 20
          ? 1
          : 2;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final value in values)
            SizedBox(
              width: (size.maxWidth - 16 * (columns - 1)) / columns,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.$1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: RiderColors.muted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    cashPeso(value.$2),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: RiderColors.accentText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}
