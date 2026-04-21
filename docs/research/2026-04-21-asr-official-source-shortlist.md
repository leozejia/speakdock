# 端侧 ASR 官方资料调研与 shortlist 提纲

状态：研究提纲，只基于官方/一手资料，不自动升级为架构承诺。最终产品真值仍以 `docs/technical/ARCHITECTURE.md` 为准。

日期：2026-04-21

## 1. 调研边界

本页只回答一个问题：在 `Apple Silicon M3 / 16GB / macOS 15.7.4` 上，哪些官方可查的 ASR 候选值得进入 SpeakDock 的本地语音输入 shortlist。

只使用以下来源：

- 官方 repo
- 官方技术报告 / 论文
- 官方模型卡
- 官方框架文档

本页不做：

- 二手博客综述
- 社区 benchmark 转述
- 未在官方资料出现的 Apple Silicon 跑分结论
- `ASR Post-Correction` 或 `Workspace Refine` 的模型结论

## 2. 先给结论

当前建议分层如下：

- 必留基线：`Apple Speech`
- 强 shortlist：`Qwen3-ASR-0.6B`、`SenseVoice`
- 对照 shortlist：`Whisper`
- 观察名单：`Moonshine`

原因不是“谁名气大”，而是四个维度一起看：

- 中文语音输入是否有官方正面证据
- 是否有实时/低时延官方叙事
- 是否有足够明确的本地部署官方材料
- 对 `M3 / 16GB / macOS 15.7.4` 是否存在明显资料缺口

## 3. 候选逐项判断

### 3.1 Apple Speech

#### 官方来源

- Apple Speech 框架总览：<https://developer.apple.com/documentation/speech/>
- `SFSpeechRecognitionRequest`：<https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest>
- `supportsOnDeviceRecognition`：<https://developer.apple.com/documentation/Speech/SFSpeechRecognizer/supportsOnDeviceRecognition>
- `supportedLocales()`：<https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportedlocales%28%29>
- `contextualStrings`：<https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/contextualstrings>
- `shouldReportPartialResults`：<https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/shouldreportpartialresults>

#### 官方资料能确认什么

- Apple 官方明确提供 live audio 识别、partial results、on-device 开关、supported locales、以及 `contextualStrings` 这类轻量词汇提示能力。
- 官方文档也明确写了：不是所有 locale 都保证离线；只有 `supportsOnDeviceRecognition == true` 时，请求才能真正强制留在设备侧。
- 对 SpeakDock 现阶段最有价值的是：这是当前唯一零下载、零外部 runtime、与 macOS 权限和系统输入法体验最贴合的基线。

#### 擅长什么

- 系统集成最强，接入成本最低。
- partial results 和 live dictation 体验天然适合“按住说话”的热路径。
- `contextualStrings` 适合做轻量术语增强，不需要先引入独立模型系统。

#### 不擅长什么

- 官方没有公开模型卡、参数量、中文 benchmark、延迟 benchmark，也没有给出可控的底层推理细节。
- locale 的离线支持是条件式的，不是统一保证。
- 定制空间有限，公开文档层面更像“系统能力调用”，不是可深度调优的本地模型栈。

#### 对中文实时语音输入是否值得进 shortlist

- 值得，而且必须保留。
- 它不一定是最终准确率最强者，但它是 SpeakDock 的系统基线，也是 streaming preview 最稳的保底路径。

#### 资料缺口

- Apple 没公开中文准确率、模型结构、实际本机内存/热量数据。
- 仅凭官方文档，无法把它当成“长期唯一方案”，只能当系统基线。

### 3.2 Qwen3-ASR-0.6B

#### 官方来源

- 官方 repo：<https://github.com/QwenLM/Qwen3-ASR>
- 官方技术报告：<https://arxiv.org/abs/2601.21337>
- 官方模型卡：<https://huggingface.co/Qwen/Qwen3-ASR-0.6B>

#### 官方资料能确认什么

- 官方技术报告明确说，`Qwen3-ASR-0.6B` 支持 `52` 种语言和方言，`0.6B` 版本主打 accuracy/efficiency trade-off，并给出平均 `TTFT` 最低 `92ms` 的说法。
- 官方 repo / 模型卡明确给出：支持中文、英语、粤语及多种中文方言；同一模型支持 offline / streaming；支持长音频；带完整推理工具链。
- 官方 repo 还明确写了：streaming inference 当前只在 `vLLM backend` 提供。

#### 擅长什么

- 官方中文能力叙事最强，且不只是普通话，还覆盖粤语和多种中文方言。
- 官方直接把它定位成开源 ASR 里的高性能候选，不是“顺带能听语音”的多模态副产品。
- 统一 offline / streaming 的单模型叙事，对 SpeakDock 这种热路径产品很有吸引力。

#### 不擅长什么

