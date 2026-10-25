import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/leaflet_delivery_map.dart';

class FakeDeliveryMapSession implements DeliveryMapSession {
  String? document;
  void Function(String)? event;
  Completer<void>? pending;
  Object? error;
  int closes = 0;
  @override
  Widget get view => const ColoredBox(
    color: Color(0xFFF2F1ED),
    child: Center(child: Text('Leaflet test view')),
  );
  @override
  Future<void> load(String value, void Function(String) onEvent) async {
    document = value;
    event = onEvent;
    if (pending != null) await pending!.future;
    if (error != null) throw error!;
    if (closes == 0) onEvent('{"type":"ready"}');
  }

  @override
  Future<void> close() async {
    if (closes == 0) closes++;
  }
}
