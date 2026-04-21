# SpeakDock Current Focus

## 1. 用途

这份文档是当前唯一 live doc。

- 同时承担 `live plan` 和 `live review`
- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、复核结论和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：`ASR Post-Correction 最小实测准备`
- 状态：`In Progress`

## 3. 当前复核结论

- 第二轮 research 已完成，当前不再继续扩大候选池
- `ASR Post-Correction` 当前规则改为：
  - 直接优先跑来源清晰的社区运行优化版
  - 官方原版只在结果异常时作为诊断锚点
- 当前最小顺序写死为：
  - 主候选：`mlx-community/Qwen3.5-0.8B-4bit-OptiQ`
  - 对照候选：`mlx-community/Qwen3.5-0.8B-4bit`
  - 结构替代：`mlx-community/gemma-3-1b-it-4bit`
  - 诊断锚点：`Qwen/Qwen3.5-0.8B`
- 当前正确动作不是先接模型，而是先写死样本、指标和准入闸门
- `ASR Post-Correction` 是路由前层，不单独区分 `Compose / Capture`
- 当前 app 已经具备现成接线积木：
  - `ASRCorrectionEngine`
  - `make smoke-asr-correction`
  - `make asr-correction-report`
  - `make asr-sample-report`
- 本轮 live focus 只做“最小实测准备”，不碰默认热路径

## 4. 为什么现在做

第二轮 research 已经把方向收住了，但还没有把“怎么测才算过”写成工程动作。

- 如果先接模型、后补评测，主线很容易再次漂移
- 当前缺的是样本真源、评测闸门和候选执行顺序
- 只有把这些写死，下一轮代码 spike 才不会变成“谁先跑通谁赢”

所以这一轮先做评测准备，不直接做本地模型接入。

## 5. 本轮范围

1. 写死 `ASR Post-Correction` 匿名样本夹具的字段与 bucket
2. 写死最小正确性闸门、运行闸门和接线 smoke 闸门
3. 写死候选执行顺序与停止条件
4. 把现有 `smoke / report` 命令映射回评测流程
5. 同步 `CURRENT / research / docs index`

## 6. 明确不做

- 不在这一轮默认开启本地 `ASR Post-Correction`
- 不在这一轮下载所有候选模型做大杂烩横评
- 不在这一轮改 `Workspace Refine`
- 不在这一轮替换 Apple Speech
- 不把 `Compose / Capture` 拆成两套评测

## 7. 执行顺序

1. 先落地最小实测设计页
2. 再固定匿名夹具 schema 与样本数量
3. 然后定义下一轮代码 spike 的最小交付物
4. 最后先跑 `mlx-community/Qwen3.5-0.8B-4bit-OptiQ`

## 8. 完成定义

满足以下条件才算完成：

- 已有独立的 `ASR Post-Correction` 最小实测设计页
- 样本真源、bucket、字段、数量已经写死
- 三道闸门和 `ready / watchlist / pass` 规则已经写死
- 下一轮代码 spike 的最小交付物已经明确
- 不需要再靠口头解释“先测什么、测到什么算过”

## 9. 下一轮候选

- 基于匿名夹具的本地批量评测入口
- `mlx-community/Qwen3.5-0.8B-4bit-OptiQ` 与 `mlx-community/Qwen3.5-0.8B-4bit` 的首轮真实结果
- `Workspace Refine` prompt 重定义

## 10. 当前不进入下一轮的项

- 不重新打开本地 `Workspace Refine` 默认路线
- 不提前锁定量化版本与 sidecar 形态
- 不在没有真实评测结果前讨论是否默认启用

## 11. 阻塞项

- 当前无外部阻塞

## 12. 最近完成

- 已完成：`第二轮调研：ASR Post-Correction 与云端 Refine` 已归档
- 已完成：`Qwen3-ASR / Qwen3.5-Omni / 文本后纠错模型` 的命名边界纠偏
- 已完成：`ASR Post-Correction` 最小 shortlist 已收口
- 已完成：`ASR Post-Correction` 最小实测设计页已落地
- 已完成：匿名基线夹具、离线评测报表脚本与 `make asr-post-correction-eval-report` 入口已落地
