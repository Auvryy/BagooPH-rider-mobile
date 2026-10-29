import '../../../core/commands/cash_validation.dart';
import '../../../core/network/wire.dart';

/// Earned shipping shares, never a total inferred from collected COD.
class RiderEarnings {
  RiderEarnings.fromJson(Object? value) {
    final json = Wire.object(value);
    available = Wire.boolean(json['available']);
    if (available) {
      if (json['basis'] != 'original_delivery_earnings_ledger') Wire.invalid();
      confirmed = cashCents(json['confirmed_cents']);
      pending = cashCents(json['pending_cents']);
    } else {
      if (json['confirmed_cents'] != null || json['pending_cents'] != null) {
        Wire.invalid();
      }
      confirmed = pending = null;
    }
  }

  late final bool available;
  late final BigInt? confirmed, pending;
}

/// The server owns shift closure and the original cash responsibility.
class RiderShiftSummary {
  RiderShiftSummary.fromJson(Map<String, dynamic> json)
    : id = _id(json['shift_id']),
      startedAt = json['started_at'] == null
          ? null
          : Wire.time(json['started_at']),
      collected = cashCents(json['collected_cents']),
      remitted = cashCents(json['remitted_cents']),
      held = cashCents(json['held_cents']),
      pendingHandovers = Wire.count(json['pending_handovers']),
      unresolvedDifferences = Wire.count(json['unresolved_differences']),
      canClose = Wire.boolean(json['can_close']) {
    if (canClose &&
        (held != BigInt.zero ||
            pendingHandovers != 0 ||
            unresolvedDifferences != 0)) {
      Wire.invalid();
    }
  }

  static String? _id(Object? value) {
    if (value == null) return null;
    return Wire.id(value is int ? '$value' : value);
  }

  final String? id;
  final DateTime? startedAt;
  final BigInt collected, remitted, held;
  final int pendingHandovers, unresolvedDifferences;
  final bool canClose;
}
