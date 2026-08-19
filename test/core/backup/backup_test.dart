import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_study_growth/src/core/backup/backup_channel.dart';
import 'package:ai_study_growth/src/core/backup/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupCrypto（Part 4.1 AES 加密）', () {
    test('加密→解密往返一致', () {
      final plain = Uint8List.fromList(utf8.encode('错题本数据 12345'));
      final encrypted = BackupCrypto.encrypt(plain, 'mypassword');
      expect(BackupCrypto.isEncrypted(encrypted), isTrue);
      final decrypted = BackupCrypto.decrypt(encrypted, 'mypassword');
      expect(utf8.decode(decrypted), '错题本数据 12345');
    });

    test('错误密码抛出明确异常', () {
      final plain = Uint8List.fromList(utf8.encode('data'));
      final encrypted = BackupCrypto.encrypt(plain, 'right');
      expect(
        () => BackupCrypto.decrypt(encrypted, 'wrong'),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('同明文同密码两次加密结果不同（随机 salt/iv）', () {
      final plain = Uint8List.fromList(utf8.encode('same'));
      final a = BackupCrypto.encrypt(plain, 'pw');
      final b = BackupCrypto.encrypt(plain, 'pw');
      expect(a, isNot(equals(b)));
    });

    test('非加密文件识别为未加密', () {
      final zipLike = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 0, 0]);
      expect(BackupCrypto.isEncrypted(zipLike), isFalse);
    });
  });

  group('BackupChannelConfig（Part 4.2 通道规则）', () {
    test('坚果云地址写死，用户只填账号+应用密码', () {
      const config = BackupChannelConfig(
        type: BackupChannelType.jianguoyun,
        username: 'user@example.com',
      );
      expect(config.effectiveUrl, 'https://dav.jianguoyun.com/dav/');
    });

    test('InfiniCLOUD 地址按用户名自动拼接', () {
      const config = BackupChannelConfig(
        type: BackupChannelType.infinicloud,
        username: 'alice',
      );
      expect(config.effectiveUrl, 'https://alice.teracloud.jp/dav/');
    });

    test('InfiniCLOUD 允许手动覆盖地址', () {
      const config = BackupChannelConfig(
        type: BackupChannelType.infinicloud,
        username: 'alice',
        serverUrl: 'https://custom.example.com/dav',
      );
      expect(config.normalizedUrl, 'https://custom.example.com/dav/');
    });

    test('自定义 WebDAV 全手填 + 尾斜杠规范化', () {
      const config = BackupChannelConfig(
        type: BackupChannelType.customWebdav,
        serverUrl: 'https://nas.local:5005/dav',
      );
      expect(config.normalizedUrl, 'https://nas.local:5005/dav/');
    });

    test('扩展点枚举已预留（本期不实现）', () {
      expect(BackupChannelType.values, contains(BackupChannelType.aliyunDrive));
      expect(BackupChannelType.values, contains(BackupChannelType.baiduPcs));
    });
  });
}
