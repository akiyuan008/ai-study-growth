/// Supabase 云端配置。
///
/// 单用户模式：本 App 仅机主一人使用，内置唯一共享账号，
/// 安装即自动登录、自动同步，无需任何注册/登录操作。
///
/// 数据安全边界：
/// - anon key 为公开可嵌入密钥，访问受 RLS 限制
/// - 所有数据表按 auth.uid() = user_id 隔离（该账号仅能读写自己的数据）
/// - 存储桶 question-images 按 {user_id}/ 目录隔离
abstract final class SupabaseConfig {
  static const String url = 'https://enkzlidriizwwsijzswl.supabase.co';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVua3psaWRyaWl6d3dzaWp6c3dsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MjU1MTEsImV4cCI6MjA5NjUwMTUxMX0.k1EAvCww2q-N7H1QAimWqcXQPvyEhwWd1CSO2dhCo8Q';

  /// 唯一共享账号（单用户专用；凭据仅用于此账号自身数据的 RLS 访问）
  static const String sharedEmail = 'zhiilu_sync@outlook.com';
  static const String sharedPassword = 'ZhiLu#2026Sync!Safe';

  /// 题目图片存储桶
  static const String imagesBucket = 'question-images';

  /// 参与同步的数据表
  static const List<String> syncTables = [
    'question_records',
    'knowledge_points',
    'question_knowledge_links',
    'review_cards',
    'review_logs',
    'generated_exercises',
    'question_bank',
  ];
}
