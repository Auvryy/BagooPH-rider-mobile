import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'website configuration only accepts the matching HTTPS courier origin',
    () {
      expect(
        const AppConfig(
          'https://bagoo.example.test/api/v1',
          riderWebsite: 'https://courier.bagoo.example.test',
        ).websiteOrigin?.origin,
        'https://courier.bagoo.example.test',
      );
      for (final website in [
        'http://courier.bagoo.example.test',
        'https://foreign.example.test',
        'https://courier.bagoo.example.test/path',
        'https://user:secret@courier.bagoo.example.test',
        'https://courier.bagoo.example.test?token=test',
        'https://courier.bagoo.example.test:8443',
      ]) {
        expect(
          () => AppConfig(
            'https://bagoo.example.test/api/v1',
            riderWebsite: website,
          ).websiteOrigin,
          throwsFormatException,
        );
      }
      expect(
        const AppConfig('https://bagoo.example.test/api/v1').websiteOrigin,
        isNull,
      );
    },
  );
}
