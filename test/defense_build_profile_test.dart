import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defense profile enables only accepted duty and claim writes', () {
    final config = AppConfig.environment();
    expect(config.origin.toString(), 'https://bagooph.shop/api/v1');
    expect(config.websiteOrigin?.origin, 'https://courier.bagooph.shop');
    expect(config.localAuth, isFalse);
    expect(config.operationsWritesVerified, isTrue);
    expect(config.parcelWritesVerified, isFalse);
    expect(config.prepaidDeliveryWritesVerified, isFalse);
    expect(config.cashWritesVerified, isFalse);
    expect(config.messagesWritesVerified, isFalse);
    expect(config.notificationsWritesVerified, isFalse);
    expect(config.handoverWritesVerified, isFalse);
  }, skip: !const bool.fromEnvironment('VERIFY_DEFENSE_PROFILE'));
}