- 官方资料里没有 Apple Silicon / macOS / MPS 的原生落地说明。
- 官方 quickstart 和 demo 主要围绕 `cuda:0`、`vLLM`、FlashAttention 展开，说明官方主路径仍然是 NVIDIA 生态。
- 也就是说，模型本身强，不等于官方已经给出适合 `M3 / 16GB / macOS 15.7.4` 的标准落地方案。

#### 对中文实时语音输入是否值得进 shortlist

- 值得，而且应该进入强 shortlist。
- 但结论必须写完整：它是“强候选”，不是“已锁定实现”。
- 下一轮必须验证的不是“它强不强”，而是“官方未给 Apple Silicon 路径的前提下，我们能否把它稳定落在本机热路径里”。

#### 资料缺口

- 官方来源没有提供 macOS / Apple Silicon 原生推理方案。
- 官方来源没有提供 `M3 / 16GB` 内存、温度、首句启动行为的证据。

### 3.3 Whisper

#### 官方来源

- OpenAI 官方 repo：<https://github.com/openai/whisper>
- 官方论文：<https://arxiv.org/abs/2212.04356>
- 官方模型卡：<https://github.com/openai/whisper/blob/main/model-card.md>

#### 官方资料能确认什么

- 官方论文明确说，Whisper 基于 `680,000` 小时多语言多任务弱监督数据训练。
- 官方 repo / 模型卡明确给出多个尺寸，从 `39M` 到 `1.55B`，并公开了模型内存需求和多语言路径。
- 官方模型卡也明确写了几个关键边界：不同语言表现差异大、会 hallucination、会重复生成、并且“不能开箱即用地做 real-time transcription”。

#### 擅长什么

- 官方资料最完整，模型尺寸梯度清楚，开放性最好，MIT 许可也简单。
- 作为对照组极强，因为它是最成熟的开源 ASR 基线之一。
- `tiny / base / small / medium / large / turbo` 这条尺寸梯度，很适合拿来做性能与准确率对照。

#### 不擅长什么

- 官方自己已经说明不适合开箱即用实时转写。
- 官方模型卡也明确承认不同语言表现不均、低资源语言更弱、并存在 hallucination 和 repetitive text 风险。
- repo 里的实现是“读完整文件，再做滑窗 autoregressive 解码”的思路，本质上不是为 SpeakDock 这种低延迟热路径定制的。

#### 对中文实时语音输入是否值得进 shortlist

- 值得进，但定位应该是“对照 shortlist”，不是首选产品候选。
- 它非常适合做 baseline benchmark，用来判断新候选是否真的比成熟开源方案更值。
- 但如果目标是“中文实时语音输入”本身，Whisper 从官方资料看并不是最贴合的产品首选。

#### 资料缺口

- 官方没有给 Apple Silicon 官方性能数据。
- 官方没有给出专门针对中文实时输入场景的产品化建议。

### 3.4 SenseVoice

#### 官方来源

- 官方 repo：<https://github.com/FunAudioLLM/SenseVoice>
- 官方模型卡：<https://huggingface.co/FunAudioLLM/SenseVoiceSmall>
- 官方运行时/模型库入口：<https://github.com/modelscope/FunASR>

#### 官方资料能确认什么

- 官方 repo / 模型卡明确把 SenseVoice 定位为 speech foundation model，不只是 ASR，还含 LID、SER、AED。
- 官方 repo 明确给出两个对 SpeakDock 很关键的点：`non-autoregressive` 端到端结构，以及“`10` 秒音频只需 `70ms`”的低时延叙事。
- 官方 repo 还明确写了：在 Chinese 和 Cantonese benchmark 上，SenseVoice-Small 相对 Whisper 有优势。
- 官方 repo / 模型卡同时确认已提供 `ONNX` 与 `libtorch` 导出。

#### 擅长什么

- 中文和粤语是它官方材料里少数被直接强调优势的场景，这一点很贴 SpeakDock。
- 非自回归路线天然更像实时输入产品要的方向。
- 官方已经提供 ONNX / libtorch 出口，比只给 Python demo 更接近可集成状态。

#### 不擅长什么

- 官方口径存在不一致：repo / 模型卡说“50+ languages”，但官方 FunASR 模型库里对 `SenseVoiceSmall` 的明确语言列举是 `zh / yue / en / ja / ko`，并给出 `234M` 参数与 `300000 hours` 训练数据。
- 官方没有找到单独的技术报告来解释它在中文实时输入上的误差边界和训练细节。
- 官方示例同样偏 `cuda:0`，没有明确的 macOS / Apple Silicon 原生落地说明。

#### 对中文实时语音输入是否值得进 shortlist

- 值得，而且应进入强 shortlist。
- 它是当前官方资料里少数同时满足“中文导向 + 低时延叙事 + 有 ONNX/libtorch 出口”的候选。
- 但要在文档里明确：它的语言覆盖、部署路径和最终 Mac 侧落地体验，还需要下一轮实测来收口。

