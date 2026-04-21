# SpeakDock 端侧小模型深度调研与候选测评

状态：研究文档，只基于官方/一手资料，不自动升级为架构承诺。当前产品真值仍以 `docs/technical/ARCHITECTURE.md` 为准。

日期：2026-04-21

## 1. 这页解决什么问题

这一轮不是直接锁定模型，而是先回答三个更基础的问题：

1. SpeakDock 需要哪些不同角色的模型，而不是一个笼统的“小模型方案”
2. 在当前机器条件下，哪些候选值得进入第一轮 shortlist
3. 第一轮应该怎么测，才能避免“先接进去再补评估”的漂移

注：

- 这页是第一轮总研究页
- 对文本模型而言，后续第二轮已经进一步收口为“只看 `Qwen3.5` 最新线，不再考虑 `Qwen3.0` 文本模型”
- 文本后纠错的最新结论以 [2026-04-21-asr-post-correction-cloud-refine-research.md](./2026-04-21-asr-post-correction-cloud-refine-research.md) 为准

在本轮研究之后，产品边界已进一步收口为：

- 端侧小模型当前只承担 `ASR Post-Correction`
- `Workspace Refine` 默认走云端 LLM
- 高性能机器可允许用户自定义本地 `Refine`，但这不是产品默认路线

## 2. 当前前提

本轮评测前提固定为本机真实环境：

- 机器：`MacBook Air`
- 芯片：`Apple M3`
- 内存：`16 GB`
- 系统：`macOS 15.7.4`

工程约束：

- SpeakDock 当前热路径已经稳定在 `Apple Speech -> Clean -> Workspace -> Compose/Capture`
- 端侧模型不能反向污染当前热路径定义
- 失败必须可回退，不能为了“端侧”把默认可用性做差
- 中文优先，中英混输、专有名词和术语保真比英文 benchmark 更重要

推断：

- `MacBook Air` 属于热量裕度更紧的机器，端侧方案不能只看“能跑”，还要看连续使用时是否过热

## 3. 角色必须拆开

SpeakDock 不能把 `ASR`、`ASR Post-Correction`、`Workspace Refine` 混成一个模型问题。

### 3.1 `ASR`

- 输入：音频
- 输出：实时或准实时文本
- 重点：中文准确率、低延迟、热路径可用、可流式反馈

### 3.2 `ASR Post-Correction`

- 输入：已经出字但不够准的 transcript
- 输出：词级或短句级修正后的文本
- 重点：术语保真、不要整句乱改、延迟必须明显小于 `Workspace Refine`

### 3.3 `Workspace Refine`

- 输入：当前 active workspace 文本
- 输出：表达更清晰、结构更好的工作区内容
- 重点：意图保持、结构整理、风格控制、失败可回退

结论：

- `ASR` 候选更偏语音模型和系统能力
- `ASR Post-Correction` 候选更偏小型文本模型
- `Workspace Refine` 候选更偏质量更高的文本模型

当前产品决策：

- 端侧小模型主线只保留给 `ASR Post-Correction`
- `Workspace Refine` 不再进入端侧默认方案筛选
- 本地 `Refine` 只保留为高配机器上的用户自定义扩展

它们不该共用一个 shortlist。

## 4. `ASR` 已完成的第一轮收敛

这一层已经有独立子页：

- [2026-04-21-asr-official-source-shortlist.md](./2026-04-21-asr-official-source-shortlist.md)

当前结论：

- 必留基线：`Apple Speech`
- 强 shortlist：`Qwen3-ASR-0.6B`、`SenseVoice`
- 对照 shortlist：`Whisper`
- 观察名单：`Moonshine`

这页不重复抄一遍 `ASR` 细节，只继续向下回答文本模型与测评设计。

## 5. 文本模型候选筛选

这里的目标已经收口：

- 主线：筛 `ASR Post-Correction`
- 非主线：评估哪些 `Workspace Refine` 本地方案应直接 `pass`

### 5.1 Apple Foundation Models

官方来源：

