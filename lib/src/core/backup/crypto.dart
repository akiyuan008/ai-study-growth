import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';

/// 备份包加密（Part 4.1）：PBKDF2-SHA256 派生密钥 + AES-256-CBC。
/// 文件格式：magic(8) + version(1) + salt(16) + iv(16) + 密文
abstract final class BackupCrypto {
  static const _magic = 'SGROWBAK';
  static const _version = 1;
  static const _iterations = 100000;
  static const _saltLen = 16;
  static const _ivLen = 16;

  /// 从密码派生 AES-256 密钥
  static Uint8List deriveKey(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _iterations, 32));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// 加密：返回带文件头的密文字节
  static Uint8List encrypt(Uint8List plaintext, String password) {
    final random = Random.secure();
    final salt = Uint8List.fromList(
        List<int>.generate(_saltLen, (_) => random.nextInt(256)));
    final iv = Uint8List.fromList(
        List<int>.generate(_ivLen, (_) => random.nextInt(256)));
    final key = deriveKey(password, salt);

    final encrypter =
        enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
    final encrypted =
        encrypter.encryptBytes(plaintext.toList(), iv: enc.IV(iv)).bytes;

    final out = BytesBuilder();
    out.add(utf8.encode(_magic));
    out.addByte(_version);
    out.add(salt);
    out.add(iv);
    out.add(Uint8List.fromList(encrypted));
    return out.toBytes();
  }

  /// 解密：校验文件头，密码错误抛 BackupCryptoException
  static Uint8List decrypt(Uint8List data, String password) {
    if (data.length < 8 + 1 + _saltLen + _ivLen) {
      throw const BackupCryptoException('备份文件格式无效');
    }
    final magic = utf8.decode(data.sublist(0, 8));
    if (magic != _magic) {
      throw const BackupCryptoException('不是有效的加密备份文件');
    }
    final salt = data.sublist(9, 9 + _saltLen);
    final iv = data.sublist(9 + _saltLen, 9 + _saltLen + _ivLen);
    final cipherBytes = data.sublist(9 + _saltLen + _ivLen);

    final key = deriveKey(password, salt);
    try {
      final encrypter =
          enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
      final decrypted = encrypter.decryptBytes(
        enc.Encrypted(Uint8List.fromList(cipherBytes)),
        iv: enc.IV(iv),
      );
      return Uint8List.fromList(decrypted);
    } catch (_) {
      throw const BackupCryptoException('密码错误或文件已损坏');
    }
  }

  /// 判断字节流是否为加密备份
  static bool isEncrypted(Uint8List data) {
    if (data.length < 8) return false;
    return utf8.decode(data.sublist(0, 8), allowMalformed: true) == _magic;
  }
}

class BackupCryptoException implements Exception {
  const BackupCryptoException(this.message);
  final String message;
  @override
  String toString() => message;
}
