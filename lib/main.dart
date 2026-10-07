import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/theme.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Plus Jakarta Sans'], license);
  });

  const previewRequested = bool.fromEnvironment(
    'DEVICE_PREVIEW',
    defaultValue: true,
  );
  final previewEnabled =
      kDebugMode &&
      previewRequested &&
      (kIsWeb || defaultTargetPlatform == TargetPlatform.linux);
  runApp(
    previewEnabled
        ? DevicePreview(
            builder: (_) => const BagooRiderApp(useDevicePreview: true),
          )
        : const BagooRiderApp(),
  );
}

class BagooRiderApp extends StatelessWidget {
  const BagooRiderApp({super.key, this.useDevicePreview = false});
  final bool useDevicePreview;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BagooPH Rider',
      debugShowCheckedModeBanner: false,
      locale: useDevicePreview ? DevicePreview.locale(context) : null,
      builder: useDevicePreview ? DevicePreview.appBuilder : null,
      theme: buildRiderTheme(),
      routes: {
        '/': (_) => const LoginPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
      },
    );
  }
}
