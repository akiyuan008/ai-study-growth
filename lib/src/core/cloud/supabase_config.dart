/// Supabase 云端配置。
///
/// anon key 为公开可嵌入密钥，数据安全由 RLS 保证：
/// - 所有数据表按 auth.uid() = user_id 隔离
/// - 存储桶 question-images 按 {user_id}/ 目录隔离
abstract final class SupabaseConfig {
  static const String url = 'https://enkzlidriizwwsijzswl.supabase.co';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVua3psaWRyaWl6d3dzaWp6c3dsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MjU1MTEsImV4cCI6MjA5NjUwMTUxMX0.k1EAvCww2q-N7H1QAimWqcXQPvyEhwWd1CSO2dhCo8Q';

  /// 题目图片存储桶
  static const String imagesBucket = 'question-images';

  /// 参与同步的数据表（本地 drift 表名 → Supabase 表名，此处一致）
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
