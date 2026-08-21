/// SM-2 间隔复习引擎（v15 终版：替换 FSRS）
///
/// SM-2 算法核心：
/// - 新卡首次复习间隔 = 1 天
/// - 评分后按质量因子调整间隔
/// - 质量分 0-5，实际使用三档：仍错(1)/模糊(3)/已会(5)
/// - EF (easiness factor) 初始 2.5，范围 [1.3, 3.0]
/// - 间隔公式：interval = interval * ef
class Sm2Scheduler {
  static const double _initialEf = 2.5;
  static const double _minEf = 1.3;
  static const double _maxEf = 3.0;
  static const int _initialIntervalDays = 1;

  /// 间隔封顶 365 天：防指数增长溢出 DateTime 范围，也符合错题本复习场景
  static const int _maxIntervalDays = 365;

  /// 从持久化字段还原一张 SM-2 卡片
  Sm2Card cardFromStorage({
    required int cardId,
    required int reps,
    required double easinessFactor,
    required int intervalDays,
    required DateTime due,
    DateTime? lastReview,
  }) {
    return Sm2Card(
      cardId: cardId,
      reps: reps,
      easinessFactor: easinessFactor,
      intervalDays: intervalDays,
      due: due,
      lastReview: lastReview,
    );
  }

  /// 创建新卡（从未复习）
  Sm2Card newCard({required int cardId}) {
    return Sm2Card(
      cardId: cardId,
      reps: 0,
      easinessFactor: _initialEf,
      intervalDays: 0,
      due: DateTime.now(),
      lastReview: null,
    );
  }

  /// 评分并得到新卡片状态
  /// quality: 仍错=1, 模糊=3, 已会=5
  ({Sm2Card card, Sm2ReviewLog reviewLog}) rate(
    Sm2Card card,
    int quality, {
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final previousEf = card.easinessFactor;
    final previousInterval = card.intervalDays;

    // SM-2 EF 更新公式
    var newEf = previousEf + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEf < _minEf) newEf = _minEf;
    if (newEf > _maxEf) newEf = _maxEf;

    // 计算新间隔
    int newInterval;
    int newReps;
    if (quality < 3) {
      // 仍错：重置为初始间隔
      newInterval = _initialIntervalDays;
      newReps = 0;
    } else if (quality == 3) {
      // 模糊：保持或略微增加间隔
      newInterval = previousInterval <= 0 ? _initialIntervalDays : (previousInterval * newEf).round();
      newReps = card.reps + 1;
    } else {
      // 已会：正常推进
      newInterval = previousInterval <= 0 ? _initialIntervalDays : (previousInterval * newEf).round();
      if (newInterval < 1) newInterval = 1;
      newReps = card.reps + 1;
    }
    // 间隔封顶：防止长期连续答对后指数膨胀
    if (newInterval > _maxIntervalDays) newInterval = _maxIntervalDays;

    final newDue = at.add(Duration(days: newInterval));

    final newCard = Sm2Card(
      cardId: card.cardId,
      reps: newReps,
      easinessFactor: newEf,
      intervalDays: newInterval,
      due: newDue,
      lastReview: at,
    );

    final log = Sm2ReviewLog(
      reviewedAt: at,
      quality: quality,
      previousEf: previousEf,
      previousInterval: previousInterval,
      newEf: newEf,
      newInterval: newInterval,
    );

    return (card: newCard, reviewLog: log);
  }

  /// 预览三档评分的下次复习间隔（复习页按钮展示用）。
  /// 与真实 rate() 逻辑完全一致，展示即结果。
  Map<int, Duration> previewIntervals(Sm2Card card, {DateTime? now}) {
    final at = now ?? DateTime.now();
    return {
      for (final q in [1, 3, 5])
        q: rate(card, q, now: at).card.due.difference(at),
    };
  }

  /// 是否已到期
  bool isDue(Sm2Card card, {DateTime? now}) {
    return (card.due).isBefore(now ?? DateTime.now());
  }

  /// 逾期天数
  int overdueDays(Sm2Card card, {DateTime? now}) {
    final n = now ?? DateTime.now();
    if (card.due.isAfter(n)) return 0;
    return n.difference(card.due).inDays;
  }
}

/// SM-2 卡片数据模型
class Sm2Card {
  const Sm2Card({
    required this.cardId,
    required this.reps,
    required this.easinessFactor,
    required this.intervalDays,
    required this.due,
    this.lastReview,
  });

  final int cardId;
  final int reps; // 已复习次数
  final double easinessFactor; // EF 难度因子 [1.3, 3.0]
  final int intervalDays; // 当前间隔（天）
  final DateTime due; // 下次到期时间
  final DateTime? lastReview; // 上次复习时间

  /// 状态文字描述
  String get statusText {
    if (reps == 0) return '新题';
    if (reps == 1) return '第 1 次复习';
    return '第 $reps 次复习';
  }
}

/// SM-2 复习日志
class Sm2ReviewLog {
  const Sm2ReviewLog({
    required this.reviewedAt,
    required this.quality,
    required this.previousEf,
    required this.previousInterval,
    required this.newEf,
    required this.newInterval,
  });

  final DateTime reviewedAt;
  final int quality; // 1=仍错, 3=模糊, 5=已会
  final double previousEf;
  final int previousInterval;
  final double newEf;
  final int newInterval;

  String get qualityLabel => switch (quality) {
    1 => '仍错',
    3 => '模糊',
    5 => '已会',
    _ => '未知',
  };
}
