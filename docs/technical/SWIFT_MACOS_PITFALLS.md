# SpeakDock Swift/macOS 踩坑记录

## 1. 用途

这份文档是 SpeakDock 当前唯一的 Swift/macOS 踩坑记录。

- 只记录已经真实踩过、以后大概率还会再次踩的坑
- 每条都写清楚错误做法、正确做法、验收方式
- 行为定义仍以 `docs/technical/ARCHITECTURE.md` 为准
- 如果架构文档和这里冲突，先修这里，再同步修架构文档，不能长期分叉

## 2. 使用规则

新增一条记录前，先判断是否同时满足这三个条件：

1. 这个问题已经在 SpeakDock 里真实发生过
2. 这个问题不是一次性语法错误，而是有重复踩坑风险
3. 这个问题可以被稳定复现或稳定验收

每条记录都必须包含：

- 现象
- 错误做法
- 正确做法
- 当前项目里的落实位置
- 验收方式

## 3. 当前已确认的坑

### 3.1 不要在 `NSApp` 尚未就绪前碰激活策略或 app icon

现象：

- `make run` 后直接闪退
- 或 launch 早期无响应
- 或测试环境里 `NSApp` 为空导致状态异常

错误做法：

- 在 SwiftUI `App.init()` 里直接访问 `NSApp`
- 在 app 还没进入 `applicationWillFinishLaunching` / `applicationDidFinishLaunching` 前切换 activation policy
- 在过早时机设置 app icon

正确做法：

- 用 `@NSApplicationDelegateAdaptor` 挂 `AppRuntime`
- 只在 `applicationWillFinishLaunching` / `applicationDidFinishLaunching` 里触碰 `NSApplication`
- 所有会访问 `NSApp` 的逻辑都要允许 `NSApp == nil`

当前落实位置：

- `Sources/SpeakDockMac/App/AppRuntime.swift`
- `Tests/SpeakDockMacTests/AppRuntimeTests.swift`

验收方式：

- `make test`
- `make build`
- `make run`
- `make logs LOG_WINDOW=2m` 中能看到 `application did finish launching`

### 3.2 `menu bar icon` 不能直接缩小 `app icon`

现象：

- 菜单栏图标看不清
- 深浅色模式下对比度不稳定
- 用户误以为菜单栏没图标

错误做法：

- 直接把彩色 `app icon` 缩小塞进菜单栏
- 在极小尺寸里保留过多细节

正确做法：

- `app icon` 和 `menu bar glyph` 保持同一语义，但不是同一张图
- `menu bar glyph` 只保留模板化、单色、小尺寸可读的形体
- `app icon` 负责品牌识别，`menu bar glyph` 负责状态入口

当前落实位置：

- `Sources/SpeakDockMac/UI/SpeakDockVisualStyle.swift`
- `Sources/SpeakDockMac/App/SpeakDockApp.swift`

验收方式：

- 菜单栏常驻图标在浅色 / 深色系统外观下都能稳定看见
- `Fn` 不可用时状态点仍清楚

### 3.3 `Settings` 与 `menu popup` 不要再各画一套品牌图

现象：

- Dock 图标、设置页图标、菜单弹窗图标长得像但不一样
- 用户会直接感知为“图没统一”

错误做法：

- 在 SwiftUI 里单独画一份近似 logo
- app icon、运行时 icon、设置页 icon 分别维护

正确做法：

- `Settings` 和 `menu popup` 直接复用同一份生成后的 app icon 资源
- 只有 `menu bar` 保留独立 glyph

当前落实位置：

- `Sources/SpeakDockMac/UI/SpeakDockVisualStyle.swift`
- `Sources/SpeakDockMac/App/AppRuntime.swift`
- `.build/icon-work/AppIcon-1024.png`

验收方式：

- Dock 图标与设置页左上角品牌图保持一致
- 菜单弹窗 header 品牌图也来自同一资源

### 3.4 app icon 必须有单一生成链路

现象：

- `svg`、Swift 渲染脚本、`icns` 彼此漂移
- 看起来改了 logo，但 Dock 还是旧图

错误做法：

