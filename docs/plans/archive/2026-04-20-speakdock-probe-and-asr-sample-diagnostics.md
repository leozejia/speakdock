# SpeakDock 阶段归档

## 1. 阶段主题

- 阶段：P1 `AI 语音输入法`
- focus：锁 `HotPathCoordinator` 边界，并补齐 `AX probe / ASR 样本观测` 的最小回归面
- 状态：`Completed`

## 2. 为什么当时做

上一轮已经把 `ActiveWorkspace + SecondaryAction` 主线重新锁回来了，但实现侧还有三个更现实的风险没有收口：

- `HotPathCoordinator.swift` 继续膨胀的概率很高
- `ClipboardComposeTarget.swift` 这条 `Accessibility` 路径还缺最小自动回归
- `ASR Correction` 已经能开，但真实样本还不足以支持默认推广

这轮不是追新功能，而是先把复杂度边界和诊断入口补稳。

## 3. 本轮实际完成

- `HotPathCoordinator` 已明确写死为“只做编排，不继续吸收纯规则”
- `make probe-compose` 现在结束会给出最小 `AX` 结论：`available / no-target / unavailable`
- `make asr-sample-report` 已落地，能把 `speech-error-report` 与 `asr-correction-report` 串成一次判读
- `speech-error-report` 现在会直接列出最近失败样本，方便本地排查

## 4. 这轮锁住的边界

- 不在这一轮直接大拆 `HotPathCoordinator`
- 不把 `ASR Correction` 改成默认开启
- 不新增新的工作区模式、触发模式或整理入口
- 不为了 `probe / report` 补重型基础设施

## 5. 验证结果

- `make test` -> pass
- `git diff --check` -> clean
- `probe-compose` 新增最小 verdict 测试
- `asr-sample-report` 与最近失败样本报表已有脚本测试

## 6. 结束判断

这一轮已经满足完成定义：

- `Coordinator` 边界已明确
- `AX` 路径不再只靠人工读日志
- `ASR` 真实样本开始有稳定的本地观测面
- `CURRENT / review / ARCHITECTURE` 三处口径一致

## 7. 下一轮建议

下一轮优先补“文档已要求、实现仍缺失”的窄缺口，而不是重新开新模式。

当前最直接的缺口是：

- `TermDictionary` 已支持添加、删除、忽略
- 但架构要求的“可导出”还没闭环
