import 'dart:async';

import 'package:dio/dio.dart';

enum ProviderRequestKind { tile, route }

/// Geoapify tiles cost 1/4 credit. Keep a rolling four-credit budget, below
/// the free account's five credits/s, and leave navigation ahead of queued tiles.
/// This is a per-client budget; other devices using the key share its quota.
class ProviderScheduler {
  ProviderScheduler({DateTime Function()? now}) : now = now ?? DateTime.now;

  final DateTime Function() now;
  final _pending = <_WaitingRequest>[];
  final _started = <({DateTime at, int units})>[];
  Timer? _timer;
  DateTime? _lastStart;
  int _active = 0;
  bool _disposed = false;

  Future<void> acquire(
    CancelToken? cancel, {
    ProviderRequestKind kind = ProviderRequestKind.route,
  }) {
    if (cancel?.isCancelled == true) return Future.error(cancel!.cancelError!);
    if (_disposed) return Future.error(StateError('Map provider stopped.'));
    final request = _WaitingRequest(cancel, kind);
    _pending.add(request);
    cancel?.whenCancel.then((error) {
      if (_pending.remove(request)) {
        request.ready.completeError(error);
        _pump();
      }
    });
    _pump();
    return request.ready.future;
  }

  void _pump() {
    _timer?.cancel();
    _timer = null;
    if (_disposed || _pending.isEmpty || _active >= 6) return;
    final time = now();
    _started.removeWhere(
      (r) => time.difference(r.at) >= const Duration(seconds: 1),
    );
    final request = _pending.firstWhere(
      (r) => r.kind == ProviderRequestKind.route,
      orElse: () => _pending.first,
    );
    var wait = _lastStart == null
        ? Duration.zero
        : const Duration(milliseconds: 75) - time.difference(_lastStart!);
    var used = _started.fold(0, (sum, r) => sum + r.units);
    for (final previous in _started) {
      if (used + request.units <= 16) break;
      final until = const Duration(seconds: 1) - time.difference(previous.at);
      if (until > wait) wait = until;
      used -= previous.units;
    }
    if (wait > Duration.zero) {
      _timer = Timer(wait, _pump);
      return;
    }
    _pending.remove(request);
    _lastStart = time;
    _active++;
    _started.add((at: time, units: request.units));
    request.ready.complete();
    if (_pending.isNotEmpty) {
      _timer = Timer(const Duration(milliseconds: 75), _pump);
    }
  }

  /// Release one network slot, including failures/cancellation. Cached tiles
  /// never acquire a slot or consume the provider budget.
  void release() {
    if (_active > 0) _active--;
    _pump();
  }

  void dispose() {
    _disposed = true;
    rejectPending(StateError('Map provider stopped.'));
  }

  /// A quota/key denial should fail queued work promptly, without spending
  /// further budget or waiting through an entire old viewport.
  void rejectPending(Object error) {
    _timer?.cancel();
    _timer = null;
    for (final request in _pending) {
      request.ready.completeError(error);
    }
    _pending.clear();
  }
}

class _WaitingRequest {
  _WaitingRequest(this.cancel, this.kind);
  final CancelToken? cancel;
  final ProviderRequestKind kind;
  final ready = Completer<void>();
  int get units => kind == ProviderRequestKind.tile ? 1 : 4;
}
