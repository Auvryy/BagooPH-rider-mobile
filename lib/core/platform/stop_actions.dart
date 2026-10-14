import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

abstract interface class StopActions {
  Future<void> copy(String text);
  Future<bool> open(Uri uri);
}

class PlatformStopActions implements StopActions {
  const PlatformStopActions();

  @override
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  @override
  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Accept common phone formatting without allowing other URI schemes, dial
/// codes or an arbitrary query to pass through the external launcher.
Uri? stopPhoneUri(String? value) {
  if (value == null) return null;
  final phone = value.trim().replaceAll(RegExp(r'[ ().-]'), '');
  if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) return null;
  return Uri(scheme: 'tel', path: phone);
}
