# SpeakDock macOS v1 执行日志

## 1. 目的

这份文档只记录执行状态、验证结果和实现偏差。

- 架构定义仍以 `docs/technical/ARCHITECTURE.md` 为准
- 任务顺序仍以 `docs/plans/2026-04-10-speakdock-macos-v1-implementation.md` 为准
- 只有当实现事实要求修改真相源时，才回写主文档

## 2. 当前状态

- 当前阶段：`Task 10` 已完成
- 当前目标：进入图形环境执行人工验收清单
- 当前策略：代码与文档先保持同步，剩余风险统一通过手动验收逐项确认

## 3. 任务看板

| Task | 状态 | 说明 |
| --- | --- | --- |
| Task 1 | Complete | SwiftPM 骨架、脚本、最小 menu bar app 已落地 |
| Task 2 | Complete | `Workspace` 核心模型与 reducer 已落地 |
| Task 3 | Complete | 设置层、capture 根目录迁移与菜单栏基础设置已落地 |
| Task 4 | Complete | TriggerAdapter、默认 trigger 核心逻辑与菜单栏状态已落地 |
| Task 5 | Complete | 音频采集、RMS 平滑与 overlay 反馈层已落地 |
| Task 6 | Complete | 流式 ASR、语言模型与 partial transcript 接线已落地 |
| Task 7 | Complete | Compose / Capture 输出适配与最终文本落点已接线 |
| Task 8 | Complete | Clean normalizer、保守 refine prompt 与 OpenAI 兼容 refine 已接线 |
| Task 9 | Complete | 整理、撤回、双击提交 已接线 |
| Task 10 | Complete | 收尾、README、人工验收清单 已对齐 |

## 4. 执行记录

### 2026-04-11

#### Task 1

- 状态：`Complete`
- 目标：建立可构建、可运行、可继续扩展的 macOS 工程骨架
- 已完成产物：
  - `Package.swift`
  - `Makefile`
  - `scripts/build-app.sh`
  - `scripts/run-dev.sh`
  - `Sources/SpeakDockCore/*`
  - `Sources/SpeakDockMac/App/*`
  - `Sources/SpeakDockMac/Resources/Info.plist`
  - `Tests/SpeakDockCoreTests/SpeakDockCoreSmokeTests.swift`
  - `Tests/SpeakDockMacTests/SpeakDockMacSmokeTests.swift`
- 额外工程化调整：
  - 增加仓库本地 `.swift-home` 与 `.swift-cache`，避免验证命令依赖用户级缓存目录
  - `Makefile` 增加 `TEST_FILTER` 支持，便于后续按 task 和行为做聚焦测试
- 验证结果：
  - `make build` -> pass
  - `make test` -> pass
  - `make run` -> app 启动后进程保持存活，入口冒烟通过
- 备注：
  - menu bar 图标是否可见、是否无 Dock 图标，仍需按手动验收清单在图形环境中确认

#### Task 2

- 状态：`Complete`
- 目标：建立 `Mode / Workspace / WorkspaceState / WorkspaceReducer`
- 已完成文件：
  - `Sources/SpeakDockCore/Models/Mode.swift`
  - `Sources/SpeakDockCore/Models/Workspace.swift`
  - `Sources/SpeakDockCore/Models/WorkspaceState.swift`
  - `Sources/SpeakDockCore/Workspace/WorkspaceReducer.swift`
  - `Tests/SpeakDockCoreTests/WorkspaceReducerTests.swift`
- 已验证行为：
  - 焦点切换时创建新工作区
  - 第一次说话前，起始点可变
  - 第一次说话后，起始点冻结
  - 追加说话会累积 `raw_context`
  - 整理后再点一次会撤回到 `raw_context`
  - 整理后若被手动修改，工作区会标记 `dirty`
- Red / Green 记录：
  - `WorkspaceReducerTests/testFocusSwitchCreatesNewWorkspace`：RED -> GREEN
  - `WorkspaceReducerTests/testCursorMoveBeforeFirstSpeechUpdatesStartLocation`：RED -> GREEN
  - `WorkspaceReducerTests/testCursorMoveAfterFirstSpeechKeepsStartLocationFrozen`：RED -> GREEN
  - `WorkspaceReducerTests/testSpeechAppendAccumulatesRawContext`：已有实现覆盖，测试补齐后直接通过
  - `WorkspaceReducerTests/testUndoAfterRefineRestoresRawContext`：RED -> GREEN
  - `WorkspaceReducerTests/testManualEditAfterRefineMarksWorkspaceDirty`：RED -> GREEN
