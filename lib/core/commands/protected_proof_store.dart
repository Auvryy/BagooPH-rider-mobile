import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_failure.dart';
import '../network/wire.dart';
import 'parcel_proof.dart';

/// An original proof file is encrypted in application-support storage. Only its
/// small reference and the account/API-specific key enter secure storage.
/// Unresolved files survive logout; logout never makes another account their owner.
class ProtectedParcelProofStore implements ParcelProofStore {
  ProtectedParcelProofStore({
    required Uri origin,
    required String accountId,
    FlutterSecureStorage? storage,
    Future<Directory> Function()? directory,
  }) : _scope = sha256.convert(utf8.encode('$origin/$accountId')).toString(),
       _storage = storage ?? const FlutterSecureStorage(),
       _supportDirectory = directory ?? getApplicationSupportDirectory {
    Wire.id(accountId);
  }

  final String _scope;
  final FlutterSecureStorage _storage;
  final Future<Directory> Function() _supportDirectory;
  final _cipher = AesGcm.with256bits();
  String get _keyName => 'bagoo_rider_parcel_proof_key_$_scope';

  Future<Directory> _directory() async => Directory(
    '${(await _supportDirectory()).path}/parcel-command-proofs/$_scope',
  ).create(recursive: true);

  Future<File> _file(ParcelProofReference reference) async =>
      File('${(await _directory()).path}/${reference.key}.bin');

  List<int> _binding(ParcelProofReference reference) => utf8.encode(
    'parcel-proof-v1/$_scope/${reference.key}/${reference.digest}/${reference.extension}',
  );

  Future<SecretKey> _secret({required bool create}) async {
    final stored = await _storage.read(key: _keyName);
    if (stored != null) {
      final bytes = base64Decode(stored);
      if (bytes.length != 32) Wire.invalid();
      return SecretKey(bytes);
    }
    if (!create) {
      throw const AccountFailure(
        'The saved original proof is unavailable. Check the saved request before continuing.',
        unconfirmed: true,
      );
    }
    final key = await _cipher.newSecretKey();
    await _storage.write(
      key: _keyName,
      value: base64Encode(await key.extractBytes()),
    );
    return key;
  }

  @override
  Future<ParcelProofReference> save(String key, ParcelProof proof) async {
    final reference = ParcelProofReference(
      key: key,
      digest: proof.digest,
      extension: proof.extension,
    );
    final file = await _file(reference);
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      final retained = await read(reference);
      if (retained.digest != proof.digest) Wire.invalid();
      return reference;
    }
    final box = await _cipher.encrypt(
      proof.bytes,
      secretKey: await _secret(create: true),
      aad: _binding(reference),
    );
    final temporary = File('${file.path}.${base64UrlEncode(box.nonce)}.tmp');
    try {
      await temporary.writeAsBytes(box.concatenation(), flush: true);
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
    return reference;
  }

  @override
  Future<ParcelProof> read(ParcelProofReference reference) async {
    try {
      final file = await _file(reference);
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
              FileSystemEntityType.file ||
          await file.length() > parcelProofLimit + 28) {
        throw const FormatException('Invalid protected proof');
      }
      final bytes = await file.readAsBytes();
      final box = SecretBox.fromConcatenation(
        bytes,
        nonceLength: 12,
        macLength: 16,
      );
      final original = await _cipher.decrypt(
        box,
        secretKey: await _secret(create: false),
        aad: _binding(reference),
      );
      final proof = ParcelProof(
        // Avoid sharing the mutable decrypted buffer with the caller.
        Uint8List.fromList(original),
        reference.extension,
      );
      if (proof.digest != reference.digest) Wire.invalid();
      return proof;
    } catch (_) {
      throw const AccountFailure(
        'The saved original proof could not be verified. Check the saved request; do not replace its image.',
        unconfirmed: true,
      );
    }
  }

  @override
  Future<void> delete(ParcelProofReference reference) async {
    final file = await _file(reference);
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return;
    if (type != FileSystemEntityType.file) Wire.invalid();
    await file.delete();
  }
}