- 只改 `svg` 不改渲染脚本
- 只改运行时 `png` 不验证 `icns`
- 把“本机暂时看起来对”当成完成

正确做法：

- 改 logo 时同时检查 `Artwork/AppIcon.svg` 与 `scripts/render-app-icon.swift`
- 构建后确认 `AppIcon-1024.png` 和 `SpeakDock.icns` 都重新生成
- 运行时读取 bundle 内的统一资源

当前落实位置：

- `Artwork/AppIcon.svg`
- `scripts/render-app-icon.swift`
- `scripts/generate-app-icon.sh`
- `scripts/build-app.sh`

验收方式：

- `make build`
- 确认 `.build/icon-work/SpeakDock.icns` 存在且已刷新
- 确认 `.build/icon-work/AppIcon-1024.png` 为新图

### 3.5 触发键权限失败时不能偷偷切换策略

现象：

- 用户以为 `Fn` 还在工作，实际上系统权限不够
- 或产品偷偷切到别的热键，用户完全不知情

错误做法：

- `Fn` 不可用时自动切换固定替代 trigger
- 只在日志里报错，不在产品入口里提醒

正确做法：

- `Fn` 不可用时，menu bar 明确显示不可用状态
- 用户只能在 `Settings` 里显式切换替代 trigger
- 权限用途和缺失表现必须写在 README 与手测文档里

当前落实位置：

- `README.md`
- `docs/plans/2026-04-10-speakdock-macos-v1-manual-test.md`
- `docs/technical/ARCHITECTURE.md`

验收方式：

- 移除辅助功能权限后，menu bar 明确提示不可用
- 产品不会自动切 trigger

### 3.6 输入注入目标要在按下时捕获，不要在结束时临时猜

现象：

- 松开触发键后，文本发到了错误位置
- 焦点在录音期间切走，提交目标漂移

错误做法：

- 只在结束录音时再找当前焦点
- 依赖系统全局 focused element 一次命中

正确做法：

- 在 press start 时就捕获 compose target
- 结束时优先使用 press start 捕获到的目标
- 对拿不到标准可编辑节点的 App，允许明确的 fallback 策略

当前落实位置：

- `Sources/SpeakDockMac/ClipboardComposeTarget.swift`
- `Sources/SpeakDockMac/HotPathCoordinator.swift`
- `Tests/SpeakDockMacTests/ComposeTargetSessionTests.swift`
- `Tests/SpeakDockMacTests/ComposeTargetFallbackPolicyTests.swift`

验收方式：

- `make probe-compose PROBE_SECONDS=30`
- `make logs LOG_WINDOW=2m`
- 看日志里是否出现 `compose target captured at press start`

### 3.7 日志必须用统一 `os.Logger`，不能回到临时打印

现象：

- 闪退、权限、ASR、注入问题难以回溯
- 临时 `print` 很快失控，无法长期维护

错误做法：

- 到处打 `print`
- category 不稳定，日志检索词经常变

正确做法：

- 统一使用 `os.Logger`
- subsystem 固定为 `com.leozejia.speakdock`
- category 按生命周期、权限、trace、触发器、语音、音频、注入等稳定拆分

当前落实位置：

- `Sources/SpeakDockMac/Logging/SpeakDockLog.swift`
- `scripts/show-logs.sh`
- `scripts/show-traces.sh`
- `scripts/report-traces.py`

验收方式：

- `make logs LOG_WINDOW=5m`
- `make traces TRACE_WINDOW=5m`
- `make trace-report TRACE_WINDOW=5m`
- `make term-learning-report`
- `make smoke-term-learning`
- 关键链路都能按 category 找到，热路径能看到统一 `trace.finish`
- 聚合报告能直接看到最近 `kind / result / origin / route / latency`
- 词典学习报告能直接看到 `observed / promoted / conflicted / skippedConfirmed` 结果分布

### 3.7 正常开发启动不能用 `open -n`

现象：

- `make run` 反复执行后，会出现多个常驻 `SpeakDock`
- menu bar、Dock、权限和焦点行为开始互相干扰

根因：

- `open -n` 会强制 LaunchServices 新开实例
- 这会主动绕过正常用户态应有的单实例语义

当前落实位置：