- 验证结果：
  - `make test TEST_FILTER=WorkspaceReducerTests` -> pass
  - `make test` -> pass

#### Task 3

- 状态：`Complete`
- 目标：建立 `AppSettings / SettingsStore / CaptureRootMigrator / SettingsView / MenuBarRoot`
- 已完成文件：
  - `Sources/SpeakDockCore/Models/AppSettings.swift`
  - `Sources/SpeakDockMac/Capture/CaptureRootMigrator.swift`
  - `Sources/SpeakDockMac/Settings/SettingsStore.swift`
  - `Sources/SpeakDockMac/Settings/SettingsView.swift`
  - `Sources/SpeakDockMac/MenuBar/MenuBarRoot.swift`
  - `Tests/SpeakDockMacTests/SettingsStoreTests.swift`
- 已验证行为：
  - 默认语言为 `zh-CN`
  - 默认 capture 根目录为桌面
  - 默认 trigger 为 `Fn`
  - refine 默认关闭
  - 设置值能持久化并重新加载
  - `API Key` 可以被清空并持久化
  - 用户显式切换到替代 trigger 后，设置值能持久化并重新加载
  - capture 根目录整体迁移成功时，文件被整体搬迁且新路径持久化
  - 目标目录冲突时，迁移中止且保持原路径不变
- Red / Green 记录：
  - `SettingsStoreTests/testDefaultsMatchArchitecture`：RED -> GREEN
  - `SettingsStoreTests/testSettingsPersistAndReloadIncludingAlternativeTriggerAndEmptyAPIKey`：已有实现覆盖，测试补齐后直接通过
  - `SettingsStoreTests/testCaptureRootMigrationMovesExistingFilesAndPersistsNewPath`：已有实现覆盖，测试补齐后直接通过
  - `SettingsStoreTests/testCaptureRootMigrationStopsOnDestinationConflict`：已有实现覆盖，测试补齐后直接通过
- 额外工程化调整：
  - `SettingsStore.settings` 变更自动持久化，避免菜单栏和设置页只改内存不落盘
- 验证结果：
  - `make test TEST_FILTER=SettingsStoreTests` -> pass
  - `make test` -> pass
  - `make run` -> app 启动冒烟通过
- 备注：
  - “菜单栏可打开 Settings” 仍需按人工验收清单在图形环境中点击确认

#### Task 4

- 状态：`Complete`
- 目标：建立 `TriggerEvent / TriggerAdapter / FnKeyTriggerAdapter / TriggerController`
- 已完成文件：
  - `Sources/SpeakDockCore/Trigger/TriggerEvent.swift`
  - `Sources/SpeakDockCore/Trigger/TriggerAdapter.swift`
  - `Sources/SpeakDockMac/Trigger/FnKeyTriggerAdapter.swift`
  - `Sources/SpeakDockMac/Trigger/TriggerController.swift`
  - `Tests/SpeakDockCoreTests/TriggerEventTests.swift`
- 关联接线：
  - `SettingsStore` 增加设置变更回调
  - `SpeakDockApp` 启动时创建 `TriggerController`
  - `MenuBarRoot` 改为显示当前 trigger 可用性状态
- 已验证行为：
  - `press -> release` 产生一次录音动作
  - 快速双击产生 `submit`
  - 非法事件顺序被忽略
  - 默认 trigger 状态会进入菜单栏显示
  - trigger 设置变更会触发控制器重新加载
- Red / Green 记录：
  - `TriggerEventTests/testPressReleaseProducesRecordingAction`：RED -> GREEN
  - `TriggerEventTests/testQuickDoubleClickProducesSubmitAction`：RED -> GREEN
  - `TriggerEventTests/testInvalidEventOrderIsIgnored`：RED -> GREEN
- 验证结果：
  - `make test TEST_FILTER=TriggerEventTests` -> pass
  - `make test` -> pass
  - `make run` -> app 启动冒烟通过
- 备注：
  - `Fn` 实际按住/松开、双击、以及“不弹 emoji 面板”仍需在具备图形权限的人工环境里按手动验收清单确认
  - 替代 trigger 当前支持通过设置值映射到右侧修饰键标识：`right-control / right-option / right-command / right-shift`

#### Task 5

