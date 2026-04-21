# SpeakDock 第二轮调研：ASR Post-Correction 与云端 Refine

状态：研究文档，只基于官方/一手资料与当前仓库实现，不自动升级为架构承诺。当前产品真值仍以 `docs/technical/ARCHITECTURE.md` 为准。

日期：2026-04-21

## 1. 这轮研究要回答什么

第一轮已经完成了更大的收口：

- 端侧小模型当前只保留给 `ASR Post-Correction`
- `Workspace Refine` 默认走云端 LLM
- 本地 `Refine` 只保留给高配机器上的用户自定义扩展
- `ASR` 与 `ASR Post-Correction` 必须分开看，不能把专用语音模型和文本后纠错模型混写

第二轮只回答两个具体问题：

1. 哪些模型值得进入 `ASR Post-Correction` 的最小候选集
2. 云端 `Workspace Refine` 的默认 provider 契约和失败回退应该如何写死

## 2. 当前机器与产品前提

底线机器：

- `MacBook Air`
- `Apple M3`
- `16 GB RAM`
- `macOS 15.7.4`

产品约束：

- 中文优先
- 中英混输、术语保真优先于英文 benchmark
- `ASR Post-Correction` 只允许保守纠错，不允许整句重写
- `Workspace Refine` 必须失败可回退，不能阻塞发送

## 2.1 命名澄清

截至 `2026-04-21`，基于官方 GitHub、官方 Hugging Face、官方发布页和官方技术报告，可以先把三条线分清：

- `Qwen3-ASR`：开源专用语音识别线，当前可明确验证的公开 checkpoint 是 `Qwen3-ASR-0.6B / 1.7B`
- `Qwen3.5-Omni`：更大的全模态模型线；官方发布页把它定义为 `latest generation of fully omnimodal LLM`，支持文本、图像、音频和音视频理解；系列规格是 `Plus / Flash / Light`
- `ASR Post-Correction`：SpeakDock 自己定义的 text-to-text 词级纠错层，不等于 `ASR`

这意味着：

- 当前没有理由把 `Qwen3.5-Omni` 直接写成底线机器上的默认本地方案
- `Qwen3.5-Omni` 更接近“全模态交互 / API 能力 / 长音视频处理”这类上层能力，不是当前这轮要落地的轻量本地后纠错组件
- 当前也不能把 `Qwen3.5` 文本模型误写成“`Qwen3.5-ASR` 已存在”
- 如果我们讨论的是“端侧专用 ASR”，当前主线仍应先看 `Qwen3-ASR`

## 3. 当前实现现实

这一节不来自外部资料，而来自当前仓库实现。

### 3.1 `ASRCorrectionEngine`

当前 seam：

- `Sources/SpeakDockCore/Routing/ASRCorrection.swift`
- `Sources/SpeakDockMac/ASRCorrection/OpenAICompatibleASRCorrectionEngine.swift`

当前行为：

- 输入是已经 `clean` 过的 transcript
- 只有 `enabled + baseURL + apiKey + model` 完整时才会触发模型纠错
- 模型异常或返回空文本时，直接回退到 `cleanText`
- 当前 HTTP 契约是 OpenAI-compatible `POST /chat/completions`

当前 prompt 语义：

- `Sources/SpeakDockCore/Routing/ConservativeASRCorrectionPrompt.swift`
- 明确要求：只修术语、人名、中英混输、同音误识别和极少量缺失标点
- 明确禁止：润色、改写、删减、扩写、结构变化

结论：

- 这条 seam 已经和产品语义高度一致
- 第二轮研究的目标不是换掉语义，而是选出最小可行候选集

### 3.2 `RefineEngine`

当前 seam：

- `Sources/SpeakDockCore/Refine/RefineEngine.swift`
- `Sources/SpeakDockMac/Refine/OpenAICompatibleRefineEngine.swift`

当前行为：

- 当前 HTTP 契约也是 OpenAI-compatible `POST /chat/completions`
- `manual refine` 失败时回退到 `clean text`
- `submit refine` 失败时回退到 `current workspace text`，继续发送
- 仓库里已有对应 smoke：
  - `make smoke-refine`
  - `make smoke-refine-fallback`
  - `make smoke-refine-submit-sync`

关键发现：

- 当前 `ConservativeRefinePrompt` 仍然是“保守纠错”语义，而不是“工作区整理”语义
- 也就是说，云端 `Refine` 的网络缝隙和回退策略已经成熟，但 prompt 语义仍存在漂移

结论：

- 第二轮关于云端 `Refine` 的核心不是“选一个更大的模型”，而是：
  - 保持 provider 契约稳定
  - 先把 prompt 与产品语义对齐
  - 保持失败不阻塞发送

## 4. `ASR Post-Correction` 的筛选标准

对 SpeakDock 来说，这一层不是“谁推理最强”，而是谁更适合“保守词级纠错”。

必须满足：

