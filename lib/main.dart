import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
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
    const bagooRed = Color(0xFFE00D42);

    return MaterialApp(
      title: 'BagooPH Rider',
      debugShowCheckedModeBanner: false,
      locale: useDevicePreview ? DevicePreview.locale(context) : null,
      builder: useDevicePreview ? DevicePreview.appBuilder : null,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: bagooRed),
        scaffoldBackgroundColor: const Color(0xFFFFFAFB),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: bagooRed,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'BagooPH Rider',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pickup and delivery rider app.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
