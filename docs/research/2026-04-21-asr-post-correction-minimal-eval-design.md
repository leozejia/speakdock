# SpeakDock `ASR Post-Correction` 最小实测设计

状态：设计文档。用于决定下一轮 spike 怎么做，不自动升级为架构真值。产品行为仍以 `docs/technical/ARCHITECTURE.md` 为准。

日期：2026-04-21

## 1. 这页在解决什么

这一页只解决一个问题：

- 在 `MacBook Air / Apple M3 / 16 GB / macOS 15.7.4` 这台底线机器上，`ASR Post-Correction` 到底该怎么做最小可行评测，才能决定某个本地文本模型值不值得进入实现 spike。

这里评的是：

- `ASR Post-Correction`
- 也就是 transcript 已经出来后，做词级纠正的那一层

这里不评：

- `ASR`
- `Workspace Refine`
- `Wiki Compile`

## 2. 不做什么

这轮明确不做：

- 不直接把候选模型接进默认热路径
- 不把 Apple Speech 替换成本地 `ASR`
- 不为了评测先做一套新的产品 UI
- 不用 benchmark、论文分数或别人视频替代真实样本评测
- 不把 `Compose / Capture` 分成两套模型评测，因为这一层发生在路由之前

## 3. 选定方案

这轮采用：

- `fixture-first`
- `两道硬闸门 + 一道接线 smoke`

具体顺序：

1. 先做离线样本闸门，只看“会不会改对、会不会乱改”
2. 再做底线机器运行闸门，只看“快不快、占不占、会不会挂”
3. 最后走一次仓库现有 `ASRCorrectionEngine` 接线 smoke，确认它能挂回 SpeakDock 当前 seam

选择这条路，而不是“先集成再看”，原因很直接：

- SpeakDock 当前已经有 `ASRCorrectionEngine` seam
- 现在缺的不是入口，而是准入闸门
- 如果先接模型、后补评测，后面很容易变成谁先跑通谁赢

补一条当前阶段的固定偏好：

- 直接优先跑来源清晰的社区运行优化版
- 官方原版只在结果异常时作为诊断锚点
- 没有明确来路的二次训练或激进魔改版，不进入当前主线

## 4. 这轮建立在哪些现有积木上

仓库里已经有这些现成入口：

- `Sources/SpeakDockCore/Routing/ASRCorrection.swift`
- `Sources/SpeakDockCore/Routing/ConservativeASRCorrectionPrompt.swift`
- `Sources/SpeakDockMac/ASRCorrection/OpenAICompatibleASRCorrectionEngine.swift`
- `make smoke-asr-correction`
- `make asr-correction-report`
- `make speech-error-report`
- `make asr-sample-report`

所以这一轮正确的推进方式不是新开产品路径，而是：

- 先固定样本与指标
- 再让候选模型通过同一套门

## 5. 评测作用域

`ASR Post-Correction` 是路由前层，不区分 `Compose / Capture`。

这条判断要先写死：

- 输入是 `clean transcript`
- 输出是 `corrected transcript`
- 路由到 `Compose` 还是 `Capture`，发生在这层之后

所以：

- 模型质量评测只做一次
- 不需要为了 `Compose / Capture` 各跑一套候选比较
- 最终只需要用一条接线 smoke 证明它能挂回当前 app seam

## 6. 样本基线

### 6.1 唯一样本真源

下一轮代码 spike 必须先补一份匿名基线夹具，路径写死为：

- `Tests/SpeakDockMacTests/Fixtures/asr-post-correction-anonymous-baseline.json`

这份夹具是之后：

- 本地批量评测
- 报表脚本测试
- 候选模型横向比较

共享的唯一真源。

### 6.2 最小样本组成

第一版最小样本固定为 `48` 条，不再继续缩。

分布写死为：

- `term`：12 条
- `mixed`：12 条
- `homophone`：12 条
- `control`：12 条

含义：

- `term`
  - 产品名、项目名、人名、品牌名、术语名
- `mixed`
  - 中英混输、模型名、API 名、代码词、命令词
- `homophone`
  - 中文同音或近音误识别
- `control`
  - 原文本来就对，只允许原样返回

### 6.3 样本来源优先级

优先级写死为：

1. 真实匿名化样本
2. 真实词典冲突或真实中英混输样本
3. 只在 bucket 不够时，才允许人工补少量 synthetic gap-fill

禁止：

- 只拿人工编的理想样本拼整套评测

### 6.4 夹具字段

第一版夹具字段固定为：

- `id`
- `bucket`
- `input`
- `expected`
- `should_change`
- `source`
- `notes`

字段约束：

- `bucket` 只允许：`term / mixed / homophone / control`
- `should_change = false` 只允许出现在 `control`
- `expected` 必须是最终字符串，不做多答案

示例：

