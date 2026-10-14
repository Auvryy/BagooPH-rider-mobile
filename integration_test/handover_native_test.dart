import 'dart:convert';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/features/handover/data/handover_intent.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:crypto/crypto.dart';

Uint8List twoPagePdf() {
  const blue = '0 0 1 rg 0 0 80 80 re f\n';
  const red = '1 0 0 rg 80 80 80 80 re f\n';
  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] /Contents 5 0 R >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] /Contents 6 0 R >>',
    '<< /Length ${utf8.encode(blue).length} >>\nstream\n${blue}endstream',
    '<< /Length ${utf8.encode(red).length} >>\nstream\n${red}endstream',
  ];
  var pdf = '%PDF-1.4\n';
  final offsets = <int>[0];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(utf8.encode(pdf).length);
    pdf += '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
  }
  final xref = utf8.encode(pdf).length;
  pdf += 'xref\n0 ${objects.length + 1}\n0000000000 65535 f \n';
  for (final offset in offsets.skip(1)) {
    pdf += '${offset.toString().padLeft(10, '0')} 00000 n \n';
  }
  pdf +=
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n';
  return Uint8List.fromList(utf8.encode(pdf));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native protected journal retains the original maximum-size report once across re-creation',
    (tester) async {
      final journal = SecureHandoverJournal(
        origin: Uri.parse('https://handover-native-check.invalid/api/v1'),
        accountId: '1',
      );
      // This isolated synthetic namespace never reads/replaces a real Rider session.
      expect(await journal.read(), isNull);
      final bytes = Uint8List(evidenceLimit)
        ..setRange(0, 8, [137, 80, 78, 71, 13, 10, 26, 10]);
      final original = HandoverIntent(
        accountId: '1',
        key: commandUuid(),
        action: 'handover.report',
        resource: 'handover-report',
        body: {
          'barcode': 'BGO-NATIVE-CHECK',
          'kind': 'missed_scan',
          'reported_holder': 'Synthetic test holder',
          'reported_location': 'Synthetic test location',
          'notes': 'Native protected retention regression.',
        },
        createdAt: DateTime.now().toUtc(),
        file: HandoverFile(bytes, 'png'),
      );
      try {
        await journal.write(original);
        final restored = await SecureHandoverJournal(
          origin: Uri.parse('https://handover-native-check.invalid/api/v1'),
          accountId: '1',
        ).read();
        expect(restored!.key, original.key);
        expect(restored.file!.bytes.length, evidenceLimit);
        expect(restored.file!.digest, original.file!.digest);
        expect(restored.body, original.body);
        final other = SecureHandoverJournal(
          origin: Uri.parse('https://handover-native-check.invalid/api/v1'),
          accountId: '2',
        );
        expect(await other.read(), isNull);
        expect(
          await SecureHandoverJournal(
            origin: Uri.parse('https://other-native-check.invalid/api/v1'),
            accountId: '1',
          ).read(),
          isNull,
        );
      } finally {
        await journal.clear();
      }
      expect(await journal.read(), isNull);
    },
  );
  testWidgets(
    'native PDF renderer opens both pages of private in-memory bytes',
    (tester) async {
      pdfrxFlutterInitialize();
      final bytes = twoPagePdf();
      final document = await PdfDocument.openData(
        bytes,
        sourceName: 'synthetic-native-evidence',
      );
      try {
        expect(document.pages.length, 2);
        final rendered = <String>[];
        for (final page in document.pages) {
          final image = await page.render(width: 100, height: 100);
          expect(image, isNotNull);
          expect(image!.pixels, isNotEmpty);
          rendered.add(sha256.convert(image.pixels).toString());
          image.dispose();
        }
        expect(rendered.toSet().length, 2);
      } finally {
        await document.dispose();
      }
      var viewerReady = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfViewer.data(
              bytes,
              sourceName: 'synthetic-native-viewer',
              params: PdfViewerParams(
                onViewerReady: (document, controller) =>
                    viewerReady = document.pages.length == 2,
                linkWidgetBuilder: (context, link, size) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 15));
      while (!viewerReady && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(PdfViewer), findsOneWidget);
      expect(viewerReady, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
