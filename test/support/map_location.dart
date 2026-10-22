import 'dart:async';

import 'package:bagoo_rider_mobile/features/navigation/data/foreground_map_location.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';

class TestMapLocation implements ForegroundMapLocation {
  MapLocationAccess permission = MapLocationAccess.granted;
  Completer<MapLocationAccess>? permissionReply;
  Completer<void>? cancellationReply;
  final requests = <bool>[];
  final streams = <StreamController<LocationFix>>[];
  int cancelled = 0;

  @override
  Future<MapLocationAccess> access({required bool requestPermission}) {
    requests.add(requestPermission);
    return permissionReply?.future ?? Future.value(permission);
  }

  @override
  Stream<LocationFix> fixes() {
    final reply = cancellationReply;
    final stream = StreamController<LocationFix>(
      onCancel: () async {
        cancelled++;
        await reply?.future;
      },
    );
    streams.add(stream);
    return stream.stream;
  }

  Future<void> close() async {
    for (final stream in streams) {
      await stream.close();
    }
  }
}
