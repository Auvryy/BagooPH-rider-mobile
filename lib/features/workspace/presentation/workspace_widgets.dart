import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../../core/platform/rider_website.dart';
import '../data/workspace_models.dart';

class WorkspacePanel extends StatelessWidget {
  const WorkspacePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) =>
      RiderSurface(padding: padding, child: child);
}

class WorkspaceAvatar extends StatelessWidget {
  const WorkspaceAvatar(this.name, {super.key, this.size = 42});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final initials = words
        .take(2)
        .map((w) => w.characters.first)
        .join()
        .toUpperCase();
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: RiderColors.controlFill,
        foregroundColor: RiderColors.ink,
        child: Text(
          initials.isEmpty ? 'R' : initials,
          style: TextStyle(fontSize: size * .34, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class WorkspaceBadge extends StatelessWidget {
  const WorkspaceBadge(this.label, {super.key, this.accent = false});
  final String label;
  final bool accent;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: ShapeDecoration(
      color: accent ? RiderColors.rose : const Color(0xFFF1F5F9),
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(RiderRadii.selection),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: accent ? RiderColors.accentText : RiderColors.muted,
      ),
    ),
  );
}

class WorkspaceHeading extends StatelessWidget {
  const WorkspaceHeading(
    this.title,
    this.description, {
    super.key,
    this.action,
  });
  final String title, description;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
      if (description.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(description),
      ],
      const SizedBox(height: 24),
    ],
  );
}

class WorkspaceBody extends StatelessWidget {
  const WorkspaceBody({
    super.key,
    required this.children,
    this.storageKey,
    this.scrollController,
  });
  final List<Widget> children;
  final String? storageKey;
  final ScrollController? scrollController;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: scrollController,
    key: storageKey == null ? null : PageStorageKey(storageKey),
    padding: EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
      24,
      MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
      24 + MediaQuery.paddingOf(context).bottom,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [...children, const SizedBox(height: 24)],
        ),
      ),
    ),
  );
}

class WebsiteButton extends ConsumerWidget {
  const WebsiteButton({
    super.key,
    required this.page,
    this.label = 'Open Rider website',
  });
  final RiderWebsitePage page;
  final String label;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(websiteOriginProvider) == null) {
      return const SizedBox.shrink();
    }
    return RiderPressFeedback(
      child: OutlinedButton.icon(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          if (!await openRiderWebsite(ref, page)) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Could not open the Rider website. Try again.'),
              ),
            );
          }
        },
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: Text(label),
      ),
    );
  }
}

class FeatureStateView<T> extends StatelessWidget {
  const FeatureStateView({
    super.key,
    required this.data,
    required this.icon,
    required this.title,
    required this.onRetry,
    required this.ready,
    this.website,
  });
  final FeatureData<T> data;
  final IconData icon;
  final String title;
  final VoidCallback onRetry;
  final Widget Function(T) ready;
  final RiderWebsitePage? website;
  @override
  Widget build(BuildContext context) {
    if (data.data != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.status == FeatureStatus.refreshing) ...[
            const LinearProgressIndicator(
              semanticsLabel: 'Refreshing previous information',
            ),
            const SizedBox(height: 16),
          ],
          if (data.status == FeatureStatus.failed) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                '${data.message} Showing the last loaded information.',
              ),
            ),
            RiderPressFeedback(
              child: TextButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ready(data.data as T),
        ],
      );
    }
    if (data.status == FeatureStatus.loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading Rider information',
          ),
        ),
      );
    }
    return WorkspacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: ShapeDecoration(
              color: RiderColors.controlFill,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(RiderRadii.surface),
              ),
            ),
            child: Icon(icon, color: RiderColors.muted, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            data.status == FeatureStatus.failed
                ? 'Could not load $title'
                : '$title are not connected yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(data.message ?? 'Try again.'),
          const SizedBox(height: 20),
          if (data.status == FeatureStatus.failed)
            RiderPressFeedback(
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            )
          else if (website != null)
            WebsiteButton(page: website!),
        ],
      ),
    );
  }
}

class WorkspaceEmpty extends StatelessWidget {
  const WorkspaceEmpty(this.title, this.description, {super.key, this.onClear});
  final String title, description;
  final VoidCallback? onClear;
  @override
  Widget build(BuildContext context) => WorkspacePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(description),
        if (onClear != null) ...[
          const SizedBox(height: 12),
          RiderPressFeedback(
            child: TextButton(
              onPressed: onClear,
              child: const Text('Clear filters'),
            ),
          ),
        ],
      ],
    ),
  );
}