- 状态：`Complete`
- 目标：建立音频采集、RMS 平滑与底部悬浮反馈层
- 已完成文件：
  - `Sources/SpeakDockMac/Audio/AudioCaptureEngine.swift`
  - `Sources/SpeakDockMac/Audio/LevelSmoother.swift`
  - `Sources/SpeakDockMac/Overlay/OverlayPanelController.swift`
  - `Sources/SpeakDockMac/Overlay/OverlayView.swift`
  - `Sources/SpeakDockMac/App/SpeakDockApp.swift`
  - `Sources/SpeakDockMac/Trigger/TriggerController.swift`
  - `Tests/SpeakDockMacTests/LevelSmootherTests.swift`
- 已验证行为：
  - RMS 输入按 `attack = 40% / release = 15%` 进行平滑
  - 低电平会持续收敛下降，不会停留在高位
  - 高电平会明显抬升，适合作为可见波形驱动
  - 按压 trigger 时会进入 `Listening` overlay，并启动麦克风采集
  - 松开后会停止采集；若形成一次录音动作，overlay 会进入 `Thinking`
  - overlay 具备底部居中胶囊形态、5 柱波形和第二按钮占位
  - 麦克风权限不可用时会明确显示 `Microphone Unavailable`
- Red / Green 记录：
  - `LevelSmootherTests/testRMSInputIsSmoothedWithAttackAndRelease`：RED -> GREEN
  - `LevelSmootherTests/testLowLevelConvergesDownward`：RED -> GREEN
  - `LevelSmootherTests/testHighLevelRisesClearly`：RED -> GREEN
- 验证结果：
  - `make test TEST_FILTER=LevelSmootherTests` -> pass
  - `make test` -> pass
  - `make build` -> pass
  - `make run` -> app 启动后进程保持存活，录音/overlay 链路完成冒烟接线
- 备注：
  - overlay 的真实视觉位置、底部居中表现、第二按钮可见性仍需在图形环境中人工确认
  - 真实麦克风输入下的波形跟随、权限提示文案与触发时机仍需人工确认
  - `Listening / Thinking` 已接线；`Refining` 状态入口已预留，待后续 task 接入真正 refine 流程

#### Task 6

- 状态：`Complete`
- 目标：建立流式 ASR、语言模型与语言切换接线
- 已完成文件：
  - `Sources/SpeakDockCore/Models/LanguageOption.swift`
  - `Sources/SpeakDockCore/Routing/RecognitionResult.swift`
  - `Sources/SpeakDockMac/Speech/AppleSpeechEngine.swift`
  - `Sources/SpeakDockMac/Speech/SpeechController.swift`
  - `Sources/SpeakDockMac/Audio/AudioCaptureEngine.swift`
  - `Sources/SpeakDockMac/MenuBar/MenuBarRoot.swift`
  - `Sources/SpeakDockMac/Settings/SettingsStore.swift`
  - `Sources/SpeakDockMac/App/SpeakDockApp.swift`
  - `Tests/SpeakDockCoreTests/LanguageOptionTests.swift`
- 已验证行为：
  - 默认语言模型为 `zh-CN`
  - 语言集合覆盖 `en-US / zh-CN / zh-TW / ja-JP / ko-KR`
  - 语言值可安全编码、解码和恢复
  - 菜单栏语言列表改为复用 `LanguageOption`
  - 录音会话开始时会按当前设置语言启动 Apple Speech
  - 音频 buffer 会同步送入识别引擎，partial transcript 会推回 overlay
  - Speech Recognition 权限不可用时会明确显示 `Speech Recognition Unavailable`
- Red / Green 记录：
  - `LanguageOptionTests/testDefaultLanguageIsSimplifiedChinese`：RED -> GREEN
  - `LanguageOptionTests/testSupportedLanguagesMatchArchitecture`：RED -> GREEN
  - `LanguageOptionTests/testLanguageValuesCanBeEncodedAndDecodedSafely`：RED -> GREEN
- 验证结果：
  - `make test TEST_FILTER=LanguageOptionTests` -> pass
  - `make test` -> pass
  - `make build` -> pass
  - `make run` -> app 启动后进程保持存活，Speech 接线后的启动冒烟通过
- 备注：
  - partial transcript 的真实显示、不同语言切换后的识别效果、以及 Speech 权限弹窗路径仍需在图形环境中人工确认
  - 当前只完成识别与 overlay 反馈，不包含最终文本注入；输出落点留给 `Task 7`

#### Task 7

