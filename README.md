# 智析录（ai-study-growth）

> 智析录 —— 拍得快、理得清、提醒复习、能打印的 AI 错题本：专业级扫描录入 + AI 知识点分类 + 举一反三 + SM-2 复习规划 + Supabase 云同步。
>
> 项目起源于「自律学习 APP」与「AI 错题本 APP」的融合重构；v0.6.0 起产品聚焦——删除专注/自律域，把全部力气用在「学了什么 → 学会没有 → 我在变强」这一条主线上。

## 产品主线

```
[学习输入] 拍题连拍 / 相册导入
    ↓ 文档扫描（自动校准 + 手动四角）
[录入硬门] 科目必选 + AI 仅输出层级知识点（严禁 AI 写解析）
    ↓ 用户确认真实题干/答案/错因
[知识资产] 错题本 · 知识点树 · 错因 · 个人真题题库
    ↓ SM-2 间隔复习 + 举一反三（L1-L4 来源可溯）
[学习行动] 今日复习清单 · 推荐卡 · 多选导出 PDF
    ↓ 每日真实活动
[成长引擎] 三能力趋势（学习/坚持/恢复）→ 成长身份 → 成长记忆 → NextStep
```

## 三 Tab + 中央相机键（dock）

`错题本 | [中央相机键] | 复习 | 设置` —— 相机键嵌入 dock 托架切口，一键直达拍题。

| Tab | 内容 |
|-----|------|
| **错题本** | 科目 Tab（数量角标）+ 时间/掌握度筛选、列表/详情、真实编辑、AI 追问、举一反三、多选导出 |
| **复习** | SM-2 到期队列、理由标签（第 N 次/逾期 N 天）、图即题干（大图+点按缩放）、三档自评（仍错/模糊/已会）常驻、下次日期变化可见 |
| **相机键** | 应用内相机（单页/多页模式）、连拍缩略堆叠、多页队列（调整/删除/重排）、编辑屏（四角拖拽/旋转/自动校准/增强切换） |
| **设置** | AI 服务商、AI 调用日志、通知、云同步（Supabase）、云备份（WebDAV）、外观（深色模式三态）、数据与关于 |

## AI 角色（收敛后）

**录入时 AI 只认知识点，严禁代写解析**——题干、答案、错因必须由用户亲手确认，保证「学了什么」是真实的。

- **层级知识点识别**：subject → version → book → chapter → lesson → point，视觉不支持时守卫转手动
- **AI 追问**：详情页流式答疑，只围绕当前这道题
- **举一反三**：L1 个人真题库检索（未用优先）/ L2 引用强制出处 / L3 待核实 / L4 拟题，来源标签透明
- **AiCallLog**：所有 AI 调用全量落库（purpose/请求/响应/状态/耗时/错误分级），设置页可查可清

## 成长引擎（v10 三能力模型）

| 能力 | 事实输入 |
|------|----------|
| 学习 | 复习完成/到期比、新题、掌握度提升、举一反三完成 |
| 坚持 | 连续天数、昨天是否断档 |
| 恢复 | 遗忘后重做正确次数 / 总遗忘次数 |

- 能力是**趋势而非属性**：只产出 0-100 趋势分，UI 转定性描述，不定级不比较
- 每个分数有可解释的事实输入（今日事实卡逐条列出）
- 纯函数实现，全量单测覆盖

## 内置高中知识点树

`assets/taxonomy/high_school_taxonomy.json`（带版本号，独立资产可热更）：

- 6 学科；物理为人教版 2019 版章级真实目录（必修一/二、选必一/二/三）
- **宁浅勿造**：数学/英语/化学/生物/语文只到册级，章节留给用户自定义，不编造
- 保存页级联选择器：每级历史置顶 + 自定义兜底，知识点可多选，逐条带完整层级入库

## 文档扫描管线（OpenCV 解耦）

