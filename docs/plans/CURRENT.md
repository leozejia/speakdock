# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：把 `ActiveWorkspace + SecondaryAction` 锁成当前唯一主线，并据此继续推进工作区级 `Refine / Submit / Undo`
- 状态：`In Progress`

## 3. 为什么现在做

上一轮已经完成了两块重要收口：

- `Compose / Capture / Refine / Undo` 的工作区热路径已经有一批自驱基线
- `ASR` 首句失败的第一份真实样本也已经做了窄修正并完成归档

但最近也暴露出一个更危险的问题：主线认知开始漂。

- 外部竞品和入口形态很容易把认知带偏成“选中一段文字，直接改写”
- 这类入口可以有价值，但它不是 SpeakDock 的总模型
- SpeakDock 真正要守住的是 `ActiveWorkspace`
- `SecondaryAction` 也必须始终绑定当前工作区，而不是绑定“当前选中片段”

如果这件事不先写死，后续无论做 `Compose / Capture / Wiki / hardware trigger`，都会慢慢漂成局部功能拼盘。

所以这一轮先不追新入口，也不追新能力，先把主线重新收口成唯一正确版本。

## 4. 本轮范围

1. 归档已完成的 `ASR` 首句失败收敛阶段，不再让旧 focus 停留在 `CURRENT.md`
2. 明确 SpeakDock 当前唯一底层模型是 `ActiveWorkspace + SecondaryAction`
3. 明确 `selection refine` 只能是未来 `Compose` 下的候选显式入口，不是当前主线
4. 同步 `CURRENT / ARCHITECTURE / docs index`，让文档重新只指向同一条主线
5. 后续实现只继续围绕工作区级 `Clean / Refine / Submit / Undo`，不再引入新的顶层模式

## 5. 明确不做

- 不把 `selection refine` 升级成 SpeakDock 的默认产品模型
- 不新增独立“选中文本模式”
- 不让竞品入口反向定义 SpeakDock 的底层架构
- 不为了这轮主线纠偏去扩新的模型运行时
- 不把句子级整理重新混进词级纠错或词典学习
- 不把 `Wiki`、硬件触发器、未来多端能力从总模型里删掉

## 6. 执行顺序

1. 先把上一轮 `ASR` 收敛结果归档
2. 再把 `CURRENT / ARCHITECTURE / docs index` 统一到同一条主线
3. 然后只从 `ActiveWorkspace` 视角挑下一条最小行为任务推进
4. 新实现必须优先补自驱验证，不靠新的人工口径
5. 每完成一轮，再归档当前 plan，继续保持 `CURRENT` 只承载单一 focus

## 7. 完成定义

满足以下条件才算完成：

- `CURRENT / ARCHITECTURE / docs index` 对当前主线的表述一致
- 文档已经明确 `ActiveWorkspace + SecondaryAction` 是唯一主模型
- 文档已经明确 `selection refine` 只是候选入口，不是总模型
- 下一条实现任务仍然自然落在工作区级 `Refine / Submit / Undo` 上，而不是分裂出新模式

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

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