1. 中文与中英混输有官方正面信号
2. 可以稳定关闭思考模式或避免输出 reasoning 痕迹
3. 可以通过 `MLX / MLX-LM` 或官方明确的 Apple Silicon 路线在本机运行
4. 默认候选尽量控制在 `<= 2B` 级别；`1.7B` 视作上限试探
5. 不把 `4B+` 级方案写进底线机器主线

## 5. 候选逐项判断

### 5.1 `Qwen3.5-0.8B`

官方来源：

- [Qwen3.5 官方模型仓库](https://github.com/QwenLM/Qwen3.6)
- [Qwen/Qwen3.5-0.8B](https://huggingface.co/Qwen/Qwen3.5-0.8B)

官方信号：

- 官方 Hugging Face 模型卡明确给出 `0.8B` 规格
- 官方模型卡明确写了：`Qwen3.5-0.8B` 默认运行在 `non-thinking mode`
- 官方模型卡明确给出 `201 languages and dialects`
- 官方 quickstart 明确支持 OpenAI-compatible API 与 `Transformers / vLLM / SGLang`

为什么适合 SpeakDock：

- `0.8B` 是当前最新 Qwen 线里最接近“保守、低成本、词级纠错”的尺寸
- 默认 `non-thinking` 很重要，因为这层不能出现 `<think>` 或长 reasoning 输出
- 中文与多语言信号明显强于 `Llama 3.2`

结论：

- `primary shortlist`
- 当前最值得先测的 `ASR Post-Correction` 候选

### 5.2 `Qwen3.5-2B`

官方来源：

- [Qwen3.5 官方模型仓库](https://github.com/QwenLM/Qwen3.6)
- [Qwen/Qwen3.5-2B](https://huggingface.co/Qwen/Qwen3.5-2B)

官方信号：

- 官方 Hugging Face 模型卡明确给出 `2B` 规格
- 官方模型卡明确写了：`Qwen3.5-2B` 默认运行在 `non-thinking mode`
- 官方模型卡明确支持 OpenAI-compatible API，并给出 `Transformers / vLLM / SGLang` 的标准启动方式
- 官方 quickstart 提供 `--language-model-only` 路径，说明可以跳过视觉编码器只跑语言部分

为什么适合 SpeakDock：

- 它是合理的“上限试探”
- 如果 `0.8B` 词准不够，`2B` 是不把复杂度拉到 `4B` 的上探路线
- 仍然沿用同一模型家族，减少 prompt 与行为差异

结论：

- `shortlist`
- 角色：`upper bound candidate`

### 5.3 `Gemma 3 1B`

官方来源：

- [Gemma 3 model overview](https://ai.google.dev/gemma/docs/core)
- [Gemma 3 model card](https://ai.google.dev/gemma/docs/core/model_card_3)
- [MLX-LM](https://github.com/ml-explore/mlx-lm)

官方信号：

- Google 官方明确写了：`Gemma 3 270M` 和 `1B` 是 text-only
- 官方给出 `1B` 版本的 `32K` context
- 官方给出 `140+` 语言支持
- 官方文档还给出了大致内存表，`1B` 是小设备可用尺寸

为什么适合 SpeakDock：

- 对第二轮而言，`1B` 比 `4B` 更符合底线机器
- text-only 很重要，这比 `Gemma 3n` 这种多模态形态更贴 `ASR Post-Correction`

保留意见：

- Google 官方文档对中文优先程度的表达不如 Qwen 明确
- 官方没有像 Qwen 一样直接把 Apple Silicon/MLX 作为主叙事写出来

结论：

- `shortlist`
- 角色：`alternate candidate`

### 5.4 `Gemma 3n E2B`

官方来源：

- [Gemma 3n overview](https://ai.google.dev/gemma/docs/gemma-3n)
- [Gemma 3n model card](https://ai.google.dev/gemma/docs/gemma-3n/model_card)

官方信号：

- Google 官方明确把它定位为低资源设备模型
- 官方给出 `E2B / E4B`
- 官方同时明确说明：`E2B` 的“有效参数”低于总参数，标准执行时仍会加载明显更多参数
- 官方形态是 text + image + audio -> text

为什么不进第一主 shortlist：

- SpeakDock 当前这层是 text -> text
- `Gemma 3n` 的多模态和 effective parameter 机制很有意思，但会引入额外复杂度
- 对“保守词级纠错”这个很窄的任务来说，它没有明显比 `Qwen3.5-0.8B` 或 `Gemma 3 1B` 更顺

结论：

- `watchlist`
- 先不作为第一批主候选

### 5.5 `Llama 3.2 1B`

官方来源：

- [meta-llama/Llama-3.2-1B-Instruct](https://huggingface.co/meta-llama/Llama-3.2-1B-Instruct)
- [MLX-LM](https://github.com/ml-explore/mlx-lm)

官方信号：

- Meta 官方给出 `1B` 规格与 `128K` context
- 官方支持语言列表不包含中文

为什么不适合 SpeakDock 主线：

- 中文不是官方支持重点
- 即便参数规模合适，也不匹配“中文优先 + 中英混输”的产品定位

结论：

- `benchmark only`

### 5.6 `Phi-4-mini-instruct`

官方来源：

- [microsoft/Phi-4-mini-instruct](https://huggingface.co/microsoft/Phi-4-mini-instruct)

官方信号：

- Microsoft 官方明确写了：
  - `3.8B` 参数
  - 面向 memory/compute constrained 与 latency-bound scenarios
  - 支持中文等多语言

为什么当前不进主线：

- `3.8B` 对底线机器已经太接近 `4B` 级别
- 它更像泛用 reasoning 小模型，不像专门为“保守词级纠错”准备
- 在当前硬件边界下，复杂度收益比不合适

结论：

- `pass`
- 如果未来底线机器上浮，可以再看

## 6. 第二轮 `ASR Post-Correction` 结论

最小候选集：

- `Qwen3.5-0.8B`
- `Qwen3.5-2B`
- `Gemma 3 1B`

观察名单：

- `Gemma 3n E2B`

只做对照：

- `Llama 3.2 1B`

当前直接 `pass`：

- `Phi-4-mini-instruct`
- 所有 `4B+` 默认本地路线

## 7. 云端 `Workspace Refine` 的默认 provider 契约

### 7.1 当前实现已经固定了什么

当前仓库已经固定这些事实：

- 契约形态：OpenAI-compatible `POST /chat/completions`
- 配置形态：`baseURL + apiKey + model`
- 当前请求：`system + user messages + temperature = 0`
- `manual refine` 失败时：回退到 `clean text`
- `submit refine` 失败时：回退到 `current workspace text` 并继续发送

### 7.2 为什么当前不改成 vendor-specific 契约

官方来源：

- [OpenAI Chat API](https://platform.openai.com/docs/api-reference/chat)
- [OpenAI Responses API](https://platform.openai.com/docs/api-reference/responses)

OpenAI 官方文档明确写了：

- `Chat Completions` 仍然是正式接口
- 对 OpenAI 自己的新项目，官方更推荐 `Responses`

但对 SpeakDock 当前默认路线来说，更重要的是：

- 当前实现已经建立在 OpenAI-compatible `chat/completions`
- 这条契约天然支持 `baseURL` 自定义
- 如果现在切到 `Responses`，会更靠近某一家厂商的专有能力，而不是更 vendor-neutral

结论：

- 当前默认 provider 契约继续保持 `OpenAI-compatible chat/completions`
- 未来如果要给某一家 provider 做 first-class adapter，可以单独加，不在这一轮抢主线

### 7.3 第二轮应写死的云端 `Refine` 要求

必须满足：

1. 支持 OpenAI-compatible `chat/completions`
2. 支持用户自定义 `baseURL / apiKey / model`
3. 能稳定处理中文与中英混输
4. 默认 deterministic，避免输出解释、标题、markdown 包裹
5. 请求失败时不能阻塞发送
6. 必须保留日志与错误码观测入口

### 7.4 当前最大的真实问题

当前不是 provider 契约不够，而是 prompt 语义漂移：

- `ConservativeRefinePrompt` 现在更像“保守纠错”
- 但产品定义里的 `Workspace Refine` 已经是“工作区整理”

所以第二轮之后，真正该推进的不是先换 provider，而是：

1. 重写 `Refine` prompt 语义
2. 保持当前 fallback 语义不动
3. 再做 provider smoke

## 8. 第二轮研究结论

截至 2026-04-21，这一轮应收口成下面的判断：

- `ASR` 主线与 `ASR Post-Correction` 主线必须拆开
- 当前可明确验证的开源专用 `ASR` 线是 `Qwen3-ASR`，不是一个已公开的 `Qwen3.5-ASR`
- `Qwen3.5-Omni` 是更大的全模态模型线，更接近 API / 全模态交互能力，不是底线机器上的默认本地路线
- 本地 `ASR Post-Correction` 的官方语义基线仍优先看 `Qwen3.5-0.8B`
- 如果社区优化版在语义上不明显退化，更小的 `MLX / OptiQ / GGUF` 运行版更适合争取实际落地资格
- `Gemma 3 1B` 作为结构更简单的替代候选
- `Gemma 3n E2B` 留在观察名单，不先进第一批
- `Workspace Refine` 不需要重新争论本地路线，默认就是云端
- 云端 `Refine` 当前真正需要修的是 prompt 语义，不是 provider 契约

## 9. 下一步建议

1. 先写 `ASR Post-Correction` 的最小实测设计
2. 只围绕 `Qwen3.5-0.8B / Qwen3.5-2B / Gemma 3 1B` 做第一批准备
3. 在不换 provider 的前提下，先补一版真正的 `Workspace Refine` prompt 定义
4. 保持当前 `submit refine fallback -> current workspace text` 不变