- [Generating content and performing tasks with Foundation Models](https://developer.apple.com/documentation/FoundationModels/generating-content-and-performing-tasks-with-foundation-models)
- [Prompting an on-device foundation model](https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model)
- [SystemLanguageModel](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel)
- [Foundation Models adapter training](https://developer.apple.com/apple-intelligence/foundation-models-adapter/)
- [How to get Apple Intelligence](https://support.apple.com/en-us/121115)

官方信号：

- Apple 把它定位在摘要、提取、改写、分类、标签生成等任务
- 文档明确写了 on-device 模型更适合短、清晰、单任务 prompt，复杂任务要拆解
- 公开开发资料与适配器训练资料对应的是 `macOS 26` 一代能力

现实判断：

- 从 Swift 集成角度，它是最顺的未来路线
- 但从当前产品阶段看，它不该被写成今天就能落地的主线
- 当前机器是 `macOS 15.7.4`，而 Apple 当前公开的 Foundation Models 路线明显偏更高系统代际

结论：

- `watchlist`
- 角色：`未来 Apple 原生文本能力候选`
- 当前不进入产品默认路线

### 5.2 Qwen3 小模型

官方来源：

- [Qwen3-0.6B](https://huggingface.co/Qwen/Qwen3-0.6B)
- [Qwen3-1.7B-MLX-4bit](https://huggingface.co/Qwen/Qwen3-1.7B-MLX-4bit)
- [MLX-LM](https://github.com/ml-explore/mlx-lm)

官方信号：

- Qwen3 官方模型卡明确给出 `100+` 语言与方言支持
- `Qwen3-0.6B` 提供 `32K` context，文档明确支持本地推理与 `mlx-lm`
- 官方直接给出了 `Qwen3-1.7B-MLX-4bit` 资产，这对 Apple Silicon 很关键

现实判断：

- 这是当前最有“中文优先 + Apple Silicon 可落地”味道的文本候选之一
- `0.6B` 更适合做轻量级 `ASR Post-Correction`
- `1.7B` 可以进入 `ASR Post-Correction` 的最小可行测试池

结论：

- `进入 shortlist`
- 角色：`ASR Post-Correction` 主候选

### 5.3 Gemma 3n

官方来源：

- [Gemma 3n model card](https://ai.google.dev/gemma/docs/gemma-3n/model_card)
- [MLX](https://github.com/ml-explore/mlx)
- [MLX-LM](https://github.com/ml-explore/mlx-lm)

官方信号：

- Gemma 3n 明确为低资源设备设计
- 官方给出 `2B / 4B` 有效规模与 `32K` context
- 官方强调多语言能力，并把它放在 on-device 场景里讨论

现实判断：

- 从设备约束看，它是最像“端侧小模型”目标答案的文本候选
- 它很适合做 `ASR Post-Correction`
- 但 `4B` 级别不适合作为这台底线机器上的默认路线

结论：

- `进入 shortlist`
- 角色：`ASR Post-Correction` 候选

### 5.4 Gemma 3

官方来源：

- [Gemma 3 model card](https://ai.google.dev/gemma/docs/core/model_card_3)
- [MLX](https://github.com/ml-explore/mlx)
- [MLX-LM](https://github.com/ml-explore/mlx-lm)

官方信号：

- 官方给出 `1B / 4B / 12B / 27B` 模型族
- `4B/12B/27B` 支持 `128K` context，适合更长文本整理
- 官方强调摘要、问答、推理、多语言能力

现实判断：

- 对 SpeakDock 来说，真正有价值的是 `1B`
- `4B` 更适合质量更高的 `Workspace Refine`
- `12B / 27B` 对当前 `16 GB` 机器不适合进入首轮主测

结论：

- `pass`
- 原因：`Workspace Refine` 已不再进入端侧默认路线，`4B` 也不适合底线机器

### 5.5 Llama 3.2

官方来源：

- [Llama-3.2-3B-Instruct](https://huggingface.co/meta-llama/Llama-3.2-3B-Instruct)
- [MLX-LM](https://github.com/ml-explore/mlx-lm)

官方信号：

- 官方 intended use 明确覆盖摘要、改写、写作助手等场景
- `1B / 3B` 与 `128K` context 很适合做工程 benchmark

现实判断：

- 官方支持语言列表里没有中文，这对 SpeakDock 是硬伤
- 它适合做工程基线，不适合做中文优先产品主线

结论：

- `benchmark only`
- 角色：`英文与工程基线`

### 5.6 Phi-4-mini

官方来源：

- [Phi-4-mini-instruct](https://huggingface.co/microsoft/Phi-4-mini-instruct)

官方信号：

- 官方明确强调它面向资源受限和延迟敏感场景
- `3.8B dense` 与 `128K` context 对工作区整理很有吸引力

现实判断：

- 官方模型卡也明确说明其主要训练语料偏英文，非英文能力存在明显 gap
- 对 SpeakDock 这种中文优先产品，更适合做 reasoning 对照，不适合先做主候选

结论：

- `benchmark only`
- 角色：`推理对照基线`

### 5.7 MLX / MLX-LM 的位置

官方来源：

- [MLX](https://github.com/ml-explore/mlx)
- [MLX-LM](https://github.com/ml-explore/mlx-lm)

判断：

- `MLX / MLX-LM` 不是模型候选，而是 Apple Silicon 上的关键运行层
- 文本模型是否值得进入首轮 shortlist，一个重要加分项就是能否较顺地接入 `MLX / MLX-LM`

结论：

- 后续文本模型评测默认优先看 `MLX / MLX-LM` 路线

## 6. 第一轮 shortlist

### 6.1 `ASR`

- `Apple Speech`
- `Qwen3-ASR-0.6B`
- `SenseVoice`
- `Whisper`

不建议首轮进入：

- `Moonshine`

### 6.2 `ASR Post-Correction`

- `Qwen3-0.6B`
- `Qwen3-1.7B-MLX-4bit`
- `Gemma 3n 2B / 4B`
- `Gemma 3 1B`

benchmark only：

- `Llama 3.2 3B`
- `Phi-4-mini`

### 6.3 `Workspace Refine`

当前产品默认路线：

- 走云端 LLM

高配机器高级自定义扩展：

- 用户可自行配置本地 `Refine` provider

当前不进入默认端侧主线：

- `Gemma 3 4B`
- `Qwen3-1.7B-MLX-4bit`
- `Gemma 3n 4B`
- `Apple Foundation Models`
- `Phi-4-mini`
- `Llama 3.2 3B`

## 7. 第一轮筛选标准

每个候选都不只看“效果”，而是按同一套维度筛：

1. 中文质量
   是否能稳住中文和中英混输
2. 术语保真
   是否容易把专有名词改坏
3. 热路径延迟
   是否适合 `ASR` 或 `ASR Post-Correction`
4. 内存与热量
   是否适合 `MacBook Air + 16 GB`
5. Swift / Apple Silicon 集成难度
   是否有清楚的本地运行路线
6. 失败回退成本
   接入后失败时能否优雅回退
7. 角色匹配度
   它到底适不适合当前这一层，而不是“看起来很强”

## 8. 第一轮测评设计

### 8.1 `ASR`

目标：

- 决定 `Apple Speech` 之外是否有值得接入的本地 `ASR`

样本：

- 中文连续说话
- 中英混输
- 专有名词与产品名
- 技术术语
- 短句
- 长句
- 弱音量和轻噪声

指标：

- 首字延迟
- 最终结果延迟
- CER / 术语命中率
- 首句失败率
- 内存峰值
- 连续 10 分钟使用后的热量表现

执行顺序：

1. `Apple Speech` 作为基线
2. `Qwen3-ASR-0.6B` 先做 Apple Silicon 可行性验证
3. `SenseVoice` 作为中文低时延对照
4. `Whisper` 作为稳定对照组

### 8.2 `ASR Post-Correction`

目标：

- 判断小文本模型是否能在不乱改整句的前提下提升词准

样本：

- 来自真实 `ASR` 错误样本
- 重点覆盖术语、缩写、专有名词

指标：

- 词级修正收益
- 误伤率
- 平均延迟
- 是否出现整句重写
- 与 `TermDictionary` 的协作价值

执行顺序：

1. `Qwen3-0.6B`
2. `Qwen3-1.7B-MLX-4bit`
3. `Gemma 3n 2B / 4B`
4. `Gemma 3 1B`

### 8.3 `Workspace Refine`

目标：

- 当前不做默认端侧测评，直接以云端 LLM 为默认实现路线

样本：

- 聊天输入
- 文档输入
- 邮件输入
- 中英混输
- 有术语约束的工作区文本

指标：

- 意图保持
- 结构整理质量
- 风格控制
- 术语保真
- 平均延迟
- 峰值内存

执行顺序：

1. 云端 provider 作为默认路线继续保留
2. 本地 `Refine` 只在高配机器的用户自定义扩展场景下再单独验证

## 9. 当前结论

截至 2026-04-21，这一轮研究得出的判断是：

- `ASR` 第一优先不是“马上替换 Apple Speech”，而是先验证 `Qwen3-ASR-0.6B` 在 Apple Silicon 上是否真有可行本地路线
- `Whisper` 必须保留为 Apple Silicon 对照组，因为它的官方路径比 `Qwen3-ASR` 更清楚
- 端侧文本模型主线只保留 `ASR Post-Correction`
- `Workspace Refine` 默认走云端 LLM，不再把本地 `Refine` 当底线机器上的产品路线
- `Apple Foundation Models` 是重要 future watchlist，但在当前 `macOS 15.7.4` 机器条件下，不应被写成现阶段主线

## 10. 下一步建议

1. 先做 `ASR` 候选的可行性闸门，不直接开始全量集成
2. 同时准备一套真实 `ASR` 错误样本，避免 `ASR Post-Correction` 变成空测
3. `Workspace Refine` 继续保留云端 provider 作为默认实现路线
4. 等第一轮数据出来，再决定 `ASR Post-Correction` 的具体量化、生命周期和默认 provider