- **OpenCV 可选加载**：启动自测（System.loadLibrary + 1x1 Mat），状态可查
- **核心管线不依赖 OpenCV**：裁剪/透视拉正（Matrix.setPolyToPoly）/旋转全部 android.graphics
- OpenCV 仅负责自动检测 + 高级增强；未加载时手动四角/裁剪/旋转/基础增强全可用，UI 永不展示 JNI/stack 原文
- **增强双引擎**：OpenCV 在 → 背景压平+CLAHE；不在 → Bitmap 直方图拉伸+白平衡；都产出扫描白，原图保留可回退
- 裁剪几何纯函数化（crop_geometry.dart）：坐标钳制、退化检测、旋转映射，单测回归

## PDF 导出

- 嵌霞鹜文屏 Lite（OFL 开源 TTF）中文字体，豆腐块清零
- 打印设置：字号（标准/大号）、图片内容（增强/原图）、含举一反三开关
- 白纸预览页（恒定浅色）→ 保存/分享/系统打印

## 数据安全与云同步

- **本地优先**：Drift (SQLite) 全量本地存储，AI 密钥存 flutter_secure_storage，不配置云/AI 时全功能可用
- **Supabase 云同步**：匿名一键开启；错题/知识点/复习进度/举一反三/题库双向同步，题目图片走 Storage（RLS 用户目录隔离）；保存/评分后联网自动补同步 + 回前台补同步 + 手动立即同步
- **WebDAV 云备份**：坚果云 / InfiniCLOUD / 自定义，整包备份（DB+图片）+ AES 加密可选
- **深色模式三态**：跟随系统/浅色/深色，全仓颜色令牌化

## 技术栈

纯 Android，Flutter 单栈（3.47）。

| 分类 | 技术 |
|------|------|
| 状态管理 | Riverpod |
| 路由 | GoRouter |
| 本地数据库 | Drift (SQLite)，schemaVersion 4 |
| 云同步 | Supabase（Auth 匿名 + PostgREST + Storage，RLS 隔离） |
| 复习算法 | SM-2（EF 1.3-3.0，间隔封顶 365 天） |
| 相机/扫描 | camera 包 + Kotlin OpenCV 4.9.0（maven，可选加载）+ android.graphics 核心管线 |
| AI | OpenAI 兼容协议，流式输出，AiCallLog 全量审计 |
| 图表 | fl_chart |

### 代码结构

```
lib/src/
├── app/                 # GoRouter + MaterialApp
├── core/
│   ├── ai/              # AI 网关/客户端/提示词/调用日志（只认知识点，不写解析）
│   ├── backup/          # WebDAV 三通道 + AES
│   ├── bridge/          # Kotlin 扫描桥（cropByPoints 返回错误详情）
│   ├── capture/         # 裁剪几何纯函数
│   ├── export/          # PDF 导出（中文嵌入）
│   └── growth/          # 成长引擎（三能力纯函数）+ NextStep 规则引擎
├── data/                # Drift 数据库/仓储/设置
├── design_system/       # Growth Design System（tokens/玻璃拟物/图标/toast）
└── features/            # capture / home / learning / growth / onboarding
```

## 开发

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift 代码生成
flutter analyze && flutter test                             # CI 同款检查
flutter build apk --release --target-platform android-arm,android-arm64
```

CI：push 触发 `flutter analyze --no-fatal-infos` + `dart format` + 全量单测；tag 触发 Release 构建（剥离调试符号）。

## 版本里程碑

- **v0.10.0**：Supabase 云同步（匿名登录+双向同步+图片云端）、SM-2 评分走统一仓储、EF/间隔边界修复、CI 门禁恢复
- **v0.9.x-v15**：终版 IA（三 Tab+相机键）、SM-2 替换 FSRS、单页/多页拍摄、科目必选、图片即题干
- **v0.9.x**：深色模式三态、图即题干、内置知识点树、OpenCV 解耦、PDF 中文重做
- **v0.8.0**：v13 全量修复——删除清零（自律三表/解析队列/白名单）、裁剪根因、AiCallLog、dock 五槽、视觉守卫
- **v0.7.0**：全局治理、录入硬门、列表详情重做、复习推荐引擎
- **v0.6.0**：专注域删除、夸克式拍照页、离线核心、连接性根治
- **v0.5.x**：更名「智析录」+ 新图标；无服务器云备份（WebDAV+AES）
- **v0.4.0**：双域融合大版本（IA v2 / 录入重构 / AI 收敛 / 题库飞轮）
