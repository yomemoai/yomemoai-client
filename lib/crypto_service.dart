import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';

final _secureRandom = Random.secure();

/// Hybrid encryption compatible with python-yomemo-mcp.
/// Format: base64(JSON({ data: base64(nonce+ciphertext+tag), key: base64(RSA_OAEP(aes_key)), signature: base64(sign) }))
class CryptoService {
  RSAPrivateKey? _privateKey;
  RSAPublicKey? _publicKey;
  enc.RSA? _rsaOaep;
  enc.RSASigner? _signer;

  bool get isInitialized => _privateKey != null;

  /// Initialize with PEM private key (same key pair as MCP).
  void init(String pemString) {
    final key = enc.RSAKeyParser().parse(_normalizePem(pemString));
    if (key is! RSAPrivateKey) {
      throw ArgumentError('PEM must be a private key');
    }
    _privateKey = key;
    _publicKey = RSAPublicKey(key.modulus!, key.publicExponent!);
    _rsaOaep = enc.RSA(
      publicKey: _publicKey,
      privateKey: _privateKey,
      encoding: enc.RSAEncoding.OAEP,
      digest: enc.RSADigest.SHA256,
    );
    _signer = enc.RSASigner(
      enc.RSASignDigest.SHA256,
      publicKey: _publicKey,
      privateKey: _privateKey,
    );
  }

  String _normalizePem(String pem) {
    final s = pem.trim();
    if (s.contains('-----BEGIN')) return s;
    return '-----BEGIN PRIVATE KEY-----\n$s\n-----END PRIVATE KEY-----';
  }

  String encrypt(String plainText) {
    if (_rsaOaep == null || _signer == null) {
      throw StateError('CryptoService not initialized');
    }
    final aesKey = _randomBytes(32);
    final nonce = _randomBytes(12);

    final combinedData = _aesGcmEncrypt(
      Uint8List.fromList(utf8.encode(plainText)),
      aesKey,
      nonce,
    );
    final combinedB64 = base64.encode(combinedData);

    final encryptedKey = _rsaOaep!.encrypt(aesKey).bytes;
    final keyB64 = base64.encode(encryptedKey);

    final signature = _signer!.sign(
      Uint8List.fromList(utf8.encode(combinedB64)),
    );
    final sigB64 = base64.encode(signature.bytes);

    final pkg = <String, String>{
      'data': combinedB64,
      'key': keyB64,
      'signature': sigB64,
    };
    return base64.encode(utf8.encode(json.encode(pkg)));
  }

  /// Decrypt hybrid package. If not recognized, return as-is or an error message.
  String decrypt(String encryptedPkgBase64) {
    if (encryptedPkgBase64.trim().isEmpty) return '';
    try {
      final pkgBytes = base64.decode(encryptedPkgBase64);
      final pkg = json.decode(utf8.decode(pkgBytes)) as Map<String, dynamic>;
      if (pkg.containsKey('key') &&
          pkg['key'] != null &&
          pkg['key'].toString().isNotEmpty) {
        return _unpackAndDecrypt(pkg);
      }
      if (pkg.containsKey('data')) {
        final data = base64.decode(pkg['data'].toString());
        final decrypted = _rsaOaep!.decrypt(
          enc.Encrypted(Uint8List.fromList(data)),
        );
        return utf8.decode(decrypted);
      }
    } catch (_) {}
    if (!encryptedPkgBase64.contains('"') &&
        !encryptedPkgBase64.contains('{')) {
      return encryptedPkgBase64;
    }
    return '⚠️ Decrypt Failed';
  }

  String _unpackAndDecrypt(Map<String, dynamic> pkg) {
    final encryptedKey = base64.decode(pkg['key']!.toString());
    final aesKey = _rsaOaep!.decrypt(
      enc.Encrypted(Uint8List.fromList(encryptedKey)),
    );

    final combinedData = base64.decode(pkg['data']!.toString());
    final nonce = Uint8List.fromList(combinedData.sublist(0, 12));
    final tag = Uint8List.fromList(
      combinedData.sublist(combinedData.length - 16),
    );
    final ciphertext = Uint8List.fromList(
      combinedData.sublist(12, combinedData.length - 16),
    );

    final plain = _aesGcmDecrypt(
      ciphertext,
      Uint8List.fromList(aesKey),
      nonce,
      tag,
    );
    return utf8.decode(plain);
  }

  Uint8List _randomBytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _secureRandom.nextInt(256);
    }
    return out;
  }

  Uint8List _aesGcmEncrypt(Uint8List plain, Uint8List key, Uint8List nonce) {
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      true,
      AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)),
    );
    final encryptedWithTag = cipher.process(plain);
    final tagStart = encryptedWithTag.length - 16;
    final ciphertext = encryptedWithTag.sublist(0, tagStart);
    final tag = encryptedWithTag.sublist(tagStart);
    return Uint8List.fromList([...nonce, ...ciphertext, ...tag]);
  }

  Uint8List _aesGcmDecrypt(
    Uint8List ciphertext,
    Uint8List key,
    Uint8List nonce,
    Uint8List tag,
  ) {
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      false,
      AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)),
    );
    final out = cipher.process(Uint8List.fromList([...ciphertext, ...tag]));
    return out;
  }
}
