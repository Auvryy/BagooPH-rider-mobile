import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/theme.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../auth/data/account.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';
import '../data/settings_models.dart';
import 'settings_controller.dart';
import 'settings_forms.dart';

enum ProfileSection {
  profile,
  settings,
  account,
  assignment,
  vehicle,
  help,
  about;

  ProfileSection get parent => switch (this) {
    settings || account || assignment || vehicle => profile,
    help || about => settings,
    profile => profile,
  };
}

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
    final signingOut = ref.watch(authControllerProvider.select((s) => s.busy));
    void form(SettingsFlow flow) =>
        openSettingsForm(context, ref, account, preview, flow);
    final title = switch (section) {
      ProfileSection.profile => 'Profile',
      ProfileSection.settings => 'Settings',
      ProfileSection.account => 'Account details',
      ProfileSection.assignment => 'Assignment',
      ProfileSection.vehicle => 'Vehicle and credentials',
      ProfileSection.help => 'Help',
      ProfileSection.about => 'About Rider',
    };
    final content = <Widget>[
      if (section != ProfileSection.profile)
        Row(
          children: [
            RiderPressFeedback(
              child: IconButton(
                key: const ValueKey('settings-back'),
                tooltip: section.parent == ProfileSection.profile
                    ? 'Back to Profile'
                    : 'Back to Settings',
                onPressed: () => onSection(section.parent),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        )
      else
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
    ];

    switch (section) {
      case ProfileSection.profile:
        content.addAll([
          _SettingsGroup(
            children: [
              RiderPressFeedback(
                child: InkWell(
                  key: const ValueKey('open-account'),
                  onTap: () => onSection(ProfileSection.account),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        WorkspaceAvatar(account.name, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                account.email,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Account details',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: RiderColors.accentText),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: RiderColors.muted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            children: [
              _SettingsRow(
                key: const ValueKey('open-settings'),
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => onSection(ProfileSection.settings),
              ),
            ],
          ),
          const _GroupTitle('Work information'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                key: const ValueKey('open-assignment'),
                icon: Icons.location_on_outlined,
                title: 'Assignment',
                onTap: () => onSection(ProfileSection.assignment),
              ),
              _SettingsRow(
                key: const ValueKey('open-vehicle'),
                icon: Icons.two_wheeler_outlined,
                title: 'Vehicle and credentials',
                onTap: () => onSection(ProfileSection.vehicle),
              ),
            ],
          ),
        ]);
      case ProfileSection.settings:
        content.addAll([
          const _GroupTitle('Account', top: 0),
          _SettingsGroup(
            children: [
              _SettingsRow(
                key: const ValueKey('settings-contact'),
                icon: Icons.contact_phone_outlined,
                title: 'Contact information',
                onTap: () => form(SettingsFlow.contact),
              ),
              _SettingsRow(
                key: const ValueKey('settings-emails'),
                icon: Icons.alternate_email_rounded,
                title: 'Email and recovery',
                onTap: () => form(SettingsFlow.emails),
              ),
              _SettingsRow(
                key: const ValueKey('open-password'),
                icon: Icons.lock_outline_rounded,
                title: 'Change password',
                onTap: () => form(SettingsFlow.password),
              ),
            ],
          ),
          const _GroupTitle('Support'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                key: const ValueKey('open-help'),
                icon: Icons.help_outline_rounded,
                title: 'Help',
                onTap: () => onSection(ProfileSection.help),
              ),
              _SettingsRow(
                key: const ValueKey('open-about'),
                icon: Icons.info_outline_rounded,
                title: 'About Rider',
                onTap: () => onSection(ProfileSection.about),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            children: [
              _SettingsRow(
                key: const ValueKey('settings-logout'),
                icon: Icons.logout_rounded,
                title: preview
                    ? 'Exit preview'
                    : signingOut
                    ? 'Signing out…'
                    : 'Sign out',
                destructive: true,
                disclosure: false,
                onTap: signingOut && !preview ? null : onLogout,
              ),
            ],
          ),
        ]);
      case ProfileSection.account:
        content.addAll([
          _SettingsGroup(
            children: [
              _Information('Name', account.name),
              _Information('Sign-in email', account.email),
              _Information('Account status', _readable(account.status)),
              _Information('Identity review', _readable(account.kycStatus)),
              _Information(
                'Email verification',
                account.emailVerified ? 'Verified' : 'Pending',
              ),
              _Information('Account reference', account.id),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your reviewed name and original sign-in email stay with your account.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          RiderPressFeedback(
            child: TextButton.icon(
              key: const ValueKey('refresh-account'),
              onPressed: () {
                onRefresh();
                settings.load();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh details'),
            ),
          ),
        ]);
      case ProfileSection.assignment:
      case ProfileSection.vehicle:
        if (settings.data?.managedAvailable == true) {
          final keys = section == ProfileSection.assignment
              ? ['company', 'hub', 'hub_code', 'barangay']
              : [
                  'vehicle_type',
                  'vehicle_model',
                  'plate_number',
                  'fleet_status',
                  'license_number',
                  'registration_status',
                ];
          content.add(
            _SettingsGroup(
              children: [
                for (final key in keys)
                  _Information(
                    SettingsSnapshot.managedLabels[key]!,
                    [
                          'vehicle_type',
                          'fleet_status',
                          'registration_status',
                        ].contains(key)
                        ? _readable(settings.data!.managed[key])
                        : settings.data!.managed[key] ?? 'Not provided',
                  ),
              ],
            ),
          );
          content.addAll([
            const SizedBox(height: 12),
            Text(
              'Managed by your logistics team.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ]);
        } else {
          content.add(
            WorkspacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (settings.loading) const LinearProgressIndicator(),
                  Text(
                    settings.data != null
                        ? 'These details were not provided for your account. Your logistics team manages these records.'
                        : settings.available
                        ? 'Could not load these details. Try refreshing.'
                        : 'Sign in again to refresh your account access.',
                  ),
                  if (settings.available) ...[
                    const SizedBox(height: 12),
                    RiderPressFeedback(
                      child: TextButton.icon(
                        onPressed: settings.loading ? null : settings.load,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Refresh details'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
      case ProfileSection.help:
        content.add(
          _SettingsGroup(
            children: const [
              _HelpItem(
                Icons.storefront_outlined,
                'Seller pickup',
                'Claim an eligible pickup, verify the parcel and take it to its assigned origin Bayan Hub. The hub records intake.',
              ),
              _HelpItem(
                Icons.local_shipping_outlined,
                'Assigned delivery',
                'Your destination hub assigns final-mile work. Follow its handoff and record the outcome. Buyer receipt is a separate step.',
              ),
              _HelpItem(
                Icons.account_balance_wallet_outlined,
                'Cash responsibility',
                'Collected cash is separate from earnings. Keep collection, hub remittance and platform reconciliation separate. Signing out does not release parcels or cash.',
              ),
              _HelpItem(
                Icons.support_agent_rounded,
                'Contact your logistics team',
                'Ask your logistics team about an incorrect assignment, vehicle record or held parcel. Use your own account and the recorded hub handoff.',
              ),
            ],
          ),
        );
      case ProfileSection.about:
        final info = ref.watch(appPackageProvider);
        content.addAll([
          _SettingsGroup(
            children: [
              const _Information('App', 'BagooPH Rider'),
              info.when(
                data: (p) =>
                    _Information('Version', '${p.version} (${p.buildNumber})'),
                error: (_, _) => const _Information('Version', 'Unavailable'),
                loading: () => const _Information('Version', 'Loading…'),
              ),
              _SettingsRow(
                icon: Icons.description_outlined,
                title: 'Open-source licenses',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'BagooPH Rider',
                  applicationVersion: info.value?.version,
                ),
              ),
            ],
          ),
        ]);
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: PageStorageKey('profile-${section.name}'),
        padding: EdgeInsets.fromLTRB(
          constraints.maxWidth < 600 ? 16 : 24,
          16,
          constraints.maxWidth < 600 ? 16 : 24,
          24,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
          ),
        ),
      ),
    );
  }
}

String _readable(String? value) {
  if (value == null || value.isEmpty) return 'Not provided';
  final text = value.replaceAll('_', ' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text, {this.top = 20});
  final String text;
  final double top;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(4, top, 4, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: RiderColors.muted),
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => RiderSurface(
    radius: RiderRadii.group,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 52, endIndent: 16),
          children[i],
        ],
      ],
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
    this.disclosure = true,
  });
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool destructive, disclosure;
  @override
  Widget build(BuildContext context) => RiderPressFeedback(
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: destructive ? RiderColors.accentText : RiderColors.muted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: destructive
                        ? RiderColors.accentText
                        : RiderColors.ink,
                  ),
                ),
              ),
              if (disclosure) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: RiderColors.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _Information extends StatelessWidget {
  const _Information(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        SelectableText(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

class _HelpItem extends StatelessWidget {
  const _HelpItem(this.icon, this.title, this.text);
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    shape: const Border(),
    collapsedShape: const Border(),
    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    leading: Icon(icon, size: 22, color: RiderColors.muted),
    title: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w500),
    ),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
      ),
    ],
  );
}
