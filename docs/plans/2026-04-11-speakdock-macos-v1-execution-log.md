# SpeakDock macOS v1 执行日志

## 1. 目的

这份文档只记录执行状态、验证结果和实现偏差。

- 架构定义仍以 `docs/technical/ARCHITECTURE.md` 为准
- 任务顺序仍以 `docs/plans/2026-04-10-speakdock-macos-v1-implementation.md` 为准
- 只有当实现事实要求修改真相源时，才回写主文档

## 2. 当前状态

- 当前阶段：P1 `AI 语音输入法` 体验增强
- 当前目标：补齐术语词典入口，并持续回收 UI / README / 验收文档里的实现漂移
- 当前策略：每个行为按 RED / GREEN 小步推进；词典不记录完整转写、聊天内容或剪贴板内容

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
| UI polish | In Progress | 图标资产、Dock 可见性、词典设置入口和更接近原生质感的入口体验持续收敛中 |

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
  - menu bar 图标是否可见、Dock 图标是否按设置正常显示，仍需按手动验收清单在图形环境中确认

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

### 2026-04-15

#### UI polish

- 状态：`In Progress`
- 目标：补齐 app bundle 图标资产链路，让 SpeakDock 在 Dock / Finder 中具备正式应用标识
- 已完成文件：
  - `Artwork/AppIcon.svg`
  - `scripts/generate-app-icon.sh`
  - `scripts/render-app-icon.swift`
  - `scripts/build-app.sh`
  - `Sources/SpeakDockMac/App/AppRuntime.swift`
  - `Sources/SpeakDockMac/App/SpeakDockApp.swift`
  - `Sources/SpeakDockMac/Resources/Info.plist`
  - `Tests/SpeakDockMacTests/BuildScriptTests.swift`
  - `Tests/SpeakDockMacTests/PermissionPlistTests.swift`
- 已完成内容：
  - 新增单一源稿 `Artwork/AppIcon.svg`，风格与现有 `SpeakDockBrandGlyph` 对齐
  - 构建时自动通过本地 Swift 渲染器生成 `.iconset` 与 `.icns`
  - app bundle 现在会复制 `SpeakDock.icns` 到 `Contents/Resources`
  - `Info.plist` 增加 `CFBundleIconFile = SpeakDock`
  - 应用启动可见性不再被 `LSUIElement` 固定锁死，Dock fallback 由运行时策略控制
  - 增加 plist 测试，防止图标绑定在后续回归中丢失
- 验证结果：
  - `make test` -> pass，`66` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass，`.build/debug/SpeakDock.app/Contents/Resources/SpeakDock.icns` 已生成
  - `zsh ./scripts/generate-app-icon.sh` -> 在非沙箱 macOS 会话中验证通过
- 待人工确认：
  - `make run` 后 Dock 图标是否按 `Show Dock Icon` 设置正常显示
  - Finder 中 `.app` 是否显示新图标
  - menu bar 拥挤时，Dock fallback 是否足以保证用户能找到应用入口

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

- 状态：`Superseded by Accessibility hotfix`
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

#### Hotfix: `Fn` 权限路径改为 Accessibility

- 状态：`Complete`
- 用户反馈：
  - 系统设置的 Input Monitoring 里没有 `SpeakDock`
  - 参考同类产品后，默认全局按键路径更符合 Accessibility 授权模型
- 诊断证据：
  - 本机 SDK 的 `AXIsProcessTrustedWithOptions` 是正式的辅助功能授权提示入口
  - `NSEvent` SDK 头文件说明全局 key 事件监听通常依赖 Accessibility trust
  - macOS SDK 中未发现 `NSAccessibilityUsageDescription` plist key，因此 Accessibility 授权不需要额外 Info.plist usage description key
