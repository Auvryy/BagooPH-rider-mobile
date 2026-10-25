import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_all/webview_all.dart';

import '../../../app/theme.dart';
import 'native_delivery_map.dart';

abstract interface class DeliveryMapSession {
  Widget get view;
  Future<void> load(String document, void Function(String) onEvent);
  Future<void> close();
}

typedef DeliveryMapFactory = DeliveryMapSession Function();
final deliveryMapDocumentProvider = Provider<Future<String> Function()>(
  (ref) => deliveryMapDocument,
);
final deliveryMapFactoryProvider = Provider<DeliveryMapFactory>(
  (ref) => _NativeDeliveryMap.new,
);

class _NativeDeliveryMap implements DeliveryMapSession {
  final controller = WebViewController(
    onPermissionRequest: (request) => request.deny(),
  );
  bool _closed = false;
  @override
  Widget get view => WebViewWidget(controller: controller);
  @override
  Future<void> load(String document, void Function(String) onEvent) async {
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(const Color(0xFFF2F1ED));
    await controller.setUserAgent('BagooPH-Rider/1.0 OpenStreetMap');
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          return request.url == 'about:blank' ||
                  request.url.startsWith('data:text/html')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent;
        },
      ),
    );
    await controller.addJavaScriptChannel(
      'BagooMap',
      onMessageReceived: (event) {
        if (!_closed) onEvent(event.message);
      },
    );
    if (!_closed) await controller.loadHtmlString(document);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await controller.removeJavaScriptChannel('BagooMap');
      await controller.loadHtmlString('<!doctype html><title>Closed</title>');
      if (await controller.isOffscreenWebViewSupported()) {
        await (await OffscreenWebViewSession.fromController(controller))
            .close();
      }
    } catch (_) {
      // Closing a removed platform view must not restore or retain its map.
    }
  }
}

Future<String> deliveryMapDocument({AssetBundle? bundle}) async {
  final assets = bundle ?? rootBundle;
  final pieces = await Future.wait([
    assets.loadString('assets/maps/leaflet/leaflet.js'),
    assets.loadString('assets/maps/leaflet/leaflet.css'),
    assets.loadString('assets/maps/rider-delivery-map.js'),
    assets.loadString('assets/maps/rider-delivery-sample.json'),
  ]);
  final font = base64Encode(
    (await assets.load('assets/fonts/PlusJakartaSans.ttf')).buffer
        .asUint8List(),
  );
  final script =
      '${pieces[0]}\nwindow.riderDeliverySample=${pieces[3]};\n${pieces[2]}'
          .replaceAll('</script', r'<\/script');
  return '''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src https://tile.openstreetmap.org data:; font-src data:; connect-src 'none'; base-uri 'none'; form-action 'none';"><style>
${pieces[1]}
@font-face{font-family:'Plus Jakarta Sans';src:url(data:font/ttf;base64,$font)}
html,body,#map{width:100%;height:100%;margin:0;background:#F2F1ED;font-family:'Plus Jakarta Sans',sans-serif}
.leaflet-container,.leaflet-control,.leaflet-tooltip{font-family:'Plus Jakarta Sans',sans-serif}
.leaflet-bar{border:1px solid #DEDEE3!important;border-radius:8px!important;box-shadow:0 1px 2px #0001!important;overflow:hidden}
.leaflet-bar a,.fit-route{box-sizing:border-box;width:48px!important;height:48px!important;line-height:48px!important;background:#FFF;color:#18181B!important;border:0;font-family:inherit;font-size:22px;cursor:pointer}
.leaflet-bar a+a{border-top:1px solid #DEDEE3}.leaflet-control-attribution{max-width:100%;white-space:normal;background:#FFF;font-size:10px;padding:4px 8px}.leaflet-tooltip{border-radius:8px;border-color:#DEDEE3}.leaflet-control a:focus-visible,.fit-route:focus-visible{outline:2px solid #E00D42;outline-offset:-2px}
</style></head><body><div id="map" role="region" aria-label="Sample rider to delivery route"></div><script>$script</script></body></html>''';
}

class LeafletDeliveryMap extends StatelessWidget {
  const LeafletDeliveryMap({super.key});

  @override
  Widget build(BuildContext context) =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux
      ? const NativeDeliveryMap()
      : const _EmbeddedLeafletDeliveryMap();
}

class _EmbeddedLeafletDeliveryMap extends ConsumerStatefulWidget {
  const _EmbeddedLeafletDeliveryMap();
  @override
  ConsumerState<_EmbeddedLeafletDeliveryMap> createState() =>
      _LeafletDeliveryMapState();
}

class _LeafletDeliveryMapState
    extends ConsumerState<_EmbeddedLeafletDeliveryMap>
    with WidgetsBindingObserver {
  DeliveryMapSession? _session;
  String? _error;
  bool _ready = false;
  int _epoch = 0;
  Timer? _timeout;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_open());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_session == null) unawaited(_open());
      return;
    }
    _epoch++;
    _timeout?.cancel();
    final old = _session;
    if (old != null) unawaited(old.close());
    if (mounted) {
      setState(() {
        _session = null;
        _ready = false;
      });
    }
  }

  Future<void> _open() async {
    final epoch = ++_epoch;
    _timeout?.cancel();
    final old = _session;
    _session = null;
    if (old != null) await old.close();
    if (!mounted || epoch != _epoch) return;
    setState(() {
      _ready = false;
      _error = null;
    });
    DeliveryMapSession? session;
    try {
      final document = await ref.read(deliveryMapDocumentProvider)();
      if (!mounted || epoch != _epoch) return;
      session = ref.read(deliveryMapFactoryProvider)();
      setState(() => _session = session);
      _timeout = Timer(const Duration(seconds: 15), () {
        if (mounted && epoch == _epoch && !_ready) {
          setState(
            () => _error = 'The street map took too long to open. Try again.',
          );
        }
      });
      await session.load(document, (event) {
        if (!mounted || epoch != _epoch) return;
        try {
          final value = jsonDecode(event);
          if (value is! Map || value.keys.length != 1) return;
          if (value['type'] == 'tiles-unavailable') {
            setState(
              () => _error = 'Street tiles could not load. You can still use task addresses.',
            );
          } else if (value['type'] == 'ready') {
            _timeout?.cancel();
            setState(() => _ready = true);
          } else if (value['type'] == 'attribution') {
            unawaited(
              launchUrl(
                Uri.parse('https://www.openstreetmap.org/copyright'),
                mode: LaunchMode.externalApplication,
              ),
            );
          }
        } catch (_) {
          /* Ignore malformed renderer events. */
        }
      });
      if (!mounted || epoch != _epoch) {
        await session.close();
        return;
      }
    } catch (_) {
      _timeout?.cancel();
      await session?.close();
      if (mounted && epoch == _epoch) {
        setState(() {
          _session = null;
          _error = 'The map could not open. Task addresses remain available.';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _epoch++;
    _timeout?.cancel();
    final session = _session;
    if (session != null) unawaited(session.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _session != null
              ? _session!.view
              : ColoredBox(
                  color: Color(0xFFF2F1ED),
                  child: Center(
                    child: Text(
                      _error == null
                          ? 'Loading street map…'
                          : 'Street map unavailable.',
                    ),
                  ),
                ),
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: RiderColors.muted),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _open,
                  child: const Text('Retry map'),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
