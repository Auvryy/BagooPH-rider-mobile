import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../home/data/operations_models.dart';
import 'handover_issues_page.dart';

class HandoverEntry extends StatelessWidget {
  const HandoverEntry({
    super.key,
    required this.home,
    required this.accountId,
    this.barcode,
    this.enabled = true,
  });
  final OperationsHome? home;
  final String accountId;
  final String? barcode;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final available =
        enabled &&
        home?.handoverApiVersion == 1 &&
        home?.capabilities['handover_issues'] == true;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: ValueKey(
          barcode == null ? 'home-handover-issues' : 'stop-handover-issues',
        ),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: const Icon(Icons.fact_check_outlined),
        label: Text(
          available ? 'Handover issues' : 'Handover issues unavailable',
        ),
        onPressed: available
            ? () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => HandoverSessionGuard(
                    accountId: accountId,
                    child: HandoverIssuesPage(initialBarcode: barcode),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// Each handover/evidence route closes on account or discovery changes, even
/// when another route covers it. Private form state does not cross sessions.
class HandoverSessionGuard extends ConsumerWidget {
  const HandoverSessionGuard({
    super.key,
    required this.accountId,
    required this.child,
  });
  final String accountId;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider);
    ref.listen(
      authControllerProvider.select(
        (s) => (
          id: s.user?.id,
          approved: s.user?.approved,
          operations: s.user?.operationsApiVersion,
          handover: s.user?.handoverApiVersion,
          initialized: !s.initializing,
        ),
      ),
      (old, next) {
        if (old == null || !old.initialized || old == next) return;
        final route = ModalRoute.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && route?.isActive == true) {
            Navigator.of(context).removeRoute(route!);
          }
        });
      },
    );
    if (session.user?.id != accountId || session.user?.approved != true) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text('Sign in with your approved rider account.'),
          ),
        ),
      );
    }
    return child;
  }
}