#### 资料缺口

- 缺少独立技术报告。
- 缺少 Apple Silicon 官方部署文档。
- 官方语言覆盖口径不完全一致，写入综合 research doc 时必须原样标注这个差异。

### 3.5 Moonshine

#### 官方来源

- 官方 repo：<https://github.com/moonshine-ai/moonshine>
- 官方站点：<https://moonshine.ai/>
- 官方论文 `Moonshine: Speech Recognition for Live Transcription and Voice Commands`：<https://arxiv.org/abs/2410.15608>
- 官方论文 `Flavors of Moonshine: Tiny Specialized ASR Models for Edge Devices`：<https://arxiv.org/abs/2509.02523>

#### 官方资料能确认什么

- 官方 repo 和论文都把 Moonshine 明确定位为 live transcription / edge device / low latency 路线。
- 官方 repo 明确写了：支持 Python、iOS、Android、macOS，并且 macOS 同时支持 Apple Silicon 和 Intel。
- 官方 repo 还给出了一组非常产品化的延迟叙事，例如在 `MacBook Pro` 上对比 Whisper 的流式延迟表。
- 官方 repo 也明确列出了 Mandarin 支持，并给出 Mandarin Base 的 `CER 25.76%`。

#### 擅长什么

- 官方对 Apple 平台支持最直接，甚至直接提供 Swift / macOS 入口。
- 官方产品叙事和 SpeakDock 很接近，都是 live voice interface。
- 如果未来优先级从“准确率第一”转向“超低延迟、超轻量、极易集成”，Moonshine 会很有吸引力。

#### 不擅长什么

- 官方中文材料仍然偏薄。虽然明确支持 Mandarin，但没有像 SenseVoice / Qwen 那样给出更强的中文主场论证。
- 官方 repo 当前对非英语模型的许可写法很敏感：代码 MIT，但非英语模型走 `Moonshine Community License`，并明确说是 non-commercial。
- 官方论文 `Flavors of Moonshine` 又提到中文等模型以 permissive open-source license 发布，这与当前 repo 许可口径存在冲突。

#### 对中文实时语音输入是否值得进 shortlist

- 现阶段不建议进主 shortlist，保留在观察名单。
- 原因不是它不适合 edge，而是当前官方资料对中文商业化使用边界和中文主场能力都不够稳。
- 如果后续 license 口径澄清，或者我们转向“极致低延迟优先”的轻量方案，Moonshine 可以重新进入 shortlist 讨论。

#### 资料缺口

- 中文能力的官方证据仍偏薄，尤其缺少与 Qwen / SenseVoice 同量级的中文主场叙事。
- 当前官方资料对非英语模型授权存在口径冲突，必须在真正进入评测前先澄清。

## 4. 对 SpeakDock 的直接含义

### 4.1 哪些候选值得先测

- `Apple Speech`：必须测，作为系统基线
- `Qwen3-ASR-0.6B`：必须测，作为高优先级潜在主力候选
- `SenseVoice`：必须测，作为中文低时延候选
- `Whisper`：必须测，但主要承担对照组角色

### 4.2 哪些候选先不进入主线

- `Moonshine`：先不进入主线测评名单，保留观察

原因：

- 官方中文证据不够强
- 非英语模型授权口径存在风险
- 虽然 Apple 平台集成友好，但对 SpeakDock 当前“中文实时输入 + 准确率优先”的目标还不够稳

## 5. 下一轮评测应该回答什么

基于本页，下一轮不是继续搜资料，而是进入实测设计：

- `Apple Speech vs Qwen3-ASR-0.6B vs SenseVoice vs Whisper` 在中文短句、长句、中英混说、术语、聊天输入上的真实表现
- 首句启动延迟、连续说话稳定性、CPU/GPU/内存、热量
- streaming preview 与 final transcript 是否需要双轨
- `M3 / 16GB / macOS 15.7.4` 上是否存在不可接受的 runtime 复杂度

## 6. 可直接写入综合 research doc 的一句话结论

- `Apple Speech`：保留为系统基线和 streaming preview 保底路径，但官方透明度不足，不适合作为长期唯一方案。
- `Qwen3-ASR-0.6B`：官方中文与低延迟叙事最强，值得进强 shortlist；但官方未给 Apple Silicon 落地路径，不能提前锁定实现。
- `Whisper`：适合作为成熟开源对照组，不适合作为中文实时输入的一号产品候选。
- `SenseVoice`：中文/粤语与低时延叙事很强，值得进强 shortlist；但官方技术资料完整度不如 Qwen / Whisper，且部署口径仍需实测验证。
- `Moonshine`：Apple 平台集成最友好，但中文证据与授权口径都不够稳，先放观察名单。
