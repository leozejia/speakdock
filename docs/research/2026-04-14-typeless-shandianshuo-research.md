# Typeless / 闪电说竞品研究

日期：2026-04-14

## 1. 结论

Typeless 和闪电说都把入口说得很清楚：AI 语音输入法不是“把声音转成字”，而是把自然口语变成可直接使用的结果。

Typeless 的强项是把语音输入包装成新的键盘：跨 app、跨平台、实时润色、个人语气、个人词典、选中文本后继续用语音编辑或提问。

闪电说的强项是把语音输入往语音助手推进：语音 × 技能、屏幕感知、本地记忆、自定义技能、自定义 AI 服务商、本地和云端识别模型可配置。

SpeakDock 应该吸收它们的入口和交互优势，但不要只跟着做“漂亮文本”。我们的差异点应该是：

- `AI 语音输入法` 是第一入口。
- `本地 Markdown Capture` 是第二入口。
- `端侧小模型的保守整理` 是默认方向。
- `LLM Wiki` 是长期知识层。
- `TriggerAdapter` 让键盘、iPhone、DJI 或其他硬件都只是输入源，不绑定产品语义。

一句话定位可以更直接：

> SpeakDock 是一个会写、会改、会整理、也会记住的 AI 语音输入法。

## 2. Typeless 观察

Typeless 官网主钩子是“Speak, don't type”，核心承诺是自然说话后，在任何工作 app 里生成像手写过一样的 polished text，并强调比键盘更快。它把产品放在“voice keyboard”心智里，而不是笔记或知识管理。

公开页面里值得吸收的点：

- 跨 app 输入：Typeless 明确强调在 Mac、Windows、iOS、Android 上的各种 app 中写作。
- 自动清理口语：去 filler、去重复、识别用户中途改口、自动格式化列表和步骤。
- 个性化：学习用户语气、措辞和写作习惯，并维护个人词典。
- 多语言：强调 100+ 语言和混合语言输入。
- 选中文本后的语音命令：选中一段文字，按热键，说“改得更专业”“翻译”“变短”等，直接替换或回答。
- 读写合一：不仅能写，还能对选中文本做摘要、解释、翻译、行动项提取。
- Web Search + Markdown：在需要最新信息或格式化时，可以触发搜索和 Markdown 输出。
- 隐私叙事：零云端留存、不用用户数据训练、历史保存在设备上。

Typeless 的强产品路径：

1. 先让用户相信它是更好的键盘。
2. 再让用户相信它是随手可用的写作助手。
3. 最后把选中文本、搜索、翻译、摘要等能力接进同一套热键交互。

对 SpeakDock 的启发：

- README 开头必须先让人知道这是 AI 语音输入法，而不是抽象的 workflow。
- `Refine` 不能只藏在设置里，后续需要变成用户可感知的“语音修改当前文本”。
- `PersonalDictionary` 和 `StyleProfile` 应该进入架构计划，分别处理术语准确性和语气一致性。
- “选中文本 -> 按住触发 -> 说命令 -> 替换或生成结果”可以作为 `Compose` 的下一阶段，不需要等 Wiki 层。

## 3. 闪电说观察

闪电说官网主钩子是“语音 × 技能”和“一句话，执行技能”，它没有停在语音输入法，而是说自己是语音助手。

公开页面里值得吸收的点：

- 长按唤醒：按住快捷键唤醒语音助手。
- AI 理解上下文：公开页强调屏幕感知和本地记忆。
- 自动填入：生成结果后写回当前上下文。
- 语音输入：支持本地和云端语音识别模型，可自由配置。
- 结构化和口语过滤：把口语转成文章式输出。
- 帮我回复：读屏理解上下文，结合个人记忆，生成符合用户习惯的回复。
- 语音修改：支持选中文字或直接口述，修改语气、精简内容等。
- 自定义技能：用户定义技能名称和行为，连接自己的工作流。
- 自定义 AI 服务商：支持多个服务商，用户选择自己的 AI 引擎。
- 隐私叙事：数据由用户掌控，本地处理或直达 AI 服务商。

第三方收录页还把闪电说描述为端侧优先、本地高性能语音识别、语义纠错、全场景输入、多语言和方言、设备端保存数据。但这一部分不是官方页面，应作为低可信度补充，不能直接当成产品事实写进公开文案。

闪电说的强产品路径：

1. 先占住 AI 语音输入法。
2. 再扩展成语音助手。
3. 用屏幕感知、本地记忆、自定义技能把“语音”变成“执行”。

对 SpeakDock 的启发：

- `Skill` 可以成为 `Refine / Capture / Wiki` 之上的用户可见层，但不能一开始做成开放 Agent。
- 第一批技能应保持窄：帮我回复、改语气、变短、变正式、提取待办、保存到 inbox、整理成项目日志。
- 屏幕感知必须通过权限和可见提示做边界，不能默认悄悄读屏。
- 本地记忆应优先基于 SpeakDock 自己写下来的 Markdown 和 Wiki，而不是一开始抓全屏历史。
- 自定义服务商可以沿用现有 OpenAI-compatible 配置，再补 provider preset。

## 4. SpeakDock 应该吸收什么

### 4.1 立刻吸收：公开定位

公开叙事应该从“AI 语音输入法”开始。用户先理解“我可以在任何地方说话输入”，再理解“SpeakDock 可以整理”，最后理解“它能把留下来的内容变成知识库”。

建议公开层级：

1. AI 语音输入法。
2. 模型矫正和整理。
3. 本地 Markdown Capture。
4. LLM Wiki。
5. 硬件和多端 TriggerAdapter。

### 4.2 近期吸收：语音修改当前文本

