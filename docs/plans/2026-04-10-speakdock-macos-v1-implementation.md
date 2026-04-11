# SpeakDock macOS v1 Implementation Plan

**Goal:** 构建 SpeakDock 的首个 macOS v1 可运行版本，打通 `按住说话 -> 松开 -> 转录/整理 -> 写入 -> 可撤回` 的本地优先热路径。

**Architecture:** 采用 `一个共享核心 + 一个 macOS 壳层` 的结构。先把 `Workspace + raw_context + TriggerAdapter + ASR + TargetAdapter` 跑通，再补 `RefineEngine` 与 `WikiCompiler` 的可插拔接口，保证后续 iOS 和更多硬件输入源都能复用核心。

**Tech Stack:** Swift 5.10+, Swift Package Manager, SwiftUI/AppKit, Apple Speech, AVFoundation, CGEvent tap, UserDefaults, XCTest

---

## 0. 目录目标

本计划默认最终形成如下目录：

```text
speakdock/
  Package.swift
  Makefile
  Sources/
    SpeakDockCore/
      Models/
      Workspace/
      Trigger/
      Refine/
      Capture/
      Routing/
    SpeakDockMac/
      App/
      MenuBar/
      Overlay/
      Trigger/
      Audio/
      Speech/
      Target/
      Settings/
      Resources/
  Tests/
    SpeakDockCoreTests/
    SpeakDockMacTests/
  scripts/
    build-app.sh
    run-dev.sh
```

## 1. 开发原则

- 只先做 `macOS first`
- 只先做 `Compose + Capture`
- `Wiki` 只保留后台接口，不进入 v1 热路径实现
- `DJI` 先只做输入层协议，不在 v1 第一轮就做完整硬件适配
- 每个 Task 完成后都要能被独立验证

## 2. 任务顺序

### Task 1: 建立 Swift Package 与 app 壳层骨架

**Files:**
- Create: `Package.swift`
- Create: `Makefile`
- Create: `scripts/build-app.sh`
- Create: `scripts/run-dev.sh`
- Create: `Sources/SpeakDockMac/App/SpeakDockApp.swift`
- Create: `Sources/SpeakDockMac/App/AppRuntime.swift`
- Create: `Sources/SpeakDockMac/Resources/Info.plist`

**Step 1: 写骨架文件**

- 创建 `Package.swift`，包含 `SpeakDockCore` library target、`SpeakDockMac` executable target、测试 target
- 创建 `Makefile`，至少包含 `build / run / clean / test`
- 创建最小可启动的 `SpeakDockApp.swift`

**Step 2: 运行基础构建**

Run:

```bash
make build
```

Expected:

- `swift build` 成功
- 生成可执行产物

**Step 3: 接入 LSUIElement**

- 在 `Info.plist` 中设置 `LSUIElement = 1`
- 确保 app 以 menu bar 工具形态运行

**Step 4: 手动验证**

Run:

```bash
make run
```

Expected:

- 应用启动
- 无 Dock 图标
- 菜单栏出现 SpeakDock 图标

**Step 5: Commit**

```bash
git add Package.swift Makefile scripts/build-app.sh scripts/run-dev.sh Sources/SpeakDockMac/App/SpeakDockApp.swift Sources/SpeakDockMac/App/AppRuntime.swift Sources/SpeakDockMac/Resources/Info.plist
git commit -m "chore: scaffold macOS app shell"
```

### Task 2: 建立核心工作区模型

**Files:**
- Create: `Sources/SpeakDockCore/Models/Mode.swift`
- Create: `Sources/SpeakDockCore/Models/Workspace.swift`
- Create: `Sources/SpeakDockCore/Models/WorkspaceState.swift`
- Create: `Sources/SpeakDockCore/Workspace/WorkspaceReducer.swift`
- Create: `Tests/SpeakDockCoreTests/WorkspaceReducerTests.swift`

**Step 1: 写失败测试**

覆盖这些行为：

- 焦点切换时创建新工作区
- 第一次说话前，起始点可变
- 第一次说话后，起始点冻结
- 追加说话会累积 `raw_context`
- 整理后再点一次会撤回到 `raw_context`
- 整理后若被手动修改，撤回前应标记 `dirty`

**Step 2: 运行测试确认失败**

Run:

```bash
swift test --filter WorkspaceReducerTests
```

Expected:

- 失败，提示缺少类型或行为

**Step 3: 实现最小模型**

- 定义 `Compose / Capture / Wiki`
- 定义 `Workspace`
- 定义 `raw_context`
- 定义 `dirty`
- 用 reducer 形式实现状态转移