- 修复：
  - `FnKeyTriggerAdapter` 改为启动时先检查 `AXIsProcessTrustedWithOptions(prompt: false)`，不满足时再以 `prompt: true` 触发系统 Accessibility 授权提示
  - 权限仍不可用时，menu bar 状态显示 `Fn Unavailable: Accessibility Required`
  - event tap 创建失败时，menu bar 状态显示 `Fn Unavailable: Event Tap Unavailable`
  - 移除当前实现对 `NSInputMonitoringUsageDescription` 的依赖，避免误导用户去 Input Monitoring 列表寻找应用
  - README 与人工验收清单改为当前实现优先看 Accessibility；Input Monitoring 只保留为未来替代监听方案的条件性权限
- 验证结果：
  - `make test TEST_FILTER=FnKeyTriggerAdapterPermissionTests` -> pass
  - `make test` -> pass，`36` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass
  - 已确认 `.build/debug/SpeakDock.app/Contents/Info.plist` 不包含 `NSInputMonitoringUsageDescription`，避免误导到 Input Monitoring 权限面板
- 备注：
  - 仍需由用户在真实前台环境里确认 Accessibility 弹窗、授权后重启、以及 `Fn` 是否进入 `Listening`

### 2026-04-13

#### Hotfix: 延迟 trigger 启动到 AppKit 完成启动后

- 状态：`Complete`
- 用户反馈：
  - Accessibility 中已经给过 `SpeakDock` 授权
  - 关闭后重新 `make run` 仍然重复弹授权提示
  - 按 `Fn` 仍无反应
- 诊断证据：
  - `TriggerController` 原先在 `SpeakDockApp.init()` 阶段立即 `reloadConfiguration()`
  - 这会让 `FnKeyTriggerAdapter.start()` 在 AppKit / LaunchServices 完成应用注册前触发 Accessibility / TCC 检查
  - 系统日志显示启动早期连续出现 `TCCAccessRequest()`，与过早权限检查相符
- 修复：
  - `TriggerController` 初始化时不再启动 adapter，初始状态为 `Trigger Not Started`
  - 新增 `TriggerController.start()`，只在首次调用时安装 adapter
  - `AppRuntime.applicationDidFinishLaunching` 增加启动回调
  - `SpeakDockApp.init()` 将 `triggerController.start()` 绑定到 AppKit 完成启动后的回调
  - 设置变更只在 trigger controller 已启动后才触发 reload
  - 新增 `TriggerControllerLifecycleTests` 覆盖“初始化不启动”和“启动后设置变更会 reload”
- 验证结果：
  - `make test TEST_FILTER=TriggerControllerLifecycleTests` -> pass
  - `make test` -> pass，`38` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass
- 备注：
  - 仍需用户在真实前台环境重新运行 `make run`，确认 Accessibility 不再重复弹、menu bar 显示 `Fn Ready`，以及按 `Fn` 能进入 `Listening`

#### Debug Note: menu bar app 可见性

- 状态：`Diagnosed`
- 用户反馈：
  - `SpeakDock` 看起来像完全后台程序，找不到前台入口
  - 需要确认当前 macOS App 调试方式是否正确
- 诊断证据：
  - `Info.plist` 设置了 `LSUIElement = 1`，设计上不会显示 Dock 图标或普通前台窗口
  - `AppRuntime.applicationDidFinishLaunching` 调用 `NSApp.setActivationPolicy(.accessory)`，与 menu bar 工具形态一致
  - `SpeakDockApp` 通过 `MenuBarExtra("SpeakDock", systemImage: "mic.circle.fill")` 创建右上角状态栏入口；菜单栏默认入口是麦克风圆形图标，不是左上角应用菜单或 Dock 图标
  - `scripts/run-dev.sh` 通过 `open -n -W .build/debug/SpeakDock.app` 启动 app bundle，当前调试方式比直接执行二进制更符合 LaunchServices / TCC 权限模型
  - 进程查询确认 `make run` 的 `open -n -W` 仍在等待，且 `SpeakDock` App 本体进程已运行
- 结论：
  - 当前 `make run` 调试方式正确
  - “无 Dock / 无普通前台窗口”是预期行为
  - 若右上角也看不到麦克风圆形图标，下一步应排查 menu bar extra 是否被菜单栏空间或第三方菜单栏管理工具隐藏，而不是先改启动方式

