import 'dart:typed_data';

import 'package:bagoo_rider_mobile/features/auth/data/registration_document.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List pngHeader(int width, int height) => Uint8List.fromList([
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  ..._be32(width),
  ..._be32(height),
  8,
  2,
  0,
  0,
  0,
]);

List<int> _be32(int value) => [
  (value >> 24) & 0xff,
  (value >> 16) & 0xff,
  (value >> 8) & 0xff,
  value & 0xff,
];

List<int> _le24(int value) => [
  value & 0xff,
  (value >> 8) & 0xff,
  (value >> 16) & 0xff,
];

Uint8List jpegHeader(int width, int height) => Uint8List.fromList([
  0xff,
  0xd8,
  0xff,
  0xc0,
  0,
  17,
  8,
  (height >> 8) & 0xff,
  height & 0xff,
  (width >> 8) & 0xff,
  width & 0xff,
  3,
  1,
  17,
  0,
  2,
  17,
  0,
  3,
  17,
  0,
  0xff,
  0xd9,
]);

Uint8List webpVp8xHeader(int width, int height) => Uint8List.fromList([
  0x52,
  0x49,
  0x46,
  0x46,
  22,
  0,
  0,
  0,
  0x57,
  0x45,
  0x42,
  0x50,
  0x56,
  0x50,
  0x38,
  0x58,
  10,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  ..._le24(width - 1),
  ..._le24(height - 1),
]);

Uint8List webpVp8lHeader(int width, int height) {
  final packed = ((height - 1) << 14) | (width - 1);
  return Uint8List.fromList([
    0x52,
    0x49,
    0x46,
    0x46,
    17,
    0,
    0,
    0,
    0x57,
    0x45,
    0x42,
    0x50,
    0x56,
    0x50,
    0x38,
    0x4c,
    5,
    0,
    0,
    0,
    0x2f,
    packed & 0xff,
    (packed >> 8) & 0xff,
    (packed >> 16) & 0xff,
    (packed >> 24) & 0xff,
  ]);
}

Uint8List webpVp8Header(int width, int height) => Uint8List.fromList([
  0x52,
  0x49,
  0x46,
  0x46,
  22,
  0,
  0,
  0,
  0x57,
  0x45,
  0x42,
  0x50,
  0x56,
  0x50,
  0x38,
  0x20,
  10,
  0,
  0,
  0,
  0,
  0,
  0,
  0x9d,
  0x01,
  0x2a,
  width & 0xff,
  (width >> 8) & 0x3f,
  height & 0xff,
  (height >> 8) & 0x3f,
]);

void main() {
  test('accepts supported signatures and exact dimension boundaries', () {
    final pdf = Uint8List.fromList('%PDF-1.7\n'.codeUnits);
    expect(registrationDocumentError('pdf', pdf), isNull);
    expect(registrationDocumentError('png', pngHeader(1, 1)), isNull);
    expect(registrationDocumentError('jpg', jpegHeader(2000, 10000)), isNull);
    expect(
      registrationDocumentError('webp', webpVp8xHeader(2000, 10000)),
      isNull,
    );
    expect(
      registrationDocumentError('webp', webpVp8lHeader(2000, 10000)),
      isNull,
    );
    expect(
      registrationDocumentError('webp', webpVp8Header(2000, 10000)),
      isNull,
    );
  });

  test('rejects mislabeled, corrupt, and oversized image headers', () {
    expect(
      registrationDocumentError(
        'pdf',
        Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
      ),
      contains('match its file type'),
    );
    expect(registrationDocumentError('exe', Uint8List(10)), isNotNull);
    expect(registrationDocumentError('png', pngHeader(0, 100)), isNotNull);
    expect(registrationDocumentError('png', pngHeader(10001, 1)), isNotNull);
    expect(registrationDocumentError('png', pngHeader(10000, 2001)), isNotNull);
    expect(registrationDocumentError('jpg', jpegHeader(10001, 1)), isNotNull);
    expect(
      registrationDocumentError('webp', webpVp8xHeader(10000, 2001)),
      isNotNull,
    );
  });

  test('reads only bounded files and checks bytes remain unchanged', () async {
    final pdf = XFile.fromData(
      Uint8List.fromList('%PDF-1.7\n'.codeUnits),
      path: 'identity.pdf',
    );
    expect((await readRegistrationDocument(pdf)).length, greaterThan(5));
    await expectLater(
      readRegistrationDocument(XFile.fromData(Uint8List(0), path: 'empty.pdf')),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      readRegistrationDocument(
        XFile.fromData(Uint8List(6 * 1024 * 1024), path: 'large.pdf'),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
