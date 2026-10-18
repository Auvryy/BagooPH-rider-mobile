/// Exact values from the accepted Rider API. Do not round identifiers or money.
class Wire {
  static Never invalid() =>
      throw const FormatException('The work response could not be verified.');
  static Map<String, dynamic> object(Object? v) =>
      v is Map<String, dynamic> ? v : invalid();
  static String string(Object? v) => v is String ? v : invalid();
  static String? nullableString(Object? v) => v == null ? null : string(v);
  static bool boolean(Object? v) => v is bool ? v : invalid();
  static int count(Object? v) => v is int && v >= 0 ? v : invalid();
  static String id(Object? v) {
    final s = string(v);
    if (RegExp(r'^[1-9][0-9]*$').firstMatch(s)?.end != s.length ||
        s.length > 19 ||
        BigInt.parse(s) > BigInt.parse('9223372036854775807')) {
      invalid();
    }
    return s;
  }

  static String version(Object? v) {
    final s = string(v);
    if (RegExp(r'^[a-f0-9]{64}$').firstMatch(s)?.end != s.length) invalid();
    return s;
  }

  static String uuid(Object? v) {
    final s = string(v);
    if (RegExp(r'^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$')
            .firstMatch(s)
            ?.end !=
        s.length) {
      invalid();
    }
    return s;
  }

  static DateTime time(Object? v) {
    final s = string(v);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$').hasMatch(s)) {
      invalid();
    }
    final parsed = DateTime.tryParse(s);
    if (parsed == null || parsed.toIso8601String() != s) invalid();
    return parsed;
  }

  static String taskId(Object? v) {
    final s = string(v);
    final m = RegExp(r'^(pickup|final_mile)-([1-9][0-9]*)$').firstMatch(s);
    if (m == null || m.end != s.length) invalid();
    id(m[2]);
    return s;
  }

  static Map<String, bool> flags(Object? v) =>
      Map.unmodifiable(object(v).map((k, v) => MapEntry(k, boolean(v))));
  static Map<String, int> counts(Object? v) =>
      Map.unmodifiable(object(v).map((k, v) => MapEntry(k, count(v))));
}