```json
{
  "id": "term-001",
  "bucket": "term",
  "input": "project adults 已经完成",
  "expected": "Project Atlas 已经完成",
  "should_change": true,
  "source": "real-anonymized",
  "notes": "项目名误识别"
}
```

## 7. 评测闸门

### 7.1 闸门 A：离线正确性

这一步只看字符串结果，不看 app。

通过条件写死为：

- `term / mixed / homophone` 三个 bucket 各自至少 `10 / 12` 条精确命中
- 三个需要纠正的 bucket 合计至少 `32 / 36` 条精确命中
- `control` 必须 `12 / 12` 原样返回
- `fallback / empty / malformed output` 必须是 `0`

失败即 `pass`，不进入下一闸门。

### 7.2 闸门 B：底线机器运行

这一步在同一份 `48` 条夹具上跑，机器固定为当前底线机器。

通过条件写死为：

- `p50 latency <= 350ms`
- `p95 latency <= 800ms`
- `peak RSS <= 3.5 GB`
- 单次 `48` 条批量跑完过程中，不允许 crash / hang

分类规则：

- 全通过：`ready`
- 正确性过了，但运行指标没过：`watchlist`
- 正确性没过：`pass`

### 7.3 闸门 C：SpeakDock 接线 smoke

这一步不再横评模型，只验证“它能挂回当前 seam”。

通过条件：

- `make smoke-asr-correction` 必须通过
- `make asr-sample-report LOG_WINDOW=5m ASR_EVAL_THRESHOLD=20` 在真实本地验证后，至少能进入一次 `ready`
- 最近 `20` 次本地观察会话里，`fallback rate <= 10%`

这一步只在候选已经过了前两道门之后才做。

## 8. 候选执行顺序

候选分三层：

1. `主候选`
2. `对照候选`
3. `结构替代`

当前顺序写死为：

1. 主候选：`mlx-community/Qwen3.5-0.8B-4bit-OptiQ`
2. 对照候选：`mlx-community/Qwen3.5-0.8B-4bit`
3. 结构替代：`mlx-community/gemma-3-1b-it-4bit`
4. 诊断锚点：`Qwen/Qwen3.5-0.8B`

理由：

- `mlx-community/Qwen3.5-0.8B-4bit-OptiQ` 是当前唯一主候选
- 它是标准 `MLX` 运行路径，模型卡直接给出 `mlx-lm >= 0.30.7`
- 它不是纯 uniform 4-bit，而是 `OptiQ` 的混合精度方案：`4/8-bit` 分层分配，目标 `4.5 BPW`
- `mlx-community/Qwen3.5-0.8B-4bit` 只保留为对照组，用来判断 `OptiQ` 的额外复杂度是否真的换来了更好的质量
- `mlx-community/gemma-3-1b-it-4bit` 保留为结构替代，不和 Qwen 两个 4bit 混成一组
- 官方 `Qwen/Qwen3.5-0.8B` 不再占第一执行位，只在社区版结果异常时用来定位问题是出在模型、量化还是 runtime

执行规则：

- 先跑 `mlx-community/Qwen3.5-0.8B-4bit-OptiQ`
- 再跑 `mlx-community/Qwen3.5-0.8B-4bit` 做同族对照
- 如果 `OptiQ` 在闸门 A 上没有明显优势，就停止为它追加复杂度
- 如果两个 Qwen 社区版都不理想，再拉 `mlx-community/gemma-3-1b-it-4bit`
- 只有社区版结果异常到无法判因，才回头拉官方 `Qwen/Qwen3.5-0.8B`

## 9. 这轮所需依赖

做这轮最小评测需要的外部依赖固定为：

- 本地模型权重
- Apple Silicon 可运行的本地推理路径
- `python3`
- 仓库现有 `Makefile / smoke / report` 入口

这轮不需要：

- 云端 API Key
- 新的产品设置页
- 新的后台服务

## 10. 明确延后项

以下事项本轮明确延后，不在最小评测设计里展开：

- 量化版本最终锁定
- sidecar 形态最终锁定
- 自动化热量遥测
- 多轮 prompt 调优

延后理由：

- 在有候选先通过闸门 A 之前，这些都太早
- 先把“值不值得做”判清，再讨论“怎么工程化最优”

## 11. 下一轮代码 spike 应该产出什么

下一轮实现只需要交付这些最小产物：

1. `asr-post-correction-anonymous-baseline.json`
2. 基于该夹具的本地批量评测入口
3. 统一输出 `exact-match / over-edit / fallback / latency / rss` 的报表
4. `mlx-community/Qwen3.5-0.8B-4bit-OptiQ` 与 `mlx-community/Qwen3.5-0.8B-4bit` 的首轮真实对比结果

如果以上四项没出来，就不应开始讨论“是否默认开启本地 `ASR Post-Correction`”。