- 状态：`Complete`
- 目标：建立 `Compose / Capture` 输出适配与最终文本落点
- 已完成文件：
  - `Sources/SpeakDockCore/Capture/CaptureFileNamer.swift`
  - `Sources/SpeakDockCore/Routing/RouteDecision.swift`
  - `Sources/SpeakDockMac/Target/InputSourceSwitcher.swift`
  - `Sources/SpeakDockMac/Target/ClipboardComposeTarget.swift`
  - `Sources/SpeakDockMac/Target/CaptureFileTarget.swift`
  - `Sources/SpeakDockMac/App/SpeakDockApp.swift`
  - `Tests/SpeakDockCoreTests/CaptureFileNamerTests.swift`
- 已验证行为：
  - capture 文件名固定为 `speakdock-YYYYMMDD-HHMMSS.md`
  - 文件名总是带品牌前缀和 `.md` 后缀
  - `Compose` 路径使用剪贴板 + `Cmd+V` 注入
  - CJK 输入源场景会临时切到 ASCII，再恢复原输入源
  - `Compose` 只有在可编辑文本目标成立时才会执行
  - `Accessibility` 不可用或目标不安全时，会直接报 `Compose Unavailable`
  - 无可编辑目标时转入 `Capture`
  - `Capture` 首次落盘后会保留活跃文件，后续继续追加到同一文件
  - Apple Speech 最终结果现已真正落到 `Compose / Capture`
- Red / Green 记录：
  - `CaptureFileNamerTests/testFileNameMatchesArchitectureTimestampFormat`：RED -> GREEN
  - `CaptureFileNamerTests/testFileNameAlwaysUsesBrandPrefixAndMarkdownExtension`：RED -> GREEN
- 验证结果：
  - `make test TEST_FILTER=CaptureFileNamerTests` -> pass
  - `make test` -> pass
  - `make build` -> pass
  - `make run` -> app 启动后进程保持存活，输出适配接线后的启动冒烟通过
- 备注：
  - 真正的 `Accessibility` 聚焦判定、聊天框粘贴成功率、中文输入法下注入稳定性仍需图形环境人工确认
  - `Capture` 首次落盘后默认编辑器自动打开、以及后续多轮语音持续追加的真实体验仍需人工确认
  - 当前 `Compose` 判定保持保守实现，后续若遇到具体应用兼容性问题，再按应用类型细化
  - `Capture` 连续追加目前以“同一默认编辑器前台时继续追同一文件”为准，后续若 workspace 接线细化，再回收这一 heuristic

#### Task 8

- 状态：`Complete`
- 目标：建立 `Clean / refine` 接口，并把 `Refining...` 接到热路径
- 已完成文件：
  - `Sources/SpeakDockCore/Refine/RefineEngine.swift`
  - `Sources/SpeakDockCore/Refine/ConservativeRefinePrompt.swift`
  - `Sources/SpeakDockCore/Refine/CleanNormalizer.swift`
  - `Sources/SpeakDockMac/Refine/OpenAICompatibleRefineEngine.swift`
  - `Sources/SpeakDockMac/App/SpeakDockApp.swift`
  - `Tests/SpeakDockCoreTests/ConservativeRefinePromptTests.swift`
- 已验证行为：
  - refine prompt 强调“只修复明显识别错误”
  - refine prompt 明确禁止润色、改写、删减
  - refine 未启用或配置不完整时，热路径直接走 `CleanNormalizer`
  - `CleanNormalizer` 只做确定性清洗，不引入结构性改写
  - refine 已启用且配置完整时，overlay 会先进入 `Refining...`
  - refine 失败时会 fail-open，继续提交 `CleanNormalizer` 结果，不丢文本
- Red / Green 记录：
  - `ConservativeRefinePromptTests/testPromptEmphasizesOnlyFixingObviousRecognitionErrors`：RED -> GREEN
  - `ConservativeRefinePromptTests/testPromptExplicitlyForbidsPolishRewriteAndDeletion`：RED -> GREEN
  - `ConservativeRefinePromptTests/testDisabledRefineFallsBackToCleanOnlyMode`：RED -> GREEN
  - `ConservativeRefinePromptTests/testCleanNormalizerOnlyAppliesDeterministicCleanup`：RED -> GREEN
- 验证结果：
  - `make test TEST_FILTER=ConservativeRefinePromptTests` -> pass
  - `make test` -> pass
  - `make build` -> pass
  - `make run` -> app 启动后进程保持存活，refine 接线后的启动冒烟通过
