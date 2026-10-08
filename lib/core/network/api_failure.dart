class AccountFailure implements Exception {
  const AccountFailure(
    this.message, {
    this.status,
    this.fields = const {},
    this.retryAfterSeconds,
    this.unconfirmed = false,
  });
  final String message;
  final int? status, retryAfterSeconds;
  final Map<String, String> fields;
  final bool unconfirmed;
  bool get invalidSession => status == 401 || status == 403;
}
