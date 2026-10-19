String notificationTime(DateTime utc) {
  final time = utc.toUtc().add(const Duration(hours: 8));
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${time.day} ${months[time.month - 1]} ${time.year} · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} PHT';
}

String notificationPeso(String cents) {
  final amount = BigInt.parse(cents);
  final whole = (amount ~/ BigInt.from(100)).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '₱$whole.${(amount % BigInt.from(100)).toString().padLeft(2, '0')}';
}
