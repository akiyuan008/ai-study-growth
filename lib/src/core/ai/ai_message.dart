/// 对话消息（OpenAI 兼容格式）
class AiMessage {
  const AiMessage({required this.role, required this.content});

  /// system / user / assistant
  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
        role: json['role'] as String,
        content: json['content'] as String? ?? '',
      );
}

/// 流式输出的增量片段
class AiStreamChunk {
  const AiStreamChunk({required this.delta, this.finished = false});

  /// 本次增量文本
  final String delta;

  /// 是否为最后一个片段
  final bool finished;
}