- `scripts/run-dev.sh`
- `Sources/SpeakDockMac/App/AppRuntime.swift`
- `Tests/SpeakDockMacTests/BuildScriptTests.swift`
- `Tests/SpeakDockMacTests/AppRuntimeTests.swift`

验收方式：

- `make run` 连续执行两次
- 第二次启动后不应出现新的常驻实例
- 现有实例应被复用并回到前台
- 只有 `probe / smoke` 这类隔离测试路径允许显式多开

### 3.8 `App Language` 和 `Input Language` 必须分离

现象：

- 界面语言切换后误伤 ASR 识别语言
- 用户想中文界面 + 英文输入，做不到

错误做法：

- 用一个 `language` 字段同时驱动 UI 和 ASR

正确做法：

- UI 语言与输入语言分离
- ASR 只消费 `Input Language`
- 左上角系统菜单与运行时文案跟随 `App Language`

当前落实位置：

- `Sources/SpeakDockMac/SettingsStore.swift`
- `Sources/SpeakDockMac/SpeechController.swift`
- `Sources/SpeakDockMac/AppLocalizer.swift`

验收方式：

- 切 `App Language` 只影响界面
- 切 `Input Language` 只影响识别

### 3.9 macOS `Settings` 不要做成“外壳里再套一个网页壳”

现象：

- 用户会感觉窗体外壳和里面内容像两套分离的 UI
- pane 切换时虽然窗口尺寸没变，但视觉重心和填充感在漂
- 整个设置页更像网页后台，而不是 macOS 原生设置窗

错误做法：

- 外层先画一个大壳体，里面再放一个独立的大圆角 detail 卡片
- detail 内部继续用很多浮起的大卡片强调每个 section
- 不同 pane 各自用不同版式，导致切换时内容密度和留白节奏不一致

正确做法：

- 把窗体先定义成一个统一的 `sidebar + detail` 结构
- detail 应该是连续内容区，不要再套第二层大壳
- section 只做轻量分组，不要每层都强调自己是独立面板
- `General / Dictionary / Refine` 使用同一套双列节奏和相近的信息密度

当前落实位置：

- `Sources/SpeakDockMac/Settings/SettingsView.swift`

验收方式：

- 切换 pane 时，用户不会再明显感觉“外壳一层、内容另一层”
- 三个 pane 都沿用同一套整体布局节奏
- detail 内容区视觉上能自然填满整个设置窗右侧

### 3.10 不要在自定义窄设置壳体里硬套 `LabeledContent`

现象：

- 中文 label 会出现挤压、错位或看起来像左侧单独裂开一块
- `Refine` 这类页里容易出现重复区块、左侧渲染异常或局部撑宽
- 同一份设置内容，放进系统 `Form` 看起来正常，放进自定义壳体就开始漂

错误做法：

- 在已经自定义了 `sidebar + detail + secondary rail` 的壳体里，继续把 `LabeledContent` 当成通用字段布局
- 让系统自动 label 对齐逻辑和自定义窄卡片宽度互相打架

正确做法：

- 在自定义设置壳体里显式写字段结构：`label -> control -> footnote`
- 对窄容器和双列布局使用自己的 `VStack` / `HStack` 结构，不再赌系统自动排版
- 如果页面已经不是原生 `Form` 语义，就不要半套原生表单、半套自定义壳体混用

当前落实位置：

- `Sources/SpeakDockMac/Settings/SettingsView.swift`

验收方式：

- 切换 `General / Dictionary / Refine` 时不再出现局部撑宽和重复区块
- 中英文下字段标题、输入框、说明文字都保持稳定
- `Refine` 左侧不再出现异常渲染

## 4. 每轮结束前的固定检查

所有涉及 Swift/macOS 行为改动的任务，结束前至少检查：

1. `make test`
2. `make build`
3. 必要时 `make run`
4. 必要时 `make logs LOG_WINDOW=2m`
5. 如果改了 icon，再检查 `.icns` 和运行时实际显示

## 5. 后续新增原则

未来如果再补新坑，只允许加在这一个文件里，不允许再散落到：

- 零散临时 markdown
- commit message 里
- 聊天记录里
- 未索引的 research note 里
