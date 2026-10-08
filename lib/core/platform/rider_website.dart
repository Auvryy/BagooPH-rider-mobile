import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/auth/presentation/auth_controller.dart';

enum RiderWebsitePage {
  tasks('/deliveries'),
  trips('/earnings'),
  messages('/messages'),
  profile('/profile'),
  settings('/account/settings'),
  recovery('/forgot-password');

  const RiderWebsitePage(this.path);
  final String path;
}

abstract interface class WebsiteLauncher {
  Future<bool> open(Uri uri);
}

class SystemWebsiteLauncher implements WebsiteLauncher {
  const SystemWebsiteLauncher();
  @override
  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

final websiteLauncherProvider = Provider<WebsiteLauncher>(
  (ref) => const SystemWebsiteLauncher(),
);
final websiteOriginProvider = Provider<Uri?>((ref) {
  try {
    return ref.watch(appConfigProvider).websiteOrigin;
  } on FormatException {
    return null;
  }
});

/// Only fixed, verified first-party destinations. No bearer or account details
/// are put in a browser URL; the website uses its own browser session.
Future<bool> openRiderWebsite(WidgetRef ref, RiderWebsitePage page) async {
  final origin = ref.read(websiteOriginProvider);
  if (origin == null) return false;
  try {
    return await ref
        .read(websiteLauncherProvider)
        .open(origin.resolve(page.path));
  } catch (_) {
    return false;
  }
}