#### Hotfix: 稳定开发构建的 Accessibility 授权身份

- 状态：`Complete`
- 用户反馈：
  - menu bar 已能打开，但状态显示 `Fn Unavailable: Accessibility Required`
  - 系统设置 `Privacy & Security -> Accessibility` 中 `SpeakDock` 已打开
- 诊断证据：
  - `codesign -dr - .build/debug/SpeakDock.app` 原先输出 `designated => cdhash ...`
  - 这说明开发 bundle 的 ad-hoc 签名身份绑定到每次构建产物 hash，rebuild 后 TCC 里看似打开的 Accessibility 授权可能不再匹配当前进程
  - 本机没有可用的稳定 code signing identity：`security find-identity -v -p codesigning` 返回 `0 valid identities found`
  - 在临时 app bundle 上验证 `codesign --sign - --requirements '=designated => identifier "com.leozejia.speakdock"'` 可把 ad-hoc designated requirement 固定到 bundle identifier
- 修复：
  - `scripts/build-app.sh` 的 ad-hoc 签名改为从 `Info.plist` 读取 `CFBundleIdentifier`
  - 签名时显式写入 `=designated => identifier "$BUNDLE_IDENTIFIER"`
  - 新增 `BuildScriptTests` 覆盖构建脚本必须保留稳定 designated requirement
- 验证结果：
  - `make test TEST_FILTER=BuildScriptTests` -> 先按预期失败，再修复后通过
  - `make build` -> pass
  - `codesign -dr - .build/debug/SpeakDock.app` -> `designated => identifier "com.leozejia.speakdock"`
  - `make test TEST_FILTER=FnKeyTriggerAdapterPermissionTests` -> pass
  - `make test` -> pass，`39` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
- 备注：
  - 旧的 Accessibility 授权记录可能仍绑定旧 `cdhash`，需要用户在系统设置里删除旧 `SpeakDock` 授权项后重新添加一次新的 `.build/debug/SpeakDock.app`
  - 重新授权后，后续 rebuild 应不再因为 `cdhash` 变化导致授权漂移

#### Hotfix: 修复音频 tap 回调触发 MainActor 断言崩溃

- 状态：`Complete`
- 用户反馈：
  - 新构建启动后申请了麦克风与 Speech Recognition 权限
  - 授权后 App 闪退，重新 `make run` 继续闪退
- 诊断证据：
  - `~/Library/Logs/DiagnosticReports/SpeakDock-2026-04-13-095052.ips` 中崩溃类型为 `EXC_BREAKPOINT / SIGTRAP`
  - faulting thread 为 `RealtimeMessenger.mServiceQueue`
  - 崩溃栈指向 `AudioCaptureEngine.swift` 的 `installTap` 回调：`closure #1 in AudioCaptureEngine.startCaptureIfNeeded()`
  - 统一日志明确输出：`BUG IN CLIENT OF LIBDISPATCH: Assertion failed: Block was expected to execute on queue [com.apple.main-thread]`
  - 根因是 audio tap 回调运行在 CoreAudio 实时音频队列，但原闭包捕获 `@MainActor` 的 `AudioCaptureEngine self` 并访问其隔离成员，Swift 6 运行时触发 executor 断言
- 修复：
  - 新增非 MainActor 的 `AudioCaptureTapProcessor`，负责在 audio tap 队列处理 buffer、计算 RMS、驱动 `LevelSmoother`
  - `AudioCaptureEngine` 的 `installTap` 闭包不再捕获 `self`
  - `onLevelChanged` 与 `onAvailabilityChanged` 显式标注为 `@MainActor` 回调
  - level/UI 更新通过 `Task { @MainActor in ... }` 回到主执行器
  - 新增 `AudioCaptureTapProcessorTests` 覆盖 tap 处理器可以从非主线程执行，并把 level 更新交回 main actor
- 验证结果：
  - `make test TEST_FILTER=AudioCaptureTapProcessorTests` -> 先按预期失败，再修复后通过
  - `make test` -> pass，`40` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass
