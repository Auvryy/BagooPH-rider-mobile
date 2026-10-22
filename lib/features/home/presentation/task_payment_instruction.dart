import 'package:flutter/material.dart';

import '../data/operations_models.dart';

/// Current task facts only. A null amount or non-COD method is not prepayment.
class TaskPaymentInstruction extends StatelessWidget {
  const TaskPaymentInstruction({
    super.key,
    required this.task,
    this.codPrefix = 'COD to collect',
  });
  final OperationTask task;
  final String codPrefix;

  @override
  Widget build(BuildContext context) {
    if (task.preview || task.phase != 'final_mile') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        switch (task.deliveryPaymentKind) {
          DeliveryPaymentKind.cod =>
            '$codPrefix: ${exactPesos(task.codDueCents!)}',
          DeliveryPaymentKind.paidWallet =>
            'Paid — no cash to collect · Bagoo Wallet',
          DeliveryPaymentKind.unavailable => 'Payment instructions unavailable. Refresh this parcel or contact your hub.',
        },
        key: const ValueKey('task-payment-instruction'),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