**Step 4: 运行测试确认通过**

Run:

```bash
swift test --filter WorkspaceReducerTests
```

Expected:

- 全部通过

**Step 5: Commit**

```bash
git add Sources/SpeakDockCore/Models/Mode.swift Sources/SpeakDockCore/Models/Workspace.swift Sources/SpeakDockCore/Models/WorkspaceState.swift Sources/SpeakDockCore/Workspace/WorkspaceReducer.swift Tests/SpeakDockCoreTests/WorkspaceReducerTests.swift
git commit -m "feat: add workspace core model"
```

### Task 3: 建立设置模型与菜单栏基础设置

**Files:**
- Create: `Sources/SpeakDockCore/Models/AppSettings.swift`
- Create: `Sources/SpeakDockMac/Settings/SettingsStore.swift`
- Create: `Sources/SpeakDockMac/Settings/SettingsView.swift`
- Create: `Sources/SpeakDockMac/Capture/CaptureRootMigrator.swift`
- Create: `Sources/SpeakDockMac/MenuBar/MenuBarRoot.swift`
- Create: `Tests/SpeakDockMacTests/SettingsStoreTests.swift`

**Step 1: 写失败测试**

覆盖这些行为：

- 默认语言为 `zh-CN`
- 默认 capture 根目录为桌面
- 默认 trigger 为 `Fn`
- `RefineEngine` 默认关闭
- `API Key` 可以被清空
- 设置值能持久化并重新加载
- 用户显式切换到替代 trigger 后，设置值能持久化并重新加载
- capture 根目录变更时，支持一键整体迁移
- 目标目录冲突时，迁移中止并提示

**Step 2: 运行测试确认失败**

Run:

```bash
swift test --filter SettingsStoreTests
```

Expected:

- 失败

**Step 3: 实现设置层**

- 用 `UserDefaults` 持久化语言、capture 根目录、默认/替代 trigger、refine 开关、`Base URL / API Key / Model`
- 实现 capture 根目录整体迁移
- 菜单栏至少提供：
  - 打开设置
  - 切换语言
  - 显示当前 trigger 状态
  - 当 `Fn` 不可用时进入替代 trigger 配置入口
  - 启用/禁用 refine
  - 退出

**Step 4: 运行测试与手动验证**

Run:

```bash
swift test --filter SettingsStoreTests
make run
```

Expected:

- 单测通过
- 菜单栏可以打开设置界面

**Step 5: Commit**

```bash
git add Sources/SpeakDockCore/Models/AppSettings.swift Sources/SpeakDockMac/Settings/SettingsStore.swift Sources/SpeakDockMac/Settings/SettingsView.swift Sources/SpeakDockMac/Capture/CaptureRootMigrator.swift Sources/SpeakDockMac/MenuBar/MenuBarRoot.swift Tests/SpeakDockMacTests/SettingsStoreTests.swift
git commit -m "feat: add settings and menu bar root"
```

### Task 4: 建立 TriggerAdapter 与默认键盘触发

**Files:**
- Create: `Sources/SpeakDockCore/Trigger/TriggerEvent.swift`
- Create: `Sources/SpeakDockCore/Trigger/TriggerAdapter.swift`
- Create: `Sources/SpeakDockMac/Trigger/FnKeyTriggerAdapter.swift`
- Create: `Sources/SpeakDockMac/Trigger/TriggerController.swift`
- Create: `Tests/SpeakDockCoreTests/TriggerEventTests.swift`

**Step 1: 写失败测试**

覆盖这些行为：

- `press -> release` 产生一次录音触发
- 快速双击产生 `submit`
- 非法事件顺序被忽略

**Step 2: 运行测试确认失败**

Run:

```bash
swift test --filter TriggerEventTests
```

Expected:

- 失败

**Step 3: 实现纯逻辑层**

- 实现 `TriggerEvent`
- 实现双击窗口判断
- 实现触发状态机

**Step 4: 接入 macOS 默认触发**

- 使用 `CGEvent tap` 或等价机制监听 `Fn`
- 抑制 `Fn` 事件继续传递
- 把事件映射到核心 `TriggerEvent`
- 如果默认 `Fn` 路径不可用，不自动切换到某个固定热键
- menu bar 明确显示 `Fn` 当前不可用
- 用户必须在 Settings 里显式选择替代 trigger 后，才切换到新的 trigger
- 菜单栏明确展示 trigger 是否可用