- 备注：
  - 真实 OpenAI 兼容接口调用、`Refining...` 的端到端停留时长、以及失败兜底体验仍需图形环境和联网环境人工确认
  - 当前只接入“松开后可选 refine”的热路径；整理按钮与撤回仍留给 `Task 9`

### 2026-04-12

#### Task 9

- 状态：`Complete`
- 目标：打通整理按钮、撤回、双击提交
- 已完成文件：
  - `Sources/SpeakDockCore/Workspace/UndoFlowState.swift`
  - `Sources/SpeakDockCore/Workspace/WorkspaceReducer.swift`
  - `Sources/SpeakDockMac/App/HotPathCoordinator.swift`
  - `Sources/SpeakDockMac/App/SpeakDockApp.swift`
  - `Sources/SpeakDockMac/MenuBar/MenuBarRoot.swift`
  - `Sources/SpeakDockMac/Overlay/OverlayPanelController.swift`
  - `Sources/SpeakDockMac/Target/ClipboardComposeTarget.swift`
  - `Sources/SpeakDockMac/Target/CaptureFileTarget.swift`
  - `Tests/SpeakDockCoreTests/UndoFlowTests.swift`
- 已验证行为：
  - overlay 第二按钮与 menu bar 备用入口都由 `UndoFlowState` 驱动
  - 已整理工作区再次触发第二动作时，会优先执行 `撤回整理`
  - 已整理且被手动改脏的工作区，会先进入确认态，再执行撤回
  - 最近一次提交落在 `UndoWindow = 8 秒` 内时，第二动作优先改为撤回最近提交
  - 双击提交会结束当前工作区，避免旧工作区继续吞后续语音
  - `Compose` 路径支持基于已渲染片段的撤回与替换；`Capture` 路径支持仅回滚最新追加尾部
- Red / Green 记录：
  - `UndoFlowTests/testRefinedWorkspaceSecondaryActionBecomesUndoRefine`：RED -> GREEN
  - `UndoFlowTests/testDirtyRefineRequiresConfirmationBeforeUndo`：RED -> GREEN
  - `UndoFlowTests/testRecentSubmissionWithinUndoWindowTakesPriorityOverRefine`：RED -> GREEN
  - `UndoFlowTests/testCaptureRollbackOnlyRemovesMostRecentAppendedTail`：RED -> GREEN
  - `UndoFlowTests/testDoubleSubmitEndsCurrentWorkspace`：RED -> GREEN
- 验证结果：
  - `make test TEST_FILTER=UndoFlowTests` -> pass
  - `make test` -> pass
  - `make build` -> pass
  - `make run` -> app 启动后进程保持存活，热路径冒烟通过
- 备注：
  - “整理后被用户真实编辑”的脏态确认路径，目前仍主要由核心状态机与单测保证，图形环境下的真实 AX 驱动脏态仍需手动确认
  - `Compose` 的替换/撤回、`Capture` 的尾部撤回、以及聊天框里的双击提交，都仍需在真实前台应用里人工确认

#### Task 10

- 状态：`Complete`
- 目标：收尾文档，并把 Settings 动作与人工验收清单对齐
- 已完成文件：
  - `Sources/SpeakDockMac/Settings/RefineConnectionTester.swift`
  - `Sources/SpeakDockMac/Settings/SettingsView.swift`
  - `Tests/SpeakDockMacTests/RefineConnectionTesterTests.swift`
  - `README.md`
  - `docs/README.md`
  - `docs/plans/2026-04-10-speakdock-macos-v1-manual-test.md`
  - `docs/plans/2026-04-11-speakdock-macos-v1-execution-log.md`
- 已验证行为：
  - Settings 现已提供显式 `Choose & Migrate…` 入口，不再依赖直接改路径字符串
  - capture 根目录切换会复用既有迁移逻辑，满足“一键整体迁移”的 UI 落点
  - Settings 现已提供显式 `Test / Save`
  - refine 配置测试会拒绝不完整配置，会裁剪引擎返回文本，并在空返回时回退到样例文本
  - README、文档索引与手动验收清单已同步当前实现和权限矩阵
  - 当前实现事实不需要回写 `ARCHITECTURE.md`
- Red / Green 记录：
  - `RefineConnectionTesterTests/testRejectsIncompleteConfiguration`：RED -> GREEN
  - `RefineConnectionTesterTests/testReturnsTrimmedResponseFromEngine`：RED -> GREEN
  - `RefineConnectionTesterTests/testFallsBackToSampleTextWhenEngineReturnsEmptyContent`：RED -> GREEN
