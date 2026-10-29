import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/rider_api_client.dart';
import '../../../core/platform/rider_website.dart';
import '../../auth/data/account.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';
import 'company_page.dart';

class RiderCompanyEntry extends ConsumerWidget {
  const RiderCompanyEntry({super.key, required this.account, this.onReturn});
  final RiderAccount account;
  final Future<void> Function()? onReturn;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available =
        account.approved &&
        account.companyApiVersion == 1 &&
        ref.watch(authRepositoryProvider) is RiderSessionApi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Company requests',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          available
              ? 'Ask to join a company, review an assignment offer or check your request history.'
              : 'Company joining is unavailable in this session. Sign in again after the service is enabled, or use the rider website.',
        ),
        const SizedBox(height: 12),
        if (available)
          OutlinedButton.icon(
            icon: const Icon(Icons.business_outlined),
            label: const Text('Open company requests'),
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => RiderCompanyPage(accountId: account.id),
                ),
              );
              if (context.mounted) await onReturn?.call();
            },
          )
        else
          const WebsiteButton(
            page: RiderWebsitePage.profile,
            label: 'Open rider website',
          ),
      ],
    );
  }
}