**Step 5: 手动验证并 Commit**

Run:

```bash
make run
```

Expected:

- 按住 `Fn` 开始录音准备
- 松开 `Fn` 结束
- 双击 `Fn` 产生提交事件
- 不再弹系统 emoji 面板
- 如果默认 trigger 不可用，menu bar 能提示异常状态
- 显式切换到替代 trigger 后，按住/松开/双击语义保持一致

```bash
git add Sources/SpeakDockCore/Trigger/TriggerEvent.swift Sources/SpeakDockCore/Trigger/TriggerAdapter.swift Sources/SpeakDockMac/Trigger/FnKeyTriggerAdapter.swift Sources/SpeakDockMac/Trigger/TriggerController.swift Tests/SpeakDockCoreTests/TriggerEventTests.swift
git commit -m "feat: add trigger adapter and fn path"
```

### Task 5: 建立音频采集与悬浮反馈层

**Files:**
- Create: `Sources/SpeakDockMac/Audio/AudioCaptureEngine.swift`
- Create: `Sources/SpeakDockMac/Audio/LevelSmoother.swift`
- Create: `Sources/SpeakDockMac/Overlay/OverlayPanelController.swift`
- Create: `Sources/SpeakDockMac/Overlay/OverlayView.swift`
- Create: `Tests/SpeakDockMacTests/LevelSmootherTests.swift`

**Step 1: 写失败测试**

覆盖这些行为：

- RMS 电平输入被平滑处理
- 低电平时波形收敛
- 高电平时波形明显抬升

**Step 2: 运行测试确认失败**

Run:

```bash
swift test --filter LevelSmootherTests
```

Expected:

- 失败

**Step 3: 实现最小音频层**

- 建立麦克风权限请求
- 建立实时音频采集
- 输出 RMS 电平
- 实现平滑器

**Step 4: 实现反馈层**

- 底部居中悬浮层
- 实时显示转录文本
- 实时波形
- `Listening / Thinking / Refining` 状态可见

**Step 5: 手动验证并 Commit**

Run:

```bash
make run
```

Expected:

- 录音时出现悬浮层
- 波形跟真实声音变化同步
- 停止录音后正确退场

```bash
git add Sources/SpeakDockMac/Audio/AudioCaptureEngine.swift Sources/SpeakDockMac/Audio/LevelSmoother.swift Sources/SpeakDockMac/Overlay/OverlayPanelController.swift Sources/SpeakDockMac/Overlay/OverlayView.swift Tests/SpeakDockMacTests/LevelSmootherTests.swift
git commit -m "feat: add audio capture and overlay feedback"
```

### Task 6: 建立流式 ASR 与语言切换

**Files:**
- Create: `Sources/SpeakDockCore/Models/LanguageOption.swift`
- Create: `Sources/SpeakDockCore/Routing/RecognitionResult.swift`
- Create: `Sources/SpeakDockMac/Speech/AppleSpeechEngine.swift`
- Create: `Sources/SpeakDockMac/Speech/SpeechController.swift`
- Create: `Tests/SpeakDockCoreTests/LanguageOptionTests.swift`

**Step 1: 写失败测试**

覆盖这些行为：

- 默认语言为 `zh-CN`
- 支持英语、简体中文、繁体中文、日语、韩语
- 语言值可安全序列化和恢复

**Step 2: 运行测试确认失败**

Run:

```bash
swift test --filter LanguageOptionTests
```

Expected:

- 失败

**Step 3: 实现最小语言层与 ASR 接口**

- 定义语言枚举
- 接入 Apple Speech
- 支持流式 partial transcript
- 录音过程中把 partial transcript 推给 overlay

**Step 4: 手动验证**

Run:

```bash
make run
```

Expected:

- 中文默认可直接识别
- 菜单栏切换语言后，新会话使用新语言
- partial transcript 能实时显示

**Step 5: Commit**

```bash
git add Sources/SpeakDockCore/Models/LanguageOption.swift Sources/SpeakDockCore/Routing/RecognitionResult.swift Sources/SpeakDockMac/Speech/AppleSpeechEngine.swift Sources/SpeakDockMac/Speech/SpeechController.swift Tests/SpeakDockCoreTests/LanguageOptionTests.swift
git commit -m "feat: add streaming speech engine and language switching"
```

### Task 7: 建立 Compose 与 Capture 输出适配