- 备注：
  - 仍需用户在真实图形环境按住 `Fn` 复测录音链路，确认不会再产生新的 `SpeakDock-*.ips` 崩溃报告

#### Feature: 轻量长期调试日志

- 状态：`Complete`
- 用户反馈：
  - 当前不应只依赖临时 `log show` 排障，需要长期调试日志能力
  - 方案必须轻量，不能引入重型日志系统
- 设计决策：
  - 采用 Apple Unified Logging / `OSLog.Logger`
  - subsystem 固定为 `com.leozejia.speakdock`
  - category 固定为 `lifecycle / permission / trigger / audio / speech / compose / capture / refine`
  - 不引入第三方依赖，不写本地日志文件，不做远程 telemetry
  - 不记录音频内容、转写正文、剪贴板内容、API Key、完整 refine 请求正文
  - CoreAudio realtime tap 回调内不直接写日志，只在录音启动、停止、失败等边界记录
- 实现：
  - 新增 `Sources/SpeakDockMac/Logging/SpeakDockLog.swift`
  - 新增 `scripts/show-logs.sh`
  - 新增 `make logs LOG_WINDOW=...`
  - 在 lifecycle / permission / trigger / audio / speech / compose / capture / refine 关键边界接入结构化日志
  - README 与架构文档补充日志入口和约束
- 验证结果：
  - `make test TEST_FILTER=SpeakDockLogTests` -> 先按预期失败，再修复后通过
  - `make test TEST_FILTER=BuildScriptTests` -> 先按预期失败，再修复后通过
  - `make test` -> pass，`42` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass
  - `make logs LOG_WINDOW=2m` -> pass，能看到 `lifecycle` 与 `trigger` 分类日志，状态包含 `Fn Ready`

#### Hotfix: 修复 tap block 继承 MainActor 隔离导致按 Fn 立即崩溃

- 状态：`Complete`
- 用户反馈：
  - `Fn` 已能触发，但按下后 App 会立刻闪退
- 诊断证据：
  - `~/Library/Logs/DiagnosticReports/SpeakDock-2026-04-13-144845.ips` 中崩溃类型为 `EXC_BREAKPOINT / SIGTRAP`
  - faulting thread 为 `RealtimeMessenger.mServiceQueue`
  - 崩溃栈指向 `AudioCaptureEngine.startCaptureIfNeeded()` 中的 audio tap closure
  - `make logs LOG_WINDOW=10m` 显示触发顺序为 `press started` -> `speech recognition start requested` -> `audio capture start requested` -> `speech recognition started` -> `audio capture started`，随后崩溃
  - 根因是 `AudioCaptureEngine` 整体标注为 `@MainActor`，在 `startCaptureIfNeeded()` 内直接创建的 `installTap` closure 继承了 MainActor 隔离；CoreAudio 在实时音频队列调用该 closure 时触发 Swift executor 检查并 trap
- 修复：
  - 新增非 MainActor 隔离的 `makeAudioCaptureTapBlock(...)`
  - 新增 `AudioCaptureTapBlockHandler` 持有 `AudioCaptureTapProcessor`，由 tap block 在实时队列调用
  - `AudioCaptureEngine.startCaptureIfNeeded()` 不再内联创建 tap closure，改为使用非隔离 factory 返回的 block
  - 保持 CoreAudio tap 回调内不写日志、不触碰 UI；level 更新仍通过 `Task { @MainActor in ... }` 回主执行器
- 验证结果：
  - `make test TEST_FILTER=AudioCaptureTapProcessorTests/testAudioTapBlockCreatedOnMainActorCanRunOffMainThread` -> 先按预期失败，再修复后通过
  - `make test TEST_FILTER=AudioCaptureTapProcessorTests` -> pass
  - `make test` -> pass，`44` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass
- 备注：
  - `SpeechController.makeAudioBufferAppender()` 的相邻闭包风险已单测覆盖，后台队列调用未触发同类 trap
  - 仍需用户在真实图形环境重新按 `Fn` 复测，确认不会再生成新的 `SpeakDock-*.ips`

