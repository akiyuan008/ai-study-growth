# 自律域对账清单（旧 self-discipline-ai-monitor → 新系统）

> 原则：Kotlin 产事实、Dart 做决策。旧仓库 React/TS 逻辑全部以 Dart 重写为准。

| # | 旧仓库能力 | 关键模块 | 新系统状态 | 说明 |
|---|-----------|---------|-----------|------|
| 1 | 专注会话与状态机 | disciplineEngine.ts | ✅ 已移植 | DisciplineEngine 三相状态机（focusing/distracted/locked） |
| 2 | 真实专注时长去重 | focusMath.ts | ✅ 已移植 | focus_math.dart 区间合并，切出一秒不算 |
| 3 | 使用监控（前台服务） | Kotlin 插件 | ✅ 已移植 | UsageMonitorService 15s 轮询，事件 JSONL 落盘补推 |
| 4 | LEVEL 1-3 干预 | disciplineEngine | ✅ 映射完成 | LEVEL1=应用内横幅提醒（1min）/ LEVEL2=锁屏遮罩（5min）/ LEVEL3=深渊模式锁屏（2min） |
| 5 | 锁屏遮罩 | 原生 Activity | ✅ 已移植 | LockScreenActivity 全屏干预 + 屏蔽返回键 |
| 6 | 深渊模式 | Dungeon.tsx | ✅ 已移植 | 30s 提醒 / 2min 锁屏，专注页与设置页双入口 |
| 7 | Mission 三来源 | missionStore / scheduleToMissions | ⚠️ 部分 | REVIEW（复习即任务）✅、MANUAL（手动建任务）✅ v0.4 补、SCHEDULE（课表）⏳ 延后至 v0.5（需课表数据模型+周循环生成）、MOSS 来源枚举已预留 |
| 8 | MOSS 伴读对话 | aiSupervisor / Chat.tsx | ✅ 已收敛 | 题目追问（流式）+ 专注页 MOSS 伴读入口（v0.4 补）；监督话术改为引导式 |
| 9 | App 分类 | appCategories.ts | ✅ 简化替代 | 白名单管理（设置页），白名单应用不算分心 |
| 10 | XP/奖励引擎 | rewardEngine / rewardCore | ✅ 并入成长身份 | 定性化：不再发数值 XP，连续天数与能力趋势承担激励职能；里程碑写成长记忆 |
| 11 | 成就系统 | Achievements.tsx | ✅ 并入成长身份 | 连续天数里程碑（3/7/30 天）自动写入成长记忆时间线 |
| 12 | 恢复奖励 | recoveryReward.ts | ✅ 移植为恢复能力 | 分心回归率 + 断档后重新起步 → recovery 分数 |
| 13 | 每日复盘 | dailyReview.ts | ⏳ 延后 | 日终复盘页建议 v0.5 与成长报告一起做 |
| 14 | 偏差分析 | deviationAnalyzer.ts | ⏳ 延后 | 依赖课表证据链，随课表能力落地 |
| 15 | 课表管理 | courseEvidence / ClassHistory | ⏳ 延后 v0.5 | 课表数据模型 + 周循环 Mission 生成 + 课堂证据 |

## 本轮（v0.4）补缺内容
- 手动任务创建（专注页底部抽屉，source=MANUAL）
- MOSS 伴读对话入口（专注页，流式通用答疑）
- 连续天数里程碑成就写入成长记忆

## 延后项原因
- **课表/偏差分析/每日复盘**：依赖完整的课表数据模型（科目-节次-周循环）与证据链设计，
  与本轮「错题录入 + AI 收敛」主线无耦合，为避免半成品先行，排入 v0.5。