Typeless 和闪电说都证明了“选中文本 + 语音命令”是很强的第二交互。

SpeakDock 可以映射成：

- `ComposeSelectionTarget`
- `VoiceCommandIntent`
- `RefineInstruction`
- `ReplaceSelectedText`
- `UndoWindow`

最小闭环：

1. 用户选中一段文字。
2. 按住 `Fn`。
3. 说“变短一点”“改正式一点”“提取待办”。
4. SpeakDock 调用 refine。
5. 替换选中文本。
6. 进入撤回窗口。

### 4.3 近期吸收：个人词典

当前 Apple Speech 的识别精度有限，个人词典是最直接的补洞手段。

建议分两层：

- `TermDictionary`：产品名、人名、技术词、项目名，做 ASR 后处理和 refine 提示。
- `StyleProfile`：用户常用表达、语气偏好、常见输出格式，只给 refine 使用，不污染 raw capture。

这两层都应该本地保存，并允许用户导出。

### 4.4 中期吸收：技能

技能不应一开始做成开放 Agent。开放 Agent 会带来权限、延迟、不可预测和安全问题。

建议第一阶段技能是固定模板：

- `帮我回复`
- `改正式一点`
- `变短`
- `变成待办`
- `保存到 inbox`
- `整理成会议记录`
- `追加到项目日志`

每个技能都应该声明：

- 输入来源：当前光标、选中文本、当前 capture、屏幕上下文、wiki 页面。
- 输出目标：替换、插入、capture、wiki draft。
- 权限需求：Accessibility、Screen Recording、文件访问、网络 refine。
- 撤回方式：替换回滚、文件尾部回滚、wiki draft 删除。

### 4.5 中期吸收：屏幕上下文

闪电说的“屏幕感知 + 本地记忆”很强，但也是高风险能力。

SpeakDock 应该更保守：

- 默认只读当前 AX focused element 和必要的窗口/app 元数据。
- 若需要截图或全屏 OCR，必须单独开关、单独权限、明显提示。
- 屏幕上下文只进入当前技能，不默认写入长期记忆。
- 可保存的上下文必须先落到 `Capture` 或 `raw/`，再由 Wiki compiler 处理。

### 4.6 中期吸收：服务商和模型配置

闪电说强调本地和云端模型可配置，Typeless强调线上处理和设备端历史。SpeakDock 已经有 OpenAI-compatible refine，可以继续扩展：

- provider preset：OpenAI-compatible、自定义 base URL、本地 server。
- model role：`asr`、`clean`、`refine`、`extract`、`wiki_compile`。
- fail-open：模型失败时不阻断热路径。
- privacy label：每个模型调用显示“本地 / 直连服务商 / 云端”。

## 5. 不应该照抄什么

- 不要承诺“所有 app 完美写入”。Compose 必须保守，不能可靠定位就直接报不可用或走用户明确的 paste-only fallback。
- 不要默认重写用户表达。SpeakDock 的默认 refine 应该先修识别错误、口头禅和结构，而不是替用户换观点。
- 不要把屏幕感知默认化。读屏、OCR、截图都应该是单独能力。
- 不要把技能做成无限制 Agent。先做固定技能和可撤回的工作流。
- 不要让 Wiki 进入热路径。Wiki 是冷路径，不能影响用户松开后的写入速度。

## 6. 推荐落地顺序

### P0：定位和文档

- 公开 README 使用“AI 语音输入法”作为入口。
- 保留 `Compose / Capture / Wiki` 三层，但不要把它放在第一句话。
- 在内部架构文档中补 `VoiceCommandIntent / Skill / TermDictionary / StyleProfile`。

### P1：输入法体验

- 保持 `Fn` 热路径稳定。
- 增加个人词典。
- 改进首次 ASR / 短音频失败诊断。
- 把 refine 从设置能力升级为用户可见的“整理当前文本”。

### P2：语音修改

- 支持选中文本后语音命令。
- 支持改语气、变短、提取待办、翻译等固定命令。
- 所有替换都进 `UndoWindow`。

### P3：技能

- 做 `帮我回复`、`保存到 inbox`、`整理成会议记录` 等固定技能。
- 给每个技能定义输入、输出、权限、撤回。
- 不开放任意 Agent 执行。

### P4：本地记忆和 Wiki

- 设计 `raw / inbox / wiki / schema` 目录。
- Capture 默认保留 raw artifact。
- Wiki compiler 后台异步处理。
- 支持项目页、人物页、主题页、日志页。

### P5：硬件和多端触发

- DJI 或其他硬件只接入 `TriggerAdapter`。
- iPhone Action Button / Shortcuts 也只接入触发层。
- 上层语义保持 `press / release / submit / skill command`。

## 7. 对现有 README 的影响

当前 README 的后半部分方向基本成立，但开头需要更像产品钩子：

- 第一行：AI 语音输入法。
- 第二段：说话写入、模型整理、Capture 成本地知识入口。
- 差异点：不是只拼 polished text，而是 local memory 和 LLM Wiki。

这个调整已经和 SpeakDock 原架构一致，也更接近用户能快速理解的入口。

## 8. 来源

- Typeless 官网：https://www.typeless.com/
- Typeless FAQ：https://www.typeless.com/help/faqs/
- Typeless Voice Superpowers release note：https://www.typeless.com/help/release-notes/macos/voice-superpowers
- Typeless v0.9.0 release note：https://www.typeless.com/help/release-notes/macos/personalized-smarter
- 闪电说官网：https://shandianshuo.cn/
- 代体升级页：https://daiti.ai/
- 攻壳智能体闪电说收录页：https://gongke.net/tools/shandianshuo