- 验证结果：
  - `make test TEST_FILTER=RefineConnectionTesterTests` -> pass
  - `make test` -> pass
  - `make build` -> pass
  - `make run` -> app bundle 启动成功，并在手动中断前保持存活
- 备注：
  - `Save` 按钮与当前自动持久化并存，目的是满足显式保存入口与人工验收要求
  - `Test` 按钮的真实联网往返、`Choose & Migrate…` 的对话框交互、以及权限弹窗路径，仍需在具备图形环境和网络条件的机器上人工确认

#### Hotfix: `make run` 启动崩溃

- 状态：`Complete`
- 用户反馈：
  - `make run` 构建成功
  - 启动后返回 `Abort trap: 6`
- 诊断证据：
  - 环境：`macOS 15.7.4 (24G517)`
  - 崩溃报告 `SpeakDock-2026-04-12-112019.ips / 112027.ips` 显示 TCC 在权限路径中触发 `SIGABRT`
  - 直接执行 app 内二进制会绕开正常 `.app` 启动语义，权限路径更容易落入 TCC 异常
  - 通过 LaunchServices 启动 `.app` 后，又暴露出 `SpeakDockApp.init()` 过早创建 `OverlayPanelController` 的问题，崩溃栈落在 `OverlayView.swift` / `OverlayPanelController.swift` 的 AppKit 初始化路径
- 修复：
  - `scripts/run-dev.sh` 改为 `open -n -W "$APP_PATH"`，让开发启动路径按 `.app` 方式进入
  - `OverlayPanelController` 改为懒创建 `OverlayPanel / OverlayView`，避免在 `App.init()` 阶段提前触发 AppKit 注册
  - 新增 `OverlayPanelControllerTests`，覆盖 controller 初始化不应提前创建 overlay 的约束
- 验证结果：
  - `make test TEST_FILTER=OverlayPanelControllerTests` -> pass
  - `make test` -> pass，`34` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass
  - `make run` -> app 启动后保持存活，手动 quit 后退出，没有新增 `SpeakDock` 崩溃报告

#### Hotfix: 启动后 `Fn` 没反应

- 状态：`Complete`
- 用户反馈：
  - `make run` 不再崩溃
  - 但启动后按 `Fn` 没有可见反应
- 诊断证据：
  - 进程检查发现之前存在两个 `SpeakDock` 实例，其中一个是验证时遗留的旧实例；已清理到无运行实例
  - `FnKeyTriggerAdapter.start()` 原实现直接调用 `CGEvent.tapCreate`，没有先走 `CGPreflightListenEventAccess / CGRequestListenEventAccess`
  - SDK 中 `CoreGraphics` 提供 `CGPreflightListenEventAccess / CGRequestListenEventAccess`，与当前 `CGEvent tap` 监听路径匹配
  - `Info.plist` 原先没有 `NSInputMonitoringUsageDescription`，无法给默认 `Fn` 全局监听提供明确授权说明
- 修复：
  - `FnKeyTriggerAdapter` 增加 `EventTapPermissionChecking`，启动时先 preflight，不满足时主动 request
  - 权限仍不可用时，menu bar 状态显示 `Fn Unavailable: Input Monitoring Required`
  - `Info.plist` 增加 `NSInputMonitoringUsageDescription`
  - 手动验收清单补充首次 Input Monitoring 授权与重启提示
  - 新增 `FnKeyTriggerAdapterPermissionTests` 和 `PermissionPlistTests`
- 验证结果：
  - `make test TEST_FILTER=FnKeyTriggerAdapterPermissionTests` -> pass
  - `make test TEST_FILTER=PermissionPlistTests` -> pass
  - `make test` -> pass，`36` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass
  - 已确认源码与 `.build/debug/SpeakDock.app/Contents/Info.plist` 均包含 `NSInputMonitoringUsageDescription`
- 备注：
  - 图形环境中实际弹窗、授权后是否需要重启、以及 `Fn` 是否进入 `Listening`，仍需由用户在前台环境复测

## 5. 下一步

- 按 `docs/plans/2026-04-10-speakdock-macos-v1-manual-test.md` 在真实图形环境里逐项验收
- 优先重新运行 `make run`，确认不再出现 `Abort trap: 6`，并处理 Input Monitoring 授权提示
- 然后验证 `Fn / 替代 trigger / overlay 第二按钮 / Compose / Capture / UndoWindow`
- 在具备网络条件的环境里验证 refine `Test` 与真实 `Refining...` 往返
