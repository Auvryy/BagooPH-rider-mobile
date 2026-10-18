import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';

import '../network/api_failure.dart';
import '../network/wire.dart';

const parcelProofLimit = 5242880;
const parcelProofMimes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

bool parcelProofSignature(Uint8List bytes, String mime) {
  bool starts(List<int> prefix) =>
      bytes.length >= prefix.length &&
      List.generate(
        prefix.length,
        (i) => bytes[i] == prefix[i],
      ).every((v) => v);
  return switch (mime) {
    'image/jpeg' => starts([255, 216, 255]),
    'image/png' => starts([137, 80, 78, 71, 13, 10, 26, 10]),
    'image/webp' =>
      starts([82, 73, 70, 70]) &&
          bytes.length >= 12 &&
          ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP',
    _ => false,
  };
}

/// Original immutable selected/captured bytes. No re-encoding on upload/retry.
/// Signature/size checks are local feedback; the server verifies actual images.
class ParcelProof {
  ParcelProof(Uint8List value, this.extension)
    : bytes = Uint8List.fromList(value).asUnmodifiableView() {
    if (bytes.isEmpty ||
        bytes.length > parcelProofLimit ||
        !parcelProofMimes.containsKey(extension) ||
        !parcelProofSignature(bytes, mime)) {
      throw const AccountFailure(
        'Choose an original JPG, PNG or WebP image up to 5 MB.',
        fields: {
          'proof_image_file': 'Use a non-empty supported image up to 5 MB.',
        },
      );
    }
  }

  final Uint8List bytes;
  final String extension;
  String get mime => parcelProofMimes[extension]!;
  String get filename => 'parcel-proof.$extension';
  late final String digest = sha256.convert(bytes).toString();

  static Future<ParcelProof> fromFile(XFile file) async {
    final length = await file.length();
    if (length < 1 || length > parcelProofLimit) {
      throw const AccountFailure(
        'Choose an original image up to 5 MB.',
        fields: {'proof_image_file': 'Maximum file size is 5 MB.'},
      );
    }
    final bytes = await file.readAsBytes();
    if (bytes.length != length) {
      throw const AccountFailure(
        'The selected image changed. Choose it again.',
      );
    }
    return ParcelProof(bytes, file.name.split('.').last.toLowerCase());
  }
}

class ParcelProofReference {
  ParcelProofReference({
    required this.key,
    required this.digest,
    required this.extension,
  }) {
    Wire.uuid(key);
    Wire.version(digest);
    if (!parcelProofMimes.containsKey(extension)) Wire.invalid();
  }

  factory ParcelProofReference.fromJson(Map<String, dynamic> value) =>
      ParcelProofReference(
        key: Wire.uuid(value['key']),
        digest: Wire.version(value['sha256']),
        extension: Wire.string(value['extension']),
      );

  final String key, digest, extension;
  Map<String, dynamic> toJson() => {
    'key': key,
    'sha256': digest,
    'extension': extension,
  };
}

abstract interface class ParcelProofStore {
  Future<ParcelProofReference> save(String key, ParcelProof proof);
  Future<ParcelProof> read(ParcelProofReference reference);
  Future<void> delete(ParcelProofReference reference);
}
