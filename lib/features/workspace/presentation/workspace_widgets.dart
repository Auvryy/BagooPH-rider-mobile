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
    this.accentGlow = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool accentGlow;
  @override
  Widget build(BuildContext context) =>
      RiderSurface(padding: padding, accentGlow: accentGlow, child: child);
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
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              RiderColors.accentGlow,
              RiderColors.accent,
            ],
          ),
          border: Border.all(color: Colors.white, width: 2.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFFFFFFF),
              blurRadius: 6,
              offset: Offset(-2, -2),
            ),
            BoxShadow(
              color: Color(0x28E00D42),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          initials.isEmpty ? 'R' : initials,
          style: TextStyle(
            fontSize: size * .34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: ShapeDecoration(
      gradient: accent
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF0F4), Color(0xFFFFE2EA)],
            )
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF1F5FB)],
            ),
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(RiderRadii.pill),
        side: const BorderSide(color: Colors.white, width: 2.0),
      ),
      shadows: [
        const BoxShadow(
          color: Color(0xFFFFFFFF),
          blurRadius: 6,
          offset: Offset(-2, -2),
        ),
        BoxShadow(
          color: accent ? const Color(0x1FE00D42) : const Color(0x120F172A),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
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
          if (action != null) ...[
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(RiderRadii.control),
                  side: const BorderSide(color: Colors.white, width: 1.5),
                ),
                shadows: RiderShadows.neumorphicElevated,
              ),
              child: action!,
            ),
          ],
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
      20,
      MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
      28 + MediaQuery.paddingOf(context).bottom,
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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [RiderColors.rose, Colors.white],
              ),
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(RiderRadii.control),
                side: const BorderSide(color: Colors.white, width: 1.5),
              ),
              shadows: RiderShadows.neumorphicElevated,
            ),
            child: Icon(icon, color: RiderColors.accentText, size: 28),
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: ShapeDecoration(
            color: RiderColors.rose,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
          child: const Icon(
            Icons.inbox_outlined,
            size: 26,
            color: RiderColors.accentText,
          ),
        ),
        const SizedBox(height: 16),
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