#### Hotfix: 修复 Compose 目标未冻结导致误入 Capture/Xcode

- 状态：`Complete`
- 用户反馈：
  - 第一次按下 `Fn` 并松开后，会进入 Xcode 编译界面，不能直接发到输入光标处
- 诊断证据：
  - `make logs LOG_WINDOW=20m` 显示完整链路已经进入 `press started` -> `audio capture started` -> `press ended` -> `speech recognition final result received`
  - 随后日志显示 `capture commit succeeded`，没有进入 `compose commit succeeded`
  - `CaptureFileTarget.write(...)` 首次写入会调用 `NSWorkspace.open(fileURL)`，如果系统默认 `.md` 打开方式是 Xcode，就会表现为跳到 Xcode
  - 根因是 `HotPathCoordinator.commitRecognizedText(...)` 在 ASR final result 到来时才判定 `composeTarget.availability()`，没有在 `Fn` 按下时冻结原始可编辑目标；并且已有 Capture session 会在 Compose 判定前通过 `shouldContinueCapture(...)` 抢先接管
- 修复：
  - 新增 `ComposeTargetSession`，在按下 `Fn` 时记录当时的 Compose target
  - `HotPathCoordinator` 在提交时优先使用本次按下时捕获的 Compose target
  - 如果本次录音捕获到 Compose target，则不会被已有 Capture continuation 抢先接管
  - `ClipboardComposeTarget` 在按下时缓存 AX element；提交时若焦点漂移，会先尝试恢复到该 element，再校验 expected target 后注入
  - 注入时增加 expected target 校验，避免焦点漂移后误粘贴到其他窗口
  - 如果 captured Compose target 不可恢复，显示 `Compose Unavailable`，不会静默落到 Capture 打开 Xcode
- 验证结果：
  - `make test TEST_FILTER=ComposeTargetSessionTests` -> 先按预期失败，再修复后通过
  - `make test` -> pass，`47` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass

#### Hotfix: 修复 VS Code 下 system-wide AXFocusedUIElement 无值导致 Compose 失效

- 状态：`Complete`
- 用户反馈：
  - 增加 Compose target 诊断后，VS Code 里仍然会跳到 Xcode
- 诊断证据：
  - `make logs LOG_WINDOW=5m` 显示按下 `Fn` 时前台为 `com.microsoft.VSCode`
  - `AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute, ...)` 返回 `error=-25212`
  - `-25212` 对应 `kAXErrorNoValue`，表示 system-wide accessibility object 没有 focused UI element 值
  - 这不是权限失败，也不是 Capture 写入失败，而是 Compose target resolver 只查 system-wide focused element，不足以覆盖 VS Code / Electron 类 app
- 修复：
  - 新增 `ComposeTargetFallbackPolicy`
  - system-wide `AXFocusedUIElement` 返回 `.noValue` 或 `.attributeUnsupported` 时，转向 frontmost application fallback
  - fallback 先查 frontmost app 的 `AXFocusedUIElement`
  - 如果仍无值，再从 frontmost app 的 `AXFocusedWindow` 子树中递归查找可编辑元素
  - `selectedTextRange` 可写也被纳入可编辑文本元素判定
  - 查找范围限制为深度 8、最多 250 个元素，避免在复杂 app 的 AX tree 中无界遍历
- 验证结果：
  - `make test TEST_FILTER=ComposeTargetFallbackPolicyTests` -> 先按预期失败，再修复后通过
  - `make test TEST_FILTER=ComposeTarget` -> pass
  - `make test` -> pass，`49` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass

#### Hotfix: 扩展微信类 App 的 Compose fallback 与兼容性 probe

- 状态：`Complete`
- 用户反馈：
  - VS Code 已经可以正常 Compose，但微信聊天窗口仍然失败
  - 单个 App 逐个真实录音测试效率过低，需要更大面积覆盖方式