**Files:**
- Create: `Sources/SpeakDockCore/Routing/RouteDecision.swift`
- Create: `Sources/SpeakDockCore/Capture/CaptureFileNamer.swift`
- Create: `Sources/SpeakDockMac/Target/ClipboardComposeTarget.swift`
- Create: `Sources/SpeakDockMac/Target/CaptureFileTarget.swift`
- Create: `Sources/SpeakDockMac/Target/InputSourceSwitcher.swift`
- Create: `Tests/SpeakDockCoreTests/CaptureFileNamerTests.swift`

**Step 1: 写失败测试**

覆盖这些行为：

- 只有在可可靠判定为可编辑文本目标时，`Compose` 才被选中
- `Capture` 在无光标时被选中
- 权限缺失、目标不可判定、或目标不可安全注入时，不静默降级到 `Capture`
- capture 文件名格式为 `speakdock-YYYYMMDD-HHMMSS.md`
- 默认目录为桌面
- `Capture` 首次落盘后，后续一律追加文件尾部

**Step 2: 运行测试确认失败**

Run:

```bash
swift test --filter CaptureFileNamerTests
```

Expected:

- 失败

**Step 3: 实现输出适配**

- `Compose` 只在 Accessibility 聚焦元素可判定为可编辑控件时成立
- `Compose` 走剪贴板 + `Cmd+V`
- CJK 输入源切到 ASCII 后再粘贴
- 粘贴后恢复输入源和剪贴板
- 当前目标不可可靠注入时，直接报 `Compose` 不可用
- `Capture` 生成本地 `MD`
- 首句写入后自动打开默认编辑器
- 后续继续追加到同一文件尾部
- 不跟随默认编辑器当前光标

**Step 4: 手动验证**

Run:

```bash
make run
```

Expected:

- 聊天框内能直接注入文字
- 中文输入法下也能稳定注入
- 权限缺失或目标不可注入时，不会误写成 `Capture`
- 桌面上无输入框时会生成 `speakdock-*.md`
- 系统默认编辑器自动打开该文件
- 后续继续说时，内容继续追加到文件尾部

**Step 5: Commit**

```bash
git add Sources/SpeakDockCore/Routing/RouteDecision.swift Sources/SpeakDockCore/Capture/CaptureFileNamer.swift Sources/SpeakDockMac/Target/ClipboardComposeTarget.swift Sources/SpeakDockMac/Target/CaptureFileTarget.swift Sources/SpeakDockMac/Target/InputSourceSwitcher.swift Tests/SpeakDockCoreTests/CaptureFileNamerTests.swift
git commit -m "feat: add compose and capture targets"
```

### Task 8: 建立整理/撤回与 refine 接口

**Files:**
- Create: `Sources/SpeakDockCore/Refine/RefineEngine.swift`
- Create: `Sources/SpeakDockCore/Refine/ConservativeRefinePrompt.swift`
- Create: `Sources/SpeakDockCore/Refine/CleanNormalizer.swift`
- Create: `Sources/SpeakDockMac/Refine/OpenAICompatibleRefineEngine.swift`
- Create: `Tests/SpeakDockCoreTests/ConservativeRefinePromptTests.swift`

**Step 1: 写失败测试**

覆盖这些行为：

- prompt 强调“只修复明显识别错误”
- prompt 明确禁止润色、改写、删减
- 未启用 refine 时热路径直接提交
- 未启用 refine 时，`Clean` 只做确定性清洗

**Step 2: 运行测试确认失败**

Run:

```bash
swift test --filter ConservativeRefinePromptTests
```

Expected:

- 失败

**Step 3: 实现 refine 接口**

- 定义 `CleanNormalizer`
- 定义 `RefineEngine` 协议
- 定义保守纠错 prompt
- 实现 OpenAI 兼容客户端
- 把 `Refining...` 状态接到 overlay
- 默认热路径先只依赖 `CleanNormalizer`

**Step 4: 手动验证**

Run:

```bash
make run
```

Expected:

- 关闭 refine 时，松开后直接提交
- 开启 refine 且配置完整时，先显示 `Refining...`
- refine 完成后再提交文本

**Step 5: Commit**

```bash
git add Sources/SpeakDockCore/Refine/RefineEngine.swift Sources/SpeakDockCore/Refine/ConservativeRefinePrompt.swift Sources/SpeakDockCore/Refine/CleanNormalizer.swift Sources/SpeakDockMac/Refine/OpenAICompatibleRefineEngine.swift Tests/SpeakDockCoreTests/ConservativeRefinePromptTests.swift
git commit -m "feat: add conservative refine engine"
```

### Task 9: 打通整理按钮、撤回、双击提交

