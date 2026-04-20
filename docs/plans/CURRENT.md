# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：在继续引入新工作区行为前，先锁 `HotPathCoordinator` 边界，并补齐 `AX probe / ASR 样本观测` 这两条最小回归面
- 状态：`Completed`

## 3. 为什么现在做

上一轮已经把 `ActiveWorkspace + SecondaryAction` 这条主线重新锁回来了，但新的复核也给了三个更现实的提醒：

- `HotPathCoordinator.swift` 已经成为最容易继续膨胀的复杂度中心
- `ClipboardComposeTarget.swift` 这条 Accessibility 路径还缺一条最小自动回归
- `ASR` 真实样本已经开始出现，但现在还不够支撑默认推广 `ASR Correction`

这三件事里，真正危险的不是“功能还没做完”，而是：

- 如果不先锁死 `Coordinator` 边界，新行为会继续向同一个大文件堆
- 如果不补最小 probe，AX 路径会继续靠人工口径验活
- 如果不补样本观测，`ASR Correction` 会停留在“能开”，但无法稳定判断“该不该开”

所以这一轮不追新入口，也不追新模式，只做最小但必要的三件事：锁边界、补 probe、补样本观测。

## 4. 本轮范围

1. 明确 `HotPathCoordinator` 当前只负责编排，不在这一轮直接做大拆分
2. 给 `probe-compose` 增加最小可判断结果，让 AX 路径不再只靠人工读日志
3. 给 `speech / asr correction` 报表补最小样本判读面，方便继续积累真实数据
4. 同步 `CURRENT / review`，让下一轮实现继续落在同一条主线

## 5. 明确不做

- 不在这一轮直接大拆 `HotPathCoordinator`
- 不把 `ASR Correction` 改成默认开启
- 不新增新的工作区模式、触发模式或整理入口
- 不把句子级整理重新混进词级纠错或词典学习
- 不为了 probe / 报表补重型基础设施

## 6. 执行顺序

1. 主线程先明确 `Coordinator` 边界，只做最小决定，不开大重构口子
2. 并行补 `AX probe` 和 `ASR` 样本观测两条低耦合线
3. 每条线都必须先补最小验证，再补实现
4. 合并后统一回归，再把本轮决定写回 review

## 7. 完成定义

满足以下条件才算完成：

- 已明确 `HotPathCoordinator` 这一轮是“锁边界，不大拆”
- `probe-compose` 已能输出最小可判断结果，不再只是人工读日志
- `speech / asr correction` 报表已能更直接支撑真实样本积累
- `CURRENT` 与 `reviews/CURRENT.md` 对这三项的去留决定一致

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- 已完成：`HotPathCoordinator` 的边界已经写死到架构和源码结构里，这一轮明确采用“只做编排，不继续吸收纯规则”的收口策略，不直接做大拆分
- 已完成：`probe-compose` 现在会输出最小 `AX` verdict，`make probe-compose` 结束时至少会给出 `available / no-target / unavailable` 三态判断，不再只靠人工读日志
- 已完成：`ASR` 样本观测现在新增 `make asr-sample-report`；`speech-error-report` 会列出最近失败样本，`asr-correction-report` 会给出 `readiness / changed rate / fallback rate`
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
