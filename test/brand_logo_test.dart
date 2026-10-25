import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/ui/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MissingBrandBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => key.endsWith('bagoo-mark.png')
      ? Future.error(FlutterError('Missing logo'))
      : rootBundle.load(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('the Bagoo mark is included in the real asset bundle', () async {
    expect(
      (await rootBundle.load('assets/branding/bagoo-mark.png')).lengthInBytes,
      greaterThan(0),
    );
  });
  testWidgets('a missing logo stays bounded beside the profile button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRiderTheme(),
        home: Scaffold(
          body: DefaultAssetBundle(
            bundle: MissingBrandBundle(),
            child: const Center(
              child: SizedBox(
                width: 240,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          BagooBrandMark(size: 26),
                          SizedBox(width: 10),
                          Flexible(child: Text('BagooPH Rider')),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircleAvatar(child: Text('SC')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    expect(tester.getSize(find.byType(BagooBrandMark)), const Size(26, 26));
    expect(find.byType(ErrorWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
