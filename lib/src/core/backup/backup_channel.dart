/// 备份通道（Part 4.2/4.3）：三通道 WebDAV + local_export，
/// 枚举预留 aliyun_drive / baidu_pcs 扩展点（本期不实现）。
enum BackupChannelType {
  jianguoyun,
  infinicloud,
  customWebdav,
  localExport,
  // 扩展点预留（本期不实现）
  aliyunDrive,
  baiduPcs,
}

/// 备份通道配置。密码/应用密码只存 flutter_secure_storage，
/// 此处仅存 keyRef（严禁明文持久化）。
class BackupChannelConfig {
  const BackupChannelConfig({
    required this.type,
    this.serverUrl = '',
    this.username = '',
    this.keyRef = '',
    this.encryptEnabled = false,
  });

  final BackupChannelType type;

  /// WebDAV 服务器地址（坚果云固定；InfiniCLOUD 按用户名拼接，可手改）
  final String serverUrl;
  final String username;

  /// secure storage 中密码的键名
  final String keyRef;

  /// 是否启用 AES 加密备份包
  final bool encryptEnabled;

  /// 坚果云服务器地址（写死）
  static const String jianguoyunUrl = 'https://dav.jianguoyun.com/dav/';

  /// InfiniCLOUD 地址按用户名自动拼接
  static String infinicloudUrl(String username) =>
      'https://$username.teracloud.jp/dav/';

  /// 实际生效的服务器地址
  String get effectiveUrl {
    switch (type) {
      case BackupChannelType.jianguoyun:
        return jianguoyunUrl;
      case BackupChannelType.infinicloud:
        return serverUrl.isNotEmpty ? serverUrl : infinicloudUrl(username);
      case BackupChannelType.customWebdav:
        return serverUrl;
      default:
        return '';
    }
  }

  /// 规范化：确保以 / 结尾
  String get normalizedUrl {
    final url = effectiveUrl.trim();
    if (url.isEmpty) return '';
    return url.endsWith('/') ? url : '$url/';
  }

  BackupChannelConfig copyWith({
    BackupChannelType? type,
    String? serverUrl,
    String? username,
    String? keyRef,
    bool? encryptEnabled,
  }) =>
      BackupChannelConfig(
        type: type ?? this.type,
        serverUrl: serverUrl ?? this.serverUrl,
        username: username ?? this.username,
        keyRef: keyRef ?? this.keyRef,
        encryptEnabled: encryptEnabled ?? this.encryptEnabled,
      );
}