- 诊断证据：
  - VS Code 段日志已经出现 `compose target capture using frontmost application fallback`、`compose target capture succeeded`、`compose commit succeeded`
  - 微信段日志显示 `frontmost=com.tencent.xinWeChat`
  - 同样出现 system-wide `AXFocusedUIElement` 的 `error=-25212`
  - 但没有出现 `using frontmost application fallback`，说明 frontmost fallback 没有找到可编辑元素，最终落到 `capture commit succeeded`
- 修复：
  - frontmost fallback 不再只查 frontmost app 的 `AXFocusedUIElement` 与 `AXFocusedWindow`
  - 如果 app focused element 不是可编辑目标，会继续在该元素子树内查找可编辑后代
  - fallback 扩展为依次扫描 `focusedWindow`、`mainWindow`、`AXWindows`、app `AXChildren`
  - 递归子树除 `AXChildren` 外，额外尝试 `AXContents` 与 `AXVisibleChildren`
  - 访问上限调整为深度 8、最多 500 个元素，避免复杂第三方 App 无界遍历
  - 失败日志补充 app focused / focused window / main window / windows / children 的 AX 错误码与数量，仍不记录标题、文本、剪贴板、转写内容
  - 新增 `make probe-compose PROBE_SECONDS=30`，以 `SpeakDock.app` 自身身份启动 probe mode，定时检查当前前台 App 的 Compose target，不录音、不注入、不改剪贴板
- 验证结果：
  - `make test TEST_FILTER=SpeakDockLaunchOptionsTests` -> pass
  - `make test TEST_FILTER=BuildScriptTests` -> pass
  - `make test TEST_FILTER=ComposeTarget` -> pass
  - `make test` -> pass，`53` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass

#### Hotfix: 为微信启用受限 paste-only Compose fallback

- 状态：`Complete`
- 用户反馈：
  - probe 能覆盖多个 App，但微信仍然返回 `availability=noTarget`
- 诊断证据：
  - VS Code、Discord、Notes、Chrome、Lark、Mail 在真实输入框时可返回 `availability=available`
  - 微信段日志稳定显示 `frontmost=com.tencent.xinWeChat`
  - 微信 `focusedWindowError=0`、`mainWindowError=0`、`childrenError=0`，说明不是权限失败，也不是完全无法读取 AX tree
  - 微信可遍历约 `396` 到 `408` 个 AX 节点，但没有任何节点满足 `AXEditable`、`AXTextField / AXTextArea` 或可写 `selectedTextRange`
  - 因此继续盲目扩大通用递归范围不是正确修复方向
- 修复：
  - 新增显式 bundle allow-list：`com.tencent.xinWeChat`
  - 仅当普通 system-wide 与 frontmost AX fallback 都无法拿到可编辑元素时，微信才进入 paste-only fallback
  - paste-only target 绑定当前前台进程 ID 与 bundle ID
  - 提交、撤回、整理替换前都会校验当前前台仍是同一微信进程；如果焦点已经切走，直接报 `Compose Unavailable`，不跨 App 误贴
  - 该 fallback 仍只使用剪贴板 + `Cmd+V`，不记录文本、剪贴板内容或聊天内容
- 验证结果：
  - `make test TEST_FILTER=ComposeTargetFallbackPolicyTests` -> pass
  - `make test` -> pass，`55` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass
  - 微信真实 probe -> pass，日志显示 `compose target capture using paste-only frontmost application fallback` 与 `availability=available`
  - 微信真实 `Fn` 注入 -> pass，第二次录音日志显示 `using compose target captured at press start` 与 `compose commit succeeded`
  - 第一次录音未提交是 `speech recognition task reported error`，不是 Compose target fallback 失败；如果后续复现，需要转入 ASR warm-up / error-code 诊断

#### Hotfix: 增强 Apple Speech 错误观测

- 状态：`Complete`
- 用户反馈：
  - 微信真实 `Fn` 测试中，第一次录音未提交，日志只有 `speech recognition task reported error`
- 诊断判断：
  - 该次失败发生在 Speech Recognition 阶段，Compose target 已在按下时捕获成功
  - 旧日志缺少 `NSError.domain` 和 `NSError.code`，无法区分 Apple Speech 系统错误、权限错误、会话错误、短音频或 warm-up 类问题
