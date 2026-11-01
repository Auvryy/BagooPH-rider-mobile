import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:bagoo_rider_mobile/features/parcels/presentation/waybill_scanner_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android scanner rejects another parcel and returns the selected normalized waybill',
    (tester) async {
      final previousScannerPlatform = MobileScannerPlatform.instance;
      final previousTargetPlatform = debugDefaultTargetPlatformOverride;
      final scannerPlatform = FakeAndroidScannerPlatform();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      MobileScannerPlatform.instance = scannerPlatform;
      try {
        String? scanResult;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: Column(
                  children: [
                    Text(scanResult ?? 'No scan result'),
                    TextButton(
                      onPressed: () async {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (_) => const WaybillScannerPage(
                              expectedWaybill: 'BGO-SELECTED-123',
                            ),
                          ),
                        );
                        setState(() => scanResult = result);
                      },
                      child: const Text('Open scanner'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open scanner'));
        await tester.pumpAndSettle();
        expect(scannerPlatform.startCount, 1);
        expect(find.text('BGO-SELECTED-123'), findsOneWidget);

        scannerPlatform.addCapture(
          const BarcodeCapture(barcodes: [Barcode(rawValue: 'BGO-OTHER-456')]),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.text(
            'That waybill belongs to another parcel. Scan the selected parcel.',
          ),
          findsOneWidget,
        );
        expect(scannerPlatform.stopCount, 0);

        scannerPlatform.addCapture(
          const BarcodeCapture(
            barcodes: [Barcode(rawValue: ' bgo-selected-123 ')],
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('BGO-SELECTED-123'), findsOneWidget);
        expect(find.text('No scan result'), findsNothing);
        expect(scannerPlatform.stopCount, 1);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        MobileScannerPlatform.instance = previousScannerPlatform;
        debugDefaultTargetPlatformOverride = previousTargetPlatform;
      }
    },
  );
}

class FakeAndroidScannerPlatform extends MobileScannerPlatform {
  final StreamController<BarcodeCapture?> _barcodeStreamController =
      StreamController<BarcodeCapture?>.broadcast();

  int startCount = 0;
  int stopCount = 0;

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodeStreamController.stream;

  @override
  Stream<TorchState> get torchStateStream =>
      Stream.value(TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    startCount++;
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(200, 200),
      numberOfCameras: 1,
    );
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Widget buildCameraView() => const SizedBox.square(dimension: 100);

  void addCapture(BarcodeCapture capture) =>
      _barcodeStreamController.add(capture);

  @override
  Future<void> dispose() => _barcodeStreamController.close();
}
