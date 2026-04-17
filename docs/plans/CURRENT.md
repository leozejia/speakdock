# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：用真实失败样本收稳 `ASR` 首句失败，当前先验证 `1110 after finish` 的窄修正
- 状态：`In Progress`

## 3. 为什么现在做

刚完成的上一轮，`capture` 侧的 live workspace 自驱基线已经基本收稳：

- `make smoke-capture-continue / make smoke-capture-undo / make smoke-capture-refine-manual / make smoke-capture-refine-dirty-undo / make smoke-capture-refine-fallback` 已经到位
- `capture` 在继续口述 / 撤回 / 整理成功 / 整理失败 / 整理后手改撤回这几条高风险边界上，已经有真实自驱闭环
- 继续在这半边补更多近似 smoke，收益会迅速下降

下一条更值钱的主线是 `ASR` 首句失败收敛：

- 用户真实反馈里仍然存在“第一次说话没出字”这类强感知问题
- 我们现在已经拿到了第一份真实失败样本：`zh-CN + kAFAssistantErrorDomain#1110`
- Apple 官方定义里，`1110` 对应的是 `Failed to recognize any speech`
- 这类问题如果直接做重型 warm-up 或重试，很容易引入新复杂度；更合理的是先做窄修正

所以这轮不做大改，不引入新模型，只先补：

- `speech` 原始日志 + 聚合报告
- `finish` 后掉到 `1110` 时的 partial transcript final fallback
- `dictation` task hint

## 4. 本轮范围

1. 保留 `speech` 原始日志与聚合报告入口
2. 基于真实样本只修 `kAFAssistantErrorDomain#1110`
3. 仅在 `finish requested + wantsRecognition=false` 时考虑 fallback
4. 优先复用已有 partial transcript，不发明新缓存层
5. 同步文档，明确这是一条窄修正，不是完整 warm-up 方案

## 5. 明确不做

- 不扩词级学习语义
- 不引入新的模型运行时
- 不做端侧小模型接入
- 不做正式打包发布
- 不改 Wiki 长线方向
- 不做新 UI 入口
- 不做激进的自动重录、后台预热录音或多次重试
- 不为了这轮诊断新建数据库或本地埋点文件

## 6. 执行顺序

1. 先保留 `speech-logs / speech-error-report` 作为诊断入口
2. 再用真实错误样本锁最小 failing test
3. 补最小运行时修正
4. 跑语音相关定向测试与全量测试
5. 继续等待下一批真实失败样本判断是否要进入更重的 `ASR` 收敛

## 7. 完成定义

满足以下条件才算完成：

- 本地存在稳定的 `speech-logs / speech-error-report` 入口
- `1110 after finish` 这类会话已有最小修正
- 相关行为有回归测试，不靠手工判断
- 文档能准确说明这条修正的边界与非目标

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- 上一轮已完成：term-learning 热路径已稳定，相关单测与 smoke 已收口
- 上一轮已完成：`TermDictionary` 的大小写不敏感、独立词边界、最长 alias 优先都已落地
- 上一轮已完成：workspace handoff 前会先做词级修正结算
- 本轮已完成：整理后继续口述会把当前可见文本吸收成新的 `raw_context` 基线，不再保留过期的撤回态
- 本轮已完成：未整理工作区如果被外部手改，同一 live workspace 的下一段口述前会先同步当前文本；这条规则现在同时覆盖 `compose + capture`
- 本轮已完成：`capture` 多段口述现在在 workspace 内存文本和真实文件里都以换行分段；撤回最近一段时也会把这层分隔一起移除
- 本轮已完成：`compose` 路径现在有 `make smoke-compose-continue` 自驱入口，能真实验证“外部手改后继续口述”
- 本轮已完成：`capture` 路径现在有 `make smoke-capture-continue` 自驱入口，能真实验证“文件被外部手改后继续口述，会先同步再按换行追加”
- 本轮已完成：`capture` 路径现在有 `make smoke-capture-undo` 自驱入口，能真实验证“最近一次文件追加可以直接按共享撤回语义回退”
- 本轮已完成：`capture` 路径现在有 `make smoke-capture-refine-manual` 自驱入口，能真实验证“当前 capture workspace 手动整理后，整理结果会直接写回隔离文件目标”
- 本轮已完成：`capture` 路径现在有 `make smoke-capture-refine-dirty-undo` 自驱入口，能真实验证“整理后的 capture 文件如果被外部手改，二级动作会先进入 dirty，再经确认撤回到原文”
- 本轮已完成：`capture` 路径现在有 `make smoke-capture-refine-fallback` 自驱入口，能真实验证“手动整理失败时，当前 capture 文件保持原文不被污染”
- 本轮已完成：现在有 `make speech-error-report` 本地入口，能把最近 `speech` 会话聚合成 `language / outcome / error domain / error code` 摘要
- 本轮已完成：现在有 `make speech-logs` 本地入口，能直接只看 `speech` category 的原始明细
- 本轮已完成：基于真实 `zh-CN + kAFAssistantErrorDomain#1110` 样本，`AppleSpeechEngine` 现在会在 `finish` 后优先用已有 partial transcript 做 final fallback
- 本轮已完成：`AppleSpeechEngine` 现在显式声明 `request.taskHint = .dictation`
- 本轮已完成：workspace 的 `endLocation` 现在会跟随整理改写、手动改写和撤回后的当前可见文本边界
- 本轮已完成：手动整理现在有独立的 `make smoke-refine-manual` 自驱入口
- 本轮已完成：整理后的外部手改现在会在二级动作前先同步回 workspace，再决定是直接撤回还是先确认
- 本轮已完成：`dirty -> confirm undo -> undo refine` 现在有独立的 `make smoke-refine-dirty-undo` 自驱入口
- 本轮已完成：`Refine fallback` 现在有独立的 `make smoke-refine-fallback` 自驱入口
- 本轮已完成：`submit` 前如果用户手改了当前 workspace，`make smoke-refine-submit-sync` 现在会真实校验整理请求读取的是手改后的当前文本
- 本轮已完成：`submit` 语义已经明确锁定，词级观察保留 pre-sync 差异，发送前 `refine` 仍读取当前可观测文本
- 更早已完成：Settings 的 `Passive Learning` 面板现在能展示 `observed / promoted / conflicted / skippedConfirmed` 状态计数
- 更早已完成：Settings 现在能展示最近学习事件，且只暴露 `alias / canonical / evidence / outcome`
- 更早已完成：项目已经收敛到 `OSLog.Logger + make logs + make speech-logs + make traces + make trace-report + make speech-error-report + make term-learning-report + make smoke-term-learning + make smoke-refine` 的统一调试入口
