# AI 学习成长系统（ai-study-growth）

> 自律学习 × AI 错题本 融合重构 —— 不是两个 App 拼在一起，而是用一个成长闭环把「学了什么」和「有没有真学」焊死。

## 产品定位

以「**我是不是在变强**」为主线的完整 AI 学习成长系统：

- **错题本域**回答：学了什么、哪里没学会 —— 拍题、AI 解析、知识点、错因、间隔复习、举一反三
- **自律域**回答：有没有真的投入 —— 专注会话、深渊模式、应用使用监控、任务执行
- **成长引擎**回答：我在变成什么样的人 —— 四能力趋势（学习/专注/坚持/恢复）、成长身份、成长记忆、NextStep

### 统一闭环

```
[学习输入] 拍题/录题
    ↓ AI 多模态解析
[知识资产] 题库 · 知识点 · 错因库
    ↓ 记忆曲线 + 举一反三
[学习行动] 今日复习清单 / 练习任务 ──→ 自动注册为当日 Mission
    ↓ 执行
[自律执行] 专注会话 · 深渊模式 · 应用使用监控（MOSS 数字伴读）
    ↓ 全量事件流
[成长引擎] 四能力趋势 → 成长身份 → 成长记忆
    ↓
[NextStep 建议] ──→ 回到学习行动（闭环）
```

### 五大融合点

1. **复习即任务**：到期复习/薄弱知识点自动生成当日 Mission
2. **专注有对象**：从错题发起「25 分钟吃透这 3 道题」的专注会话
3. **掌握度反哺能力**：复习通过 → 掌握度提升 → 写入学习能力趋势
4. **监控联动学习**：分心时 MOSS 给出具体替代行动而非干巴巴警告
5. **AI 统一大脑**：解析/追问/练习/伴读共用一套 Provider 配置

## 设计语言

**极简心流 + 玻璃拟物（Glassmorphism）**：大量留白、单核沉浸、成长可视化（能量环/光合树）。MOSS 是「数字伴读」，语气引导式、启发式。

## 技术架构

纯 Android，Flutter 单栈。

| 分类 | 技术 |
|------|------|
| 框架 | Flutter (Latest Stable) |
| 状态管理 | Riverpod |
| 路由 | GoRouter |
| 本地数据库 | Drift (SQLite)，事件溯源 + 实体表混合模型 |
| Android 桥接 | Platform Channels (MethodChannel + EventChannel) |
| Kotlin 层 | Coroutines + Flow + Android Architecture Components |
| AI | OpenAI 兼容协议，流式输出，密钥存 flutter_secure_storage |

### 桥接层原则：Kotlin 产事实，Dart 做决策

```
Kotlin: MonitorService(前台服务) / UsageStatsManager / LockScreenActivity
   ↓ EventChannel（事件先落原生盘，重启补推，一条不丢）
Dart:   DisciplineEngine(focusMath 去重) → MissionEvaluator → RewardEngine
```

### 数据层 Schema（单一事实源）

| 分类 | 表 |
|------|-----|
| 学习域实体 | question_records, knowledge_points, question_knowledge_links, review_cards, review_logs, generated_exercises, ai_messages |
| 自律域实体 | focus_sessions, missions |
| 事件流 | learning_events, focus_events |
| 成长快照 | growth_metrics（四能力每日快照） |
| AI 配置 | ai_providers（密钥不落库） |

## 路线图

| 阶段 | 内容 | 验收 | 状态 |
|------|------|------|------|
| **P0** 基座 | 脚手架、Lint/Hooks、Drift Schema、AI Provider 模块、CI | 空壳 APK 打包，Drift 初始化无报错 | ✅ |
| **P1** 设计系统 | Design Tokens、组件库（心流倒计时/能量环）、主题管理 | 组件库覆盖新 UI 规范 | ✅ |
| **P2** 错题本重构 | 相机/裁剪/多图拆分、解析管线（串行队列/单题重试）、FSRS 复习、举一反三 | 拍题→解析→入库→复习→练习全链路 | ✅ |
| **P3** 自律引擎 | Kotlin MonitorService/LockScreen、DisciplineEngine 状态机、MOSS 策略 | 分心→锁屏遮罩→回归，专注时长精准 | ✅ |
| **P4** 融合引擎 | 复习即任务、专注有对象、四能力实装、NextStep | 系统给出合理明日学习规划 | ✅ |
| **P5** 打磨发布 | 权限引导、Onboarding、整体审查、CI 打包 | 全量测试通过，Release APK | ✅ |

### 全阶段交付概览

**P3 自律域**：Kotlin 前台服务 15s 轮询前台应用（事件 JSONL 落盘、重启补推）；DisciplineEngine 三相状态机（focusing/distracted/locked），focusMath 区间去重算真实专注时长；MOSS 策略普通 1min 提醒/5min 锁屏、深渊 30s/2min；专注启动/进行/结算三页单核沉浸 UI。

**P4 成长引擎**：GrowthEngine 四能力纯函数（学习=复习完成度60%+摄入20%+掌握度20%；专注=时长对标-分心轻罚；坚持=连续天数；恢复=回归率）；MissionEngine 复习即任务（幂等生成+评分后自动评估）；NextStepEngine 四级规则（记忆债→专注→拍题→保持）；成长首页五层结构（身份/能量环/行动/记忆/快捷入口），四能力由双域真实数据驱动，身份只给定性描述。

**P5 打磨**：三屏 Onboarding（首启 + 权限引导）、通知权限申请、使用情况访问引导贯穿专注启动与引导页。

### P2 已交付清单

- **解析管线**（串行队列/状态落库/单题重试/部分成功保存/启动恢复），网关接口化可注入 Fake 测试
- **FSRS 间隔复习**：评分驱动调度，掌握度 0-5 映射（S≥21 稳定 / S≥60 掌握），复习事件入成长事件流
- **拍题 UI**：相机/相册 + 裁剪 + 任务队列页（缩略图、逐题状态、保存/放弃/重试）
- **错题本**：列表（搜索/科目过滤/掌握度徽章）、详情（题干/答案/步骤/错因/知识点/建议）
- **AI 追问**（MOSS 伴读，流式输出，历史持久化）、**举一反三**（生成/入库/完成标记）
- **AI 服务商配置页**：预设 Base URL、拉模型列表、测试连接、密钥加密存储

## 开发

```bash
# 环境：Flutter SDK（版本见 .fvmrc）
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # 生成 drift 代码
flutter test
flutter analyze --no-fatal-infos

# 启用 git hooks（clone 后执行一次）
bash tool/install_hooks.sh
```

CI：push/PR 自动跑 format + analyze + test 门禁，main 分支构建 Release APK 并发布。