- 修复：
  - 新增 `SpeechRecognitionErrorDiagnostics`
  - Apple Speech 任务错误日志现在记录脱敏的 `domain/code`
  - 不记录转写正文、音频内容、剪贴板内容或用户聊天内容
- 验证结果：
  - `SpeechRecognitionErrorDiagnosticsTests/testExtractsNSErrorDomainAndCode` -> RED 后 GREEN
  - `make test TEST_FILTER=SpeechRecognitionErrorDiagnosticsTests` -> pass
  - `make test TEST_FILTER=ComposeTargetFallbackPolicyTests` -> pass
  - `make test` -> pass，`56` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass

## 5. 下一步

### 5.1 主线调整：AI 语音输入法优先

- 状态：`Planned`
- 背景：
  - 公开 README 已从“本地语音工作流”调整为“AI 语音输入法 + 本地记忆 + LLM Wiki”
  - 新增 `docs/research/2026-04-14-typeless-shandianshuo-research.md`，对比 Typeless / 闪电说后确认下一阶段不应直接跳 Wiki 或硬件
- 结论：
  - P1 先把“AI 语音输入法”体验做稳
  - 不在 P1 引入常驻端侧小模型
  - 不在 P1 做完整 Wiki compiler
  - 不在 P1 做 DJI 或其他硬件 adapter
- P1 范围：
  - 更新架构文档，补齐 `TermDictionary / StyleProfile / VoiceCommandIntent / Skill` 的边界
  - 第一版只实现 `TermDictionary`
  - `TermDictionary` 支持用户手动填写
  - 用户手动改正 SpeakDock 输出后，只生成候选词条，不静默写入词典
  - 词典配置不进入 Git，默认保存在用户本地配置目录
  - 词典先用于 `Clean`、ASR 后处理和 `RefineRequest` 上下文
  - `StyleProfile / VoiceCommandIntent / Skill / WikiCompiler / DJI` 后置
- 模型策略：
  - 当前继续使用 Apple Speech 作为 ASR
  - 当前继续保留 OpenAI-compatible refine 作为验证通道
  - 端侧小模型选型后置到 P2/P3
  - 端侧模型研究必须基于真实 ASR 失败样本、术语词典误伤样本、refine 延迟与质量样本、内存和热量测量
- 风险边界：
  - 词典不能自动污染
  - 词典不能记录完整转写正文、聊天内容、剪贴板内容
  - 用户手动修正不等于词条事实
  - 模型失败不能阻断热路径
  - Wiki 仍然是冷路径

### 5.2 验收与实现顺序

1. 按 `docs/plans/2026-04-10-speakdock-macos-v1-manual-test.md` 在真实图形环境里逐项验收
2. 优先重新运行 `make run`，确认 Accessibility 不再重复弹；如果仍弹，移除旧授权项后重新添加 `.build/debug/SpeakDock.app`
3. 验证 `Fn / 替代 trigger / overlay 第二按钮 / Compose / Capture / UndoWindow`
4. 在具备网络条件的环境里验证 refine `Test` 与真实 `Refining...` 往返
5. P1 `TermDictionary` 已开始实现，先接入已确认别名的 Clean 确定性替换

### 5.3 P1 TermDictionary 实现记录

- 状态：`In Progress`
- 已完成行为：
  - 已确认的 `TermDictionary` 别名可注入 `CleanNormalizer`
  - Clean 输出前会把命中的别名替换成用户确认过的标准术语
  - 默认 `CleanNormalizer()` 继续使用空词典，不改变现有热路径默认行为
  - 用户手动修正前后文本可在 Core 层生成本地候选词条
  - 当前候选提取只输出差异片段，不自动写入 confirmed dictionary
  - 当前候选提取对候选长度与换行做保护，避免把整段文本当词条落盘
  - `TermDictionaryStore` 已可把 confirmed entries 和 pending candidates 保存到用户本地 `Application Support/SpeakDock/term-dictionary.json`
  - 存储层支持注入临时路径测试，不触碰仓库内文件，也不进入 Git 管理
  - app 启动时已把本地 confirmed dictionary 接入 `Clean` 热路径，后续识别不需要重启 normalizer 也能读到最新词典
  - 待确认候选现在可以被提升进 confirmed dictionary，并从 pending 列表移除
  - Settings 已接入本地 `TermDictionaryStore`
  - 用户现在可以在 Settings 手动添加、删除 confirmed terms
  - pending candidates 现在可以在 Settings 中显式 `Confirm / Dismiss`
  - README 与手动验收文档已修正为当前真实行为：Dock 默认可见，热路径是 `ASR + Clean + optional Refine`