**Files:**
- Create: `Sources/SpeakDockMac/App/HotPathCoordinator.swift`
- Modify: `Sources/SpeakDockCore/Workspace/WorkspaceReducer.swift`
- Modify: `Sources/SpeakDockMac/MenuBar/MenuBarRoot.swift`
- Modify: `Sources/SpeakDockMac/Overlay/OverlayView.swift`
- Modify: `Sources/SpeakDockMac/Overlay/OverlayPanelController.swift`
- Create: `Tests/SpeakDockCoreTests/UndoFlowTests.swift`

**Step 1: 写失败测试**

覆盖这些行为：

- 当前工作区可整理
- 整理后再次点击会撤回
- 整理后用户手改再撤回会触发确认需求
- `Compose` 下双击提交会结束当前工作区
- `UndoWindow` 固定为 8 秒
- `Capture` 撤回只删除最近一次追加到文件尾部的片段
- overlay 上的第二按钮承接整理 / 撤回入口

**Step 2: 运行测试确认失败**

Run:

```bash
swift test --filter UndoFlowTests
```

Expected:

- 失败

**Step 3: 实现最小协调层**

- 串起 trigger、audio、speech、route、target、refine
- 在 overlay 上接入整理按钮
- 接入撤回
- 接入双击提交
- 写死 `UndoWindow = 8 秒`
- 按文档优先级复用第二按钮语义
- `Capture` 回滚只回退最近一次尾部追加片段

**Step 4: 手动验证**

Run:

```bash
make run
```

Expected:

- 一整条热路径可跑通
- 整理/撤回行为符合文档
- 双击提交在聊天框可用
- overlay 上第二按钮可完成整理 / 撤回
- `UndoWindow` 超时后按钮恢复普通整理

**Step 5: Commit**

```bash
git add Sources/SpeakDockMac/App/HotPathCoordinator.swift Sources/SpeakDockCore/Workspace/WorkspaceReducer.swift Sources/SpeakDockMac/MenuBar/MenuBarRoot.swift Sources/SpeakDockMac/Overlay/OverlayView.swift Sources/SpeakDockMac/Overlay/OverlayPanelController.swift Tests/SpeakDockCoreTests/UndoFlowTests.swift
git commit -m "feat: wire hot path and undo flow"
```

### Task 10: 收尾与验收清单

**Files:**
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/technical/ARCHITECTURE.md`
- Create: `docs/plans/2026-04-10-speakdock-macos-v1-manual-test.md`

**Step 1: 补 README**

- 写启动方式
- 写权限要求
- 写权限矩阵
- 写已支持功能
- 写未支持范围
- 写默认 trigger 与替代 trigger 说明
- 写“`Fn` 不可用时不自动切换，必须显式选择替代 trigger”
- 写每项权限对应的功能与失败表现

**Step 2: 补人工验收清单**

至少覆盖：

- 启动后 menu bar 可见
- `Fn` 按住/松开可用
- 双击提交可用
- `Fn` 默认路径下不弹 emoji 面板
- `Fn` 不可用时，menu bar 会明确提示
- 用户显式切换到替代 trigger 后，替代 trigger 可用
- 默认语言为中文
- 语言切换生效
- 悬浮层与波形可见
- overlay 第二按钮可见
- `Compose` 注入可用
- 权限缺失时，`Compose` 不会静默降级成 `Capture`
- `Capture` 生成 `MD` 并自动打开
- 后续语音追加到文件尾部
- capture 根目录迁移可用
- `整理 / 撤回` 可用
- `UndoWindow = 8 秒` 行为正确
- refine 配置、测试、启停可用

**Step 3: 跑最终验证**

Run:

```bash
make test
make build
```

Expected:

- 单测通过
- 构建通过

**Step 4: Commit**

```bash
git add README.md docs/README.md docs/technical/ARCHITECTURE.md docs/plans/2026-04-10-speakdock-macos-v1-manual-test.md
git commit -m "docs: add macOS v1 test checklist and polish docs"
```

## 3. 完成标准

满足以下条件才算 macOS v1 第一轮完成：

- menu bar app 可稳定启动
- 默认 `Fn` 热路径可用
- `Fn` 不可用时，menu bar 能告警且可切换替代 trigger
- 中文默认可识别
- `Compose` 注入成功
- `Capture` 生成并打开本地 `MD`
- `整理 / 撤回` 行为正确
- refine 为可选能力，不阻塞默认热路径
- 在 MacBook Air M3 16GB 上可反复使用而不明显发热或拖慢前台 app
