import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../../../core/network/api_failure.dart';

const registrationDocumentMaxBytes = 5 * 1024 * 1024;

/// Reads a bounded document once, validates its extension and signature, and
/// checks image dimensions from headers without decoding the raster into RAM.
Future<Uint8List> readRegistrationDocument(XFile file) async {
  final length = await file.length();
  if (length < 1 || length > registrationDocumentMaxBytes) {
    throw const AccountFailure('Choose a non-empty document up to 5 MB.');
  }
  final bytes = await file.readAsBytes();
  if (bytes.length != length) {
    throw const AccountFailure(
      'The selected document changed. Choose it again.',
    );
  }
  final extension = file.name.contains('.')
      ? file.name.split('.').last.toLowerCase()
      : '';
  final error = registrationDocumentError(extension, bytes);
  if (error != null) throw AccountFailure(error);
  return bytes;
}

/// Returns a user-facing reason when bytes do not meet the backend's current
/// RegistrationDocument contract. Callers still submit the original bytes.
String? registrationDocumentError(String extension, Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > registrationDocumentMaxBytes) {
    return 'Choose a non-empty document up to 5 MB.';
  }
  switch (extension.toLowerCase()) {
    case 'pdf':
      return _startsWith(bytes, const [0x25, 0x50, 0x44, 0x46, 0x2d])
          ? null
          : 'Choose a PDF whose contents match its file type.';
    case 'jpg':
    case 'jpeg':
      final size = _jpegDimensions(bytes);
      return size != null && _withinDimensionLimit(size.$1, size.$2)
          ? null
          : _imageError;
    case 'png':
      final size = _pngDimensions(bytes);
      return size != null && _withinDimensionLimit(size.$1, size.$2)
          ? null
          : _imageError;
    case 'webp':
      final size = _webpDimensions(bytes);
      return size != null && _withinDimensionLimit(size.$1, size.$2)
          ? null
          : _imageError;
    default:
      return 'Choose a JPG, PNG, WEBP or PDF document.';
  }
}

const _imageError =
    'Choose a readable image up to 10,000 pixels per side and 20 million pixels in total, or use a PDF.';

bool _withinDimensionLimit(int width, int height) =>
    width > 0 &&
    height > 0 &&
    width <= 10000 &&
    height <= 10000 &&
    width * height <= 20000000;

bool _startsWith(Uint8List bytes, List<int> prefix) =>
    bytes.length >= prefix.length &&
    List.generate(
      prefix.length,
      (index) => bytes[index] == prefix[index],
    ).every((matches) => matches);

int _uint16be(Uint8List bytes, int offset) =>
    (bytes[offset] << 8) | bytes[offset + 1];

int _uint32be(Uint8List bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

int _uint24le(Uint8List bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);

int _uint32le(Uint8List bytes, int offset) =>
    bytes[offset] |
    (bytes[offset + 1] << 8) |
    (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24);

(int, int)? _pngDimensions(Uint8List bytes) {
  if (!_startsWith(bytes, const [137, 80, 78, 71, 13, 10, 26, 10]) ||
      bytes.length < 24 ||
      _uint32be(bytes, 8) != 13 ||
      String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR') {
    return null;
  }
  return (_uint32be(bytes, 16), _uint32be(bytes, 20));
}

(int, int)? _jpegDimensions(Uint8List bytes) {
  if (!_startsWith(bytes, const [0xff, 0xd8])) return null;
  const startOfFrame = {
    0xc0,
    0xc1,
    0xc2,
    0xc3,
    0xc5,
    0xc6,
    0xc7,
    0xc9,
    0xca,
    0xcb,
    0xcd,
    0xce,
    0xcf,
  };
  var offset = 2;
  while (offset + 3 < bytes.length) {
    if (bytes[offset] != 0xff) return null;
    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset++;
    }
    if (offset >= bytes.length) return null;
    final marker = bytes[offset++];
    if (marker == 0xda || marker == 0xd9) return null;
    if (marker == 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    if (offset + 1 >= bytes.length) return null;
    final segmentLength = _uint16be(bytes, offset);
    if (segmentLength < 2 || offset + segmentLength > bytes.length) return null;
    if (startOfFrame.contains(marker)) {
      if (segmentLength < 7) return null;
      final height = _uint16be(bytes, offset + 3);
      final width = _uint16be(bytes, offset + 5);
      return (width, height);
    }
    offset += segmentLength;
  }
  return null;
}

(int, int)? _webpDimensions(Uint8List bytes) {
  if (!_startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) ||
      bytes.length < 20 ||
      String.fromCharCodes(bytes.sublist(8, 12)) != 'WEBP') {
    return null;
  }
  final riffEnd = _uint32le(bytes, 4) + 8;
  final chunkSize = _uint32le(bytes, 16);
  if (riffEnd > bytes.length || 20 + chunkSize > riffEnd) return null;
  final chunk = String.fromCharCodes(bytes.sublist(12, 16));
  if (chunk == 'VP8X' && chunkSize >= 10) {
    return (_uint24le(bytes, 24) + 1, _uint24le(bytes, 27) + 1);
  }
  if (chunk == 'VP8L' && chunkSize >= 5 && bytes[20] == 0x2f) {
    int readBits(int start, int count) {
      var result = 0;
      for (var bit = 0; bit < count; bit++) {
        result |=
            ((bytes[21 + ((start + bit) >> 3)] >> ((start + bit) & 7)) & 1) <<
            bit;
      }
      return result;
    }

    return (readBits(0, 14) + 1, readBits(14, 14) + 1);
  }
  if (chunk == 'VP8 ' &&
      chunkSize >= 10 &&
      bytes[23] == 0x9d &&
      bytes[24] == 0x01 &&
      bytes[25] == 0x2a) {
    final width = _uint16le(bytes, 26) & 0x3fff;
    final height = _uint16le(bytes, 28) & 0x3fff;
    return (width, height);
  }
  return null;
}

int _uint16le(Uint8List bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8);