- 未完成范围：
  - 将用户手动修正事件接入候选词条生成流程
  - 候选撤回、删除和导出
  - 将词典条目传入 `RefineRequest` 上下文
- Red / Green 记录：
  - `TermDictionaryTests/testConfirmedAliasesAreAppliedBeforeFinalCleanTextIsSubmitted`：RED -> GREEN
  - `TermDictionaryTests/testManualCorrectionCreatesCandidateWithoutMutatingConfirmedDictionary`：RED -> GREEN
  - `TermDictionaryTests/testNormalizerCanReadCurrentDictionaryFromProviderWithoutRecreation`：RED -> GREEN
  - `TermDictionaryStoreTests/testPersistsAndReloadsConfirmedEntriesAndPendingCandidates`：RED -> GREEN
  - `TermDictionaryStoreTests/testConfirmCandidatePromotesItIntoConfirmedDictionaryAndRemovesPendingEntry`：RED -> GREEN
  - `TermDictionaryStoreTests/testAddEntryMergesAliasesIntoExistingEntry`：RED -> GREEN
  - `TermDictionaryStoreTests/testRemoveEntryAndDismissCandidatePersist`：RED -> GREEN
  - `TermDictionaryStoreTests/testAddEntryRejectsEmptyCanonicalOrAliasList`：RED -> GREEN
- 验证结果：
  - `make test TEST_FILTER=TermDictionaryTests` -> pass
  - `make test TEST_FILTER=ConservativeRefinePromptTests` -> pass
  - `make test TEST_FILTER=TermDictionaryStoreTests` -> pass
  - `make test` -> pass，`69` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
  - `make build` -> pass

### 5.4 菜单栏与设置界面视觉基线重构

- 状态：`Complete`
- 目标：
  - 把菜单栏面板、设置页、overlay 和菜单栏图标从工程占位态提升到可长期迭代的 macOS 基线
- 已完成行为：
  - 菜单栏图标从系统默认 `mic.circle.fill` 改为品牌化单色 waveform glyph
  - 菜单栏面板改为状态优先的紧凑控制面板，不再是原始表单堆叠
  - 设置页改为分组卡片和清晰层级，触发键替代项不再要求用户手输内部标识字符串
  - overlay 调整为更接近原生 utility HUD 的层级、按钮和状态色
- 未完成范围：
  - 视觉层人工验收与细节微调
- 验证结果：
  - `make test` -> pass，`61` 个 XCTest + `2` 个 Swift Testing smoke 全部通过

### 5.5 入口与浮层可感知性修正

- 状态：`Complete`
- 目标：
  - 当菜单栏被挤掉时，仍然给用户可靠入口
  - 缩小 `Thinking` 浮层并为卡住状态提供超时退出
- 已完成行为：
  - `AppSettings` 新增 `showDockIcon`，默认开启，并兼容旧配置解码
  - Settings 新增 `Show Dock Icon` 开关
  - app 启动与设置变更都会同步 `Dock` 可见性
  - `SettingsStore` 改为支持多观察者，避免后续运行时接线互相覆盖
  - overlay 缩小宽高与文案，禁用时隐藏右侧按钮
  - 识别结束后若长时间拿不到最终结果，会显示 `Speech Timed Out`
- 验证结果：
  - `make test TEST_FILTER=SettingsStoreTests` -> pass
  - `make test` -> pass，`63` 个 XCTest + `2` 个 Swift Testing smoke 全部通过
