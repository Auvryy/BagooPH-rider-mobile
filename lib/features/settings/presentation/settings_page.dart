import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/theme.dart';
import '../../../core/platform/rider_website.dart';
import '../../../core/ui/brand_logo.dart';
import '../../auth/data/account.dart';
import '../../workspace/presentation/workspace_widgets.dart';
import '../data/settings_models.dart';
import 'settings_controller.dart';
import 'settings_forms.dart';

enum ProfileSection { profile, settings, security, help, about }

final appPackageProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

class ProfileSettingsPage extends ConsumerWidget {
  const ProfileSettingsPage({
    super.key,
    required this.account,
    required this.section,
    required this.onSection,
    required this.onLogout,
    required this.onRefresh,
    required this.preview,
  });
  final RiderAccount account;
  final ProfileSection section;
  final ValueChanged<ProfileSection> onSection;
  final VoidCallback onLogout, onRefresh;
  final bool preview;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(
      settingsControllerProvider(
        SettingsIdentity(account.id, preview: preview),
      ),
    );
    final title = switch (section) {
      ProfileSection.profile => 'Profile',
      ProfileSection.settings => 'Settings',
      ProfileSection.security => 'Privacy and security',
      ProfileSection.help => 'Help',
      ProfileSection.about => 'About Rider',
    };
    final back = section == ProfileSection.profile
        ? null
        : TextButton.icon(
            key: const ValueKey('settings-back'),
            onPressed: () => onSection(
              section == ProfileSection.settings
                  ? ProfileSection.profile
                  : ProfileSection.settings,
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(
              section == ProfileSection.settings
                  ? 'Back to Profile'
                  : 'Back to Settings',
            ),
          );
    final content = <Widget>[];
    if (back != null) {
      content.add(Align(alignment: Alignment.centerLeft, child: back));
    }
    content.add(
      WorkspaceHeading(title, switch (section) {
        ProfileSection.profile => 'Your identity and account information.',
        ProfileSection.settings => 'Account, security and support.',
        ProfileSection.security => 'Manage your password and account security.',
        ProfileSection.help => 'A clear handoff, every step of the way.',
        ProfileSection.about =>
          'The mobile workspace for pickup and delivery couriers.',
      }),
    );
    if (section == ProfileSection.profile) {
      content.addAll([
        WorkspacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorkspaceAvatar(account.name, size: 68),
              const SizedBox(height: 20),
              Text(
                account.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(account.email),
              const SizedBox(height: 16),
              const WorkspaceBadge('Reviewed account', accent: true),
              const SizedBox(height: 24),
              _Information('Account reference', account.id),
              _Information(
                'Account status',
                account.status == 'active' ? 'Active' : account.status,
              ),
              _Information(
                'Identity review',
                account.kycStatus == 'verified' ? 'Verified' : 'Approved',
              ),
              _Information(
                'Email',
                account.emailVerified ? 'Verified' : 'Verification pending',
              ),
              if (settings.data != null)
                _Information(
                  'Mobile number',
                  settings.data!.phone ?? 'Not provided',
                ),
              TextButton.icon(
                key: const ValueKey('open-contact'),
                onPressed: () => openSettingsForm(
                  context,
                  ref,
                  account,
                  preview,
                  SettingsFlow.contact,
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Contact information'),
              ),
              TextButton.icon(
                onPressed: () {
                  onRefresh();
                  settings.load();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh account status'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        WorkspacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assignment and vehicle',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (settings.data?.managedAvailable == true)
                ...SettingsSnapshot.managedLabels.entries.map(
                  (entry) => _Information(
                    entry.value,
                    settings.data!.managed[entry.key] ?? 'Not provided',
                  ),
                )
              else
                Text(
                  settings.data != null
                      ? 'Managed assignment and vehicle details were not provided for this account. Your logistics team manages these records.'
                      : settings.available
                      ? 'Refresh account details to load your assignment and vehicle information.'
                      : 'Sign in again to refresh your account access. Your logistics team manages assignment and vehicle records.',
                ),
              if (settings.available && settings.data == null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: settings.loading ? null : settings.load,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    settings.loading ? 'Loading details…' : 'Refresh details',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        WorkspacePanel(
          padding: EdgeInsets.zero,
          child: _SettingsRow(
            key: const ValueKey('open-settings'),
            icon: Icons.settings_outlined,
            title: 'Settings',
            description: 'Security, help and sign out',
            onTap: () => onSection(ProfileSection.settings),
          ),
        ),
      ]);
    }
    if (section == ProfileSection.settings) {
      content.addAll([
        WorkspacePanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsRow(
                key: const ValueKey('settings-contact'),
                icon: Icons.contact_phone_outlined,
                title: 'Contact information',
                description: 'Mobile number and reviewed identity',
                onTap: () => openSettingsForm(
                  context,
                  ref,
                  account,
                  preview,
                  SettingsFlow.contact,
                ),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              _SettingsRow(
                key: const ValueKey('settings-emails'),
                icon: Icons.alternate_email_rounded,
                title: 'Email and recovery',
                description: 'Verified additional and contact addresses',
                onTap: () => openSettingsForm(
                  context,
                  ref,
                  account,
                  preview,
                  SettingsFlow.emails,
                ),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              _SettingsRow(
                key: const ValueKey('open-security'),
                icon: Icons.lock_outline_rounded,
                title: 'Privacy and security',
                description: 'Email verification and account management',
                onTap: () => onSection(ProfileSection.security),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              _SettingsRow(
                key: const ValueKey('open-help'),
                icon: Icons.help_outline_rounded,
                title: 'Help',
                description: 'Pickup, delivery and cash responsibilities',
                onTap: () => onSection(ProfileSection.help),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              _SettingsRow(
                key: const ValueKey('open-about'),
                icon: Icons.info_outline_rounded,
                title: 'About Rider',
                description: 'App information and licenses',
                onTap: () => onSection(ProfileSection.about),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          key: const ValueKey('settings-logout'),
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: Text(preview ? 'Exit preview' : 'Sign out'),
        ),
      ]);
    }
    if (section == ProfileSection.security) {
      content.addAll([
        WorkspacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Information('Email address', account.email),
              _Information(
                'Verification',
                account.emailVerified ? 'Verified' : 'Verification pending',
              ),
              const SizedBox(height: 8),
              const Text(
                'Password changes require your current password and verified email. Your original sign-in email stays with your account.',
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                key: const ValueKey('open-password'),
                onPressed: () => openSettingsForm(
                  context,
                  ref,
                  account,
                  preview,
                  SettingsFlow.password,
                ),
                icon: const Icon(Icons.password_rounded),
                label: const Text('Change password'),
              ),
              if (!preview) ...[
                const SizedBox(height: 20),
                const WebsiteButton(
                  page: RiderWebsitePage.recovery,
                  label: 'Forgot password',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        WorkspacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your mobile session',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your sign-in token uses secure device storage. The server checks expiry, approval and account restrictions.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Signing out ends this device session. It does not release parcels, cash or other responsibilities assigned to you.',
              ),
            ],
          ),
        ),
      ]);
    }
    if (section == ProfileSection.help) {
      content.addAll([
        const _HelpCard(
          Icons.storefront_outlined,
          'Seller pickup',
          'Claim only an available pickup permitted for you. Check the correct parcel, then bring it to its origin Bayan Hub. The hub records receipt.',
        ),
        const SizedBox(height: 16),
        const _HelpCard(
          Icons.local_shipping_outlined,
          'Assigned delivery',
          'The destination hub assigns final-mile work. Collect only the assigned parcel and follow the recorded handoff. Buyer receipt is separate from delivery.',
        ),
        const SizedBox(height: 16),
        const _HelpCard(
          Icons.account_balance_wallet_outlined,
          'Cash responsibility',
          'Cash collected is not earnings. Keep collection, hub remittance and platform reconciliation separate. Sign out does not surrender cash or parcels.',
        ),
        const SizedBox(height: 16),
        const _HelpCard(
          Icons.support_agent_rounded,
          'Need help?',
          'For an incorrect assignment, vehicle record or held parcel, contact your logistics team through the existing workflow. Do not use another rider’s account or bypass a hub handoff.',
        ),
      ]);
    }
    if (section == ProfileSection.about) {
      final info = ref.watch(appPackageProvider);
      content.addAll([
        WorkspacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandLogo(),
              const SizedBox(height: 24),
              info.when(
                data: (p) =>
                    Text('Version ${p.version} · Build ${p.buildNumber}'),
                error: (_, _) =>
                    const Text('Version information is unavailable.'),
                loading: () => const Text('Reading app version…'),
              ),
              const SizedBox(height: 16),
              const Text(
                'BagooPH Rider supports one courier role across seller pickup and final-mile delivery. Assignment, approval, custody and cash remain controlled by Bagoo.',
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'BagooPH Rider',
                  applicationVersion: info.value?.version,
                ),
                child: const Text('Open-source licenses'),
              ),
            ],
          ),
        ),
      ]);
    }
    return WorkspaceBody(
      storageKey: 'profile-${section.name}',
      children: content,
    );
  }
}

class _Information extends StatelessWidget {
  const _Information(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        SelectableText(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final IconData icon;
  final String title, description;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: RiderColors.accentText),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _HelpCard extends StatelessWidget {
  const _HelpCard(this.icon, this.title, this.text);
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => WorkspacePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: RiderColors.accentText),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text(text),
      ],
    ),
  );
}
