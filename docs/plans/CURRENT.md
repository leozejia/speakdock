# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：补齐 `TermDictionary` 的导出闭环，让“可撤回 / 可删除 / 可导出”这条定义在实现上完整成立
- 状态：`Completed`

## 3. 为什么现在做

当前热路径、诊断入口和词级学习链路已经基本稳定，但还有一个更直接的文档缺口没有补齐：

- 架构已经明确写了 `TermDictionary` 条目必须“可撤回、可删除、可导出”
- 现在实现里已经有添加、删除、忽略和本地学习
- 但还没有导出入口，定义和实现之间存在真实落差

这类问题比“再加一个新能力”更值得先做，因为：

- 方向没有歧义，架构已经给出结论
- 用户本地积累的词典和被动学习结果确实需要迁移与备份出口
- 这是低复杂度、高确定性的收口，不会把主线再带偏

所以这一轮不追新入口，只补一个窄而真实的闭环：本地词典导出。

## 4. 本轮范围

1. 归档上一轮已完成的 `probe / ASR` 诊断 focus
2. 把新一轮 `CURRENT / review` 收敛到 `TermDictionary export` 这个唯一缺口
3. 给 `TermDictionaryStore` 补导出能力，并加回归测试
4. 在 `Settings -> Dictionary` 接入显式导出入口
5. 同步人工验收文档，让“可导出”进入验证口径

## 5. 明确不做

- 不做词典导入、云同步、多端同步
- 不把词典扩成知识库或 `StyleProfile`
- 不为了导出补新的后台服务或数据库层
- 不重新改写当前词级学习规则

## 6. 执行顺序

1. 先归档上一轮 CURRENT，并写新的 live plan
2. 先补 `TermDictionaryStore` 导出测试，再补实现
3. 再把导出入口接到 `Settings -> Dictionary`
4. 最后补人工验收文档并统一回归

## 7. 完成定义

满足以下条件才算完成：

- `CURRENT / review / manual test` 对“词典可导出”口径一致
- 本地词典可以通过显式入口导出成文件
- 导出能力已有自动化测试，不只是手工点通
- 导出不会改变现有词典学习和热路径行为

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- 已完成：`TermDictionary` 现在已经补齐本地导出能力；`Settings -> Dictionary` 可显式导出当前词典快照，`TermDictionaryStore` 也已有回归测试
- 已完成：上一轮 `HotPathCoordinator` 边界、`probe-compose` verdict、`ASR` 样本观测三条诊断线已经收口并归档
- 已完成：`Compose workspace switch undo` 自驱 smoke 已落地，`make smoke-compose-switch-undo` 现在直接验证“先写入 workspace A，再切到 workspace B，再执行 secondary action 时，只撤回 B 的最近一次提交，A 保持不变”
- 已完成：`Compose` 最近一次提交撤回已有自驱 smoke，`make smoke-compose-undo` 现在直接验证“提交后第二动作只回滚当前 compose workspace 的最近一段写入”
- 已完成：`Compose / Capture` 继续口述、自驱撤回、手动整理、整理失败回退这几条工作区基线已经有 smoke 覆盖
- 已完成：`submit`、整理后手改、`dirty -> confirm undo -> undo refine` 这些工作区边界已经有真实行为定义
- 已完成：`SecondaryAction` 执行层现在和展示层保持同一条规则，没有 spoken content 的 workspace 不会偷偷进入 `Refine`
- 已完成：`ASR Correction` 已被明确成独立于 `Refine` 的 transcript 级后校正层，当前仍不进入默认热路径
- 已完成：识别提交链路现在已经插入默认 no-op 的 `ASR Correction` seam；启用前不改变现有热路径，失败时也会回退到 `Clean`
- 已完成：`ASR Correction` 已有内部可控的 OpenAI-compatible adapter 与回归测试，但默认配置仍然关闭
- 已完成：`ASR Correction` 已补上隐藏运行参数入口，只有在内部完整提供 `baseURL + apiKey + model` 时才会生效；普通运行继续保持关闭
- 已完成：`ASR Correction` 已补上独立 smoke 自驱入口，`make smoke-asr-correction` 会起本地 stub、测试宿主和 SpeakDock，直接验证 transcript 后校正能注入到 live workspace
- 已完成：`make run` 现在也支持通过 `SPEAKDOCK_ASR_CORRECTION_BASE_URL / API_KEY / MODEL` 环境变量临时启用内部 `ASR Correction`，不需要手写 `open --args`
- 已完成：`ASR Correction` 提交处理现在会留下结构化结果日志，`make asr-correction-report` 可以直接汇总 `corrected / unchanged / fallback` 与改写比率，开始支撑真实样本评估
- 已完成：`speech-logs / speech-error-report` 诊断入口已落地
- 已完成：基于真实 `zh-CN + kAFAssistantErrorDomain#1110` 样本，`ASR` 首句失败已有最小窄修正
- 已完成：`TermDictionary` 的词级学习热路径、Settings 可读层和报告入口都已稳定
