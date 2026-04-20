# SpeakDock 架构复核

## 1. 用途

这份文档是当前唯一 live 复核。

- 只记录当前复核周期的结论和待确认项
- 被 plan 消化后归档，不在这里堆历史
- 目标是作为下一轮 CURRENT.md 的输入，而不是独立存在

## 2. 复核时间

2026-04-20

## 3. 复核范围

基于完整代码库阅读，对照 `ARCHITECTURE.md` 当前描述，评估实现与架构意图的一致性，以及已知漂移风险。

## 4. 结论

架构意图与实现整体一致。`ActiveWorkspace + SecondaryAction` 主线在代码层面有清晰对应，热路径确定性、可选增强层的失败回退、被动学习阈值这几条核心决策都已落地。

## 5. 待进入下一轮 plan 的项

### 5.1 HotPathCoordinator 复杂度

- 当前状态：`HotPathCoordinator.swift` 是 macOS 端唯一协调器，职责覆盖工作区状态、undo 流、触发事件、语音识别、目标注入、整理请求
- 风险：随功能增加，这里是复杂度最容易聚集的地方
- 建议动作：在下一轮引入新工作区行为之前，先确认 Coordinator 的职责边界是否需要显式写死
- 当前决定：进入当前 plan，先把边界写死为“只做编排，不继续吸收纯规则判断”，这一轮不直接做大拆分

### 5.2 Accessibility API 路径的回归覆盖

- 当前状态：`ClipboardComposeTarget.swift` 依赖 AXUIElement，已有 PITFALLS 文档，但没有自动化回归
- 风险：macOS 系统更新时这条路径最容易静默失效
- 建议动作：评估是否值得为 Accessibility 路径加一个最小探针，纳入 `make probe-compose` 的常规检查
- 当前决定：进入当前 plan，补最小 probe verdict，让 `make probe-compose` 结束时至少给出 `available / no-target / unavailable` 三态结果，而不是只留日志

### 5.3 ASR 真实样本积累

- 当前状态：1110 首句失败已有窄修正，但真实样本量仍早期
- 风险：修正策略基于单一样本，泛化性未知
- 建议动作：在样本量达到可评估阈值之前，保持 ASR Correction 默认关闭，不提前推广
- 当前决定：进入当前 plan，补样本报表和 readiness 判读，但继续保持 `ASR Correction` 默认关闭

## 6. 不需要进入 plan 的观察

- 测试覆盖扎实，34+ 测试文件，smoke 隔离设计合理，当前无需调整
- 文档质量高，ARCHITECTURE / PITFALLS / CURRENT 三份文档职责清晰，当前无需调整
- 无 CI/CD 在当前团队规模下可接受，不建议为此专门立项

## 7. 归档条件

以下条件满足后，本文档归档：

- 5.1 / 5.2 / 5.3 三项已各自明确"进入 plan"或"暂不处理"的决定
- 决定已反映在对应的 `plans/CURRENT.md` 中
