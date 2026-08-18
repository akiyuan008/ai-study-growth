import 'dart:convert';

/// 对话消息（OpenAI 兼容格式，支持多模态图片）
class AiMessage {
  const AiMessage({
    required this.role,
    required this.content,
    this.imageBase64,
    this.imageMimeType,
  });

  /// system / user / assistant
  final String role;
  final String content;

  /// 附带图片（base64），仅 user 消息有效
  final String? imageBase64;
  final String? imageMimeType;

  bool get hasImage => imageBase64 != null && imageBase64!.isNotEmpty;

  Map<String, dynamic> toJson() {
    if (!hasImage) return {'role': role, 'content': content};
    return {
      'role': role,
      'content': [
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:$imageMimeType;base64,$imageBase64',
            'detail': 'high',
          },
        },
        {'type': 'text', 'text': content},
      ],
    };
  }

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    if (content is String) {
      return AiMessage(role: json['role'] as String, content: content);
    }
    // 多模态数组：提取文本部分
    final buffer = StringBuffer();
    if (content is List) {
      for (final part in content) {
        if (part is Map && part['type'] == 'text') {
          buffer.write(part['text'] ?? '');
        }
      }
    }
    return AiMessage(role: json['role'] as String, content: buffer.toString());
  }
}

/// 流式输出的增量片段
class AiStreamChunk {
  const AiStreamChunk({required this.delta, this.finished = false});

  /// 本次增量文本
  final String delta;

  /// 是否为最后一个片段
  final bool finished;
}

/// 图片消息构造辅助
AiMessage userMessageWithImage({
  required String text,
  required List<int> imageBytes,
  String mimeType = 'image/jpeg',
}) =>
    AiMessage(
      role: 'user',
      content: text,
      imageBase64: base64Encode(imageBytes),
      imageMimeType: mimeType,
    );
