# SpeakDock Current Focus

## 1. 用途

这份文档是当前唯一 live doc。

- 同时承担 `live plan` 和 `live review`
- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、复核结论和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：`ASR Post-Correction 首轮实测收敛`
- 状态：`In Progress`

## 3. 当前复核结论

- 第二轮 research 已完成，当前不再继续扩大候选池
- `ASR Post-Correction` 继续保持：
  - 社区运行优化版优先
  - 官方原版只在结果异常时作为诊断锚点
- 当前精确顺序已收敛为：
  - 主候选：`mlx-community/Qwen3.5-2B-OptiQ-4bit`
  - 对照候选：`mlx-community/Qwen3.5-2B-4bit`
  - 结构替代：`mlx-community/gemma-3-1b-it-4bit`
  - 独立 ASR 线：`mlx-community/Qwen3-ASR-0.6B-4bit`
- 两个 `4bit` 不是同一个东西：
  - `Qwen3.5-2B-4bit` 是普通统一 `4-bit` 转换版
  - `Qwen3.5-2B-OptiQ-4bit` 是 `4/8-bit` 混合精度版，目标 `4.5 BPW`
- 首轮真实结果已经足够排除 `0.8B` 线：
  - `mlx-community/Qwen3.5-0.8B-OptiQ-4bit`：`12/48`
  - `mlx-community/Qwen3.5-0.8B-4bit`：`9/48`
  - `Qwen/Qwen3.5-0.8B`：`12/48`
- 同一套 few-shot 夹具下，`2B` 线结果为：
  - `mlx-community/Qwen3.5-2B-OptiQ-4bit`：`15/48`，`over-edit = 1`
  - `mlx-community/Qwen3.5-2B-4bit`：`13/48`，`over-edit = 2`
- 当前结论不是“已经可接产品”，而是：
  - `2B-OptiQ-4bit` 是唯一值得继续优化的本地文本后纠错候选
  - 下一步应该优化 prompt 与评测入口，不应该直接接默认热路径
- `ASR Post-Correction` 是路由前层，不单独区分 `Compose / Capture`
- 当前 app 已经具备现成接线积木：
  - `ASRCorrectionEngine`
  - `make smoke-asr-correction`
  - `make asr-correction-report`
  - `make asr-sample-report`
- 本轮 live focus 继续不碰默认热路径

## 4. 为什么现在做

第二轮 research 已经把方向收住了，首轮真实结果也已经出来，但“唯一继续项”还没有写死。

- 如果不把当前结论写死，后续很容易重新回到 `0.8B / 2B / ASR / Refine` 混线状态
- 当前缺的是唯一继续版本、同族对照和下一轮最小代码 spike
- 只有先把这些写死，下一轮实现才不会重新扩散

所以这一轮先做实测收敛，不直接做本地模型接入。

## 5. 本轮范围

1. 把首轮真实结果写回唯一 live doc
2. 纠正候选仓库名与执行顺序
3. 明确 `2B-OptiQ-4bit` 为什么保留、普通 `4bit` 为什么只做对照
4. 写死下一轮代码 spike 只服务于 `2B` 线
5. 同步 `CURRENT / research / docs index`

## 6. 明确不做

- 不在这一轮默认开启本地 `ASR Post-Correction`
- 不在这一轮继续扩大候选池
- 不在这一轮改 `Workspace Refine`
- 不在这一轮替换 Apple Speech
- 不把 `Compose / Capture` 拆成两套评测

## 7. 执行顺序

1. 先把首轮实测结果和错误仓库名纠回文档
2. 再把继续版本收敛到 `mlx-community/Qwen3.5-2B-OptiQ-4bit`
3. 然后定义下一轮代码 spike 的最小交付物
4. 最后只围绕 `2B` 线继续跑 prompt 与评测入口

## 8. 完成定义

满足以下条件才算完成：

- 已有独立的 `ASR Post-Correction` 最小实测设计页
- 样本真源、bucket、字段、数量已经写死
- `0.8B` 与 `2B` 的首轮结果已经写回文档
- 当前唯一继续候选已经收敛到 `mlx-community/Qwen3.5-2B-OptiQ-4bit`
- 不需要再靠口头解释“为什么是这版，不是那版”

## 9. 下一轮候选

- 基于匿名夹具的 checked-in 本地批量评测 runner
- `mlx-community/Qwen3.5-2B-OptiQ-4bit` 的 prompt 变体对照
- `Workspace Refine` prompt 重定义

## 10. 当前不进入下一轮的项

- 不重新打开本地 `Workspace Refine` 默认路线
- 不在当前结果下直接默认启用本地 `ASR Post-Correction`
- 不提前把 `Qwen3-ASR` 混进文本后纠错线

## 11. 阻塞项

- 当前无外部阻塞

## 12. 最近完成

- 已完成：`第二轮调研：ASR Post-Correction 与云端 Refine` 已归档
- 已完成：`Qwen3-ASR / Qwen3.5-Omni / 文本后纠错模型` 的命名边界纠偏
- 已完成：`ASR Post-Correction` 最小 shortlist 已收口
- 已完成：`ASR Post-Correction` 最小实测设计页已落地
- 已完成：匿名基线夹具、离线评测报表脚本与 `make asr-post-correction-eval-report` 入口已落地
- 已完成：`0.8B / 2B / OptiQ / 普通 4bit` 的首轮真实对照
- 已完成：当前唯一继续候选收敛到 `mlx-community/Qwen3.5-2B-OptiQ-4bit`
