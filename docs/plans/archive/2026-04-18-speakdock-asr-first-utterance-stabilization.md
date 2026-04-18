# SpeakDock 阶段归档

## 1. 阶段主题

- 阶段：P1 `AI 语音输入法`
- focus：用真实失败样本收稳 `ASR` 首句失败，先只做 `finish -> 1110` 的窄修正
- 状态：`Completed`

## 2. 为什么当时做

在这轮之前，`Compose / Capture / Refine / Undo` 的工作区热路径已经基本可用，但还有一个强感知问题没有收口：

- 用户真实遇到“第一次说话没出字”
- 这不是抽象风险，而是已经拿到了真实失败样本
- 如果直接上重型 warm-up、自动重录或多次重试，很容易把简单热路径搞复杂

所以这轮的目标不是“大修 ASR”，而是先把真实已知失败点锁住。

## 3. 本轮实际完成

- 新增 `make speech-logs`，可以只看 `speech` category 的原始日志
- 新增 `make speech-error-report`，可以本地聚合最近 `speech` 会话的 `language / outcome / error`
- 基于真实样本 `zh-CN + kAFAssistantErrorDomain#1110`，补了 `finish requested` 之后的 partial transcript final fallback
- `AppleSpeechEngine` 显式声明 `request.taskHint = .dictation`
- 相关行为已经有回归测试，不再只靠人工感觉判断

## 4. 这轮锁住的边界

- 这是一条窄修正，不是完整 warm-up 方案
- 只在 `finish requested + wantsRecognition=false` 的收尾边界考虑 fallback
- 只复用当前会话已经拿到的 non-empty partial transcript
- 不引入新模型、不加后台预热录音、不做激进自动重试

## 5. 验证结果

- `make test TEST_FILTER=SpeechRecognitionFallbackPolicyTests` -> pass
- `make test TEST_FILTER=SpeechControllerTests` -> pass
- `make test TEST_FILTER=SpeechRecognitionErrorDiagnosticsTests` -> pass
- `make test` -> pass
- 真实日志样本已确认 `speech-logs / speech-error-report` 可用

## 6. 结束判断

这条 ASR 收敛线当前已经满足阶段完成定义：

- 已有稳定的本地诊断入口
- 已知真实失败样本已有最小修正
- 修正边界明确，没有顺手把热路径做重
- 行为被测试覆盖，不再依赖临时人工排查

## 7. 下一轮建议

下一轮不应该继续围着单个 `ASR` 错误码打转，而应该把主线拉回 SpeakDock 的底层模型：

- `ActiveWorkspace`
- `SecondaryAction`

也就是继续围绕当前工作区，而不是把产品误收敛成“选中一段文字直接改”。
