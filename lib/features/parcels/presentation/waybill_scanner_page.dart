import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme.dart';
import '../../../core/commands/parcel_validation.dart';
import '../../../core/network/api_failure.dart';

bool get supportsParcelCamera =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Supports camera-based barcode detection with clear on-device privacy protection
/// and manual typing fallback.
class WaybillScannerPage extends StatefulWidget {
  const WaybillScannerPage({
    super.key,
    required this.expectedWaybill,
    this.orderReference,
    this.authorization,
    this.isAuthorized,
  });
  final String expectedWaybill;
  final String? orderReference;
  final Listenable? authorization;
  final bool Function()? isAuthorized;
  @override
  State<WaybillScannerPage> createState() => _WaybillScannerPageState();
}

class _WaybillScannerPageState extends State<WaybillScannerPage>
    with WidgetsBindingObserver {
  final TextEditingController _manualInput = TextEditingController();
  MobileScannerController? _camera;
  bool _finishing = false;
  bool _showManualEntry = false;
  String? _notice;
  bool get _authorized => widget.isAuthorized?.call() ?? true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.authorization?.addListener(_checkAccess);
    if (supportsParcelCamera) {
      _camera = MobileScannerController(autoStart: false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  void _checkAccess() {
    if (!mounted || _authorized || _finishing) return;
    _finishing = true;
    unawaited(_stopCamera());
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _stopCamera() async {
    try {
      await _camera?.stop();
    } catch (_) {
      /* Camera may already be closed. */
    }
  }

  Future<void> _start() async {
    if (!mounted || _finishing || _camera == null || !_authorized) return;
    try {
      await _camera!.start();
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice =
              'Camera unavailable. Check camera permission and try again.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_camera == null || !_camera!.value.hasCameraPermission || _finishing) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_start());
    } else {
      unawaited(_stopCamera());
    }
  }

  Future<void> _detected(BarcodeCapture capture) async {
    if (!mounted || _finishing || !_authorized) return;
    try {
      final codes = <String>{};
      for (final barcode in capture.barcodes) {
        final raw = barcode.rawValue;
        if (raw != null) {
          try {
            codes.add(parcelWaybill(raw));
          } on AccountFailure {
            /* Keep scanning. */
          }
        }
      }
      if (codes.length != 1) {
        setState(
          () => _notice = codes.isEmpty
              ? 'Move closer to the parcel barcode or QR waybill code.'
              : 'Several codes are visible. Frame just this parcel’s waybill.',
        );
        return;
      }
      final actual = codes.single;
      if (actual != widget.expectedWaybill) {
        setState(
          () => _notice = 'That waybill belongs to another parcel. Scan the selected parcel.',
        );
        return;
      }
      _finishing = true;
      await _camera?.stop();
      if (mounted) Navigator.of(context).pop(actual);
    } catch (_) {
      _finishing = false;
      if (mounted) {
        setState(
          () => _notice = 'Could not read that waybill. Try scanning again.',
        );
      }
    }
  }

  void _submitManualWaybill() {
    if (!mounted || _finishing || !_authorized) return;
    final text = _manualInput.text.trim();
    if (text.isEmpty) {
      setState(() => _notice = 'Enter the parcel waybill number.');
      return;
    }
    try {
      final actual = parcelWaybill(text);
      if (actual != widget.expectedWaybill) {
        setState(
          () => _notice =
              'That waybill belongs to another parcel. Scan or enter the selected parcel.',
        );
        return;
      }
      _finishing = true;
      unawaited(_stopCamera());
      if (mounted) Navigator.of(context).pop(actual);
    } on AccountFailure catch (e) {
      setState(() => _notice = e.message);
    }
  }

  @override
  void dispose() {
    _finishing = true;
    _manualInput.dispose();
    WidgetsBinding.instance.removeObserver(this);
    widget.authorization?.removeListener(_checkAccess);
    unawaited(_camera?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan parcel waybill')),
    body: !_authorized
        ? const Center(child: Text('This parcel is no longer available.'))
        : SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _camera == null
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Waybill capture requires an Android camera. You can browse your tasks on this device.',
                            ),
                          ),
                        )
                      : MobileScanner(
                          controller: _camera,
                          onDetect: _detected,
                          errorBuilder: (context, error) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Camera access is unavailable. Enable camera permission for Rider, then try again.',
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: _start,
                                    child: const Text('Try camera again'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
                Flexible(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          key: const ValueKey('camera-privacy-banner'),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: RiderColors.redTint,
                            borderRadius: BorderRadius.circular(
                              RiderRadii.group,
                            ),
                            border: Border.all(
                              color: RiderColors.accent.withAlpha(40),
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.privacy_tip_outlined,
                                size: 18,
                                color: RiderColors.accentText,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Camera Privacy: Video stream is analyzed on-device strictly for waybill barcode detection. No video is recorded or stored.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: RiderColors.accentText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: RiderColors.accent,
                                borderRadius: BorderRadius.circular(
                                  RiderRadii.pill,
                                ),
                              ),
                              child: const Text(
                                'WAYBILL TO SCAN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.expectedWaybill,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.orderReference != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.orderReference!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: RiderColors.muted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'Frame the actual barcode or QR code on this parcel. Scanning does not confirm collection or delivery.',
                        ),
                        if (_notice != null) ...[
                          const SizedBox(height: 12),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _notice!,
                              style: const TextStyle(
                                color: RiderColors.accentText,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (!_showManualEntry)
                          OutlinedButton.icon(
                            key: const ValueKey('manual-waybill-toggle'),
                            icon: const Icon(Icons.keyboard_outlined),
                            label: const Text('Enter waybill manually'),
                            onPressed: () =>
                                setState(() => _showManualEntry = true),
                          )
                        else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const ValueKey('manual-waybill-input'),
                                  controller: _manualInput,
                                  decoration: const InputDecoration(
                                    labelText: 'Type waybill number',
                                    hintText: 'e.g. BGO-12345678',
                                    isDense: true,
                                  ),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  onSubmitted: (_) => _submitManualWaybill(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                key: const ValueKey('manual-waybill-submit'),
                                onPressed: _submitManualWaybill,
                                child: const Text('Submit'),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _showManualEntry = false),
                            child: const Text('Cancel manual entry'),
                          ),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('Cancel scan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
}
