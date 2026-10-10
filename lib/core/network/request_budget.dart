import 'dart:collection';

import 'api_failure.dart';

/// Shared by all first-party requests in the native session transport. The
/// server remains authoritative across other devices/IPs and may return 429.
class NativeRequestBudget {
  NativeRequestBudget({DateTime Function()? now}) : now = now ?? DateTime.now;
  final DateTime Function() now;
  final _reads = Queue<DateTime>(), _writes = Queue<DateTime>();
  void reserve(String method) {
    final current = now();
    final boundary = current.subtract(const Duration(minutes: 1));
    for (final queue in [_reads, _writes]) {
      while (queue.isNotEmpty && !queue.first.isAfter(boundary)) {
        queue.removeFirst();
      }
    }
    final write = method != 'GET';
    final full = _reads.length >= 30
        ? _reads
        : write && _writes.length >= 10
        ? _writes
        : null;
    if (full != null) {
      final retry =
          ((full.first
                      .add(const Duration(minutes: 1))
                      .difference(current)
                      .inMilliseconds) /
                  1000)
              .ceil()
              .clamp(1, 60);
      throw AccountFailure(
        'Too many requests. Please wait before refreshing.',
        status: 429,
        code: 'CLIENT_REQUEST_BUDGET',
        retryAfterSeconds: retry,
      );
    }
    _reads.addLast(current);
    if (write) _writes.addLast(current);
  }
}
