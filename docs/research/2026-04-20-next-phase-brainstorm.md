# Next Phase Brainstorm: 双模型架构与 UX 优化方向

状态：脑爆记录，不自动升级为架构承诺。当前产品真值以 `docs/technical/ARCHITECTURE.md` 为准。

日期：2026-04-20

## 1. 背景

SpeakDock macOS v1 的核心热路径已经稳定：Fn 触发 → Apple Speech 流式 ASR → Clean → Compose/Capture → Undo Window。Term Dictionary 被动学习、Refine（OpenAI-compatible）、ASR Correction seam 均已实现。

当前的主要瓶颈：

- Apple Speech 在中英混合、专业术语场景下准确率不够
- ASR Correction 层（可选，默认关闭）需要额外模型但收益不确定
- Wiki compiler 尚未实现，Capture 产出的 raw 文件缺少知识整理层
- Overlay 实时展示在长句时截断尾部，用户看不到最新内容

本次脑爆围绕"如何让识别更准、产品更好用"展开，确定了下一阶段的架构方向。

## 2. 双模型架构

### 2.1 核心决策

系统只需要两个可配置的模型槽位：

| 槽位 | 角色 | 输入 → 输出 |
|---|---|---|
| 端侧 ASR 模型 | 语音识别 | audio buffer → text |
| LLM (Refine) | 语义重组 | text + context → polished text |

中间的 Clean normalizer + Term Dictionary 是确定性逻辑，不算模型。

### 2.2 端侧 ASR 模型选型

推荐方案：**Qwen3-ASR-0.6B**

选型依据：
- 专用 ASR 模型，0.6B 参数，180M AuT encoder + decoder
- 支持 52 种语言和方言（含中文普通话、粤语、英语、日语、韩语）
- TTFT（首 token 延迟）低至 92ms
- 准确率超过 Whisper-large-v3（多个 benchmark）
- 已有 MLX 原生适配（`mlx-qwen3-asr` PyPI 包），可直接在 Apple Silicon 本地运行
- 支持 4-bit 量化，磁盘占用约 300-400MB

备选方案：
- **Whisper**（whisper.cpp 或 MLX-Whisper）：成熟稳定，但准确率不如 Qwen3-ASR
- **Apple Speech**（零配置 fallback）：无需下载，streaming partial 支持好

### 2.3 Apple Speech 的角色重新定位

Apple Speech 不被替代，而是角色收窄：

- **保留**：作为实时 streaming partial 展示源（用户按住 Fn 时的视觉反馈）
- **保留**：作为零配置 fallback（用户未下载本地模型时兜底）
- **不再承担**：最终识别结果的准确率责任

流水线变为：
```
[按住 Fn]
  ├─ Apple Speech streaming → overlay 实时显示 partial（视觉反馈）
  ├─ Audio buffer 持续录制
[松开 Fn]
  ├─ Qwen3-ASR-0.6B via MLX（audio → final transcript）~92ms TTFT
  ├─ Clean normalizer（标点、filler、term dict）
  ├─ [可选] Refine（LLM 语义重组）
  └─ 注入光标 / 写入 capture 文件
```

### 2.4 ASR Correction 层的影响

Qwen3-ASR-0.6B 的端到端准确率已经很高，独立的 ASR Correction 层的必要性降低。当前 seam 保留但继续默认关闭，待 Qwen3-ASR 接入后根据实际错误样本重新评估是否需要。

### 2.5 Sidecar 生命周期

当前偏好：**随 app 常驻**，不做懒加载。

理由：
- 语音输入对延迟极度敏感，冷启动几秒不可接受
- 用户不是一直在说话，但说话时期望即时响应
- 常驻代价：~300-400MB 内存，对 16GB+ 机器可接受

候选集成方式：本地 FastAPI sidecar 进程，Swift 通过 localhost HTTP 调用。是否采用这条路径，要等专项评测页确认。

### 2.6 Settings UI

ASR Engine 配置区：
- Provider 选择：Apple Speech / Qwen3-ASR / Whisper
- Model path（本地模型时）
- Streaming preview toggle（是否用 Apple Speech 做实时展示）

## 3. Wiki Compiler 方案

### 3.1 从自建到外部 agent

最初设想：SpeakDock 自己调 LLM API 做 wiki 编译（读 raw 文件 → 拼 prompt → 调 API → 写 wiki 文件）。

问题：wiki 编译是多轮知识整理工作——需要自主探索、交叉引用、错误修正、复杂归类。固定的一两轮 API 调用无法达到 agent 级别的准确率。

决策：**Wiki 编译交给外部 agent（Claude Code CLI 或 Codex CLI）**。

SpeakDock 通过 `Process.launch()` 调起 agent CLI，传入 prompt 和工作目录。知识目录下的 CLAUDE.md 定义 wiki 结构、命名规范、合并策略、反向链接规则。Agent 自主完成读写。

### 3.2 可选功能

Wiki 功能作为可选模块：
- 启动时检测 `claude` 或 `codex` CLI 是否在 PATH
- 不可用时灰掉"整理知识库"入口 + 提示安装
- 与 Refine 没配 API key 时灰掉的模式一致

假设：Claude Code 和 Codex 是当前两个主流 agent，目标用户群体大概率已安装其中之一。

### 3.3 浏览器 vs Obsidian

决策：**本地 HTTP server + 浏览器**，不绑定 Obsidian。

理由：
- Obsidian 是重客户端，不是每个人都用
- Obsidian 插件生态与 SpeakDock 产品边界会打架
- 浏览器是零依赖，每个人都有
- Wiki 输出为纯 Markdown，内置轻量 HTTP server 渲染成 HTML

### 3.4 职责边界

| 层 | 负责方 |
|---|---|
| Voice → text | SpeakDock（ASR + Clean） |
| Text → polished | SpeakDock（Refine，单轮 API 调用） |
| Capture → raw/ | SpeakDock（文件写入） |
| raw/ → wiki/ | 外部 agent（Claude Code / Codex CLI） |
| wiki/ → 浏览器 | SpeakDock（本地 HTTP server） |

## 4. UX 优化方向

### 4.1 Overlay partial 展示修复

当前问题：partial transcript 从头显示，长句时尾部被截断，用户看不到最新说到的内容。

方案：始终显示最新尾部，前面内容用省略号或淡出处理。或只显示最后一个标点后的 segment。改动范围在 `OverlayView`。

优先级：高（快速 win，立刻改善体验）。

### 4.2 上下文感知 Refine

当前 Refine 只看 workspace 内容。如果把光标前后 ~200 字作为 context 传给 refine prompt，输出的语气和格式会更贴合上下文。

实现：通过 AX API（`EditableTextObservationContext`）取当前文本框内容和光标位置，截取 cursor 前 200 字作为 prompt context。零额外模型成本，只是丰富了 prompt 输入。

### 4.3 应用场景隐式适配

通过 `NSWorkspace.shared.frontmostApplication?.bundleIdentifier` 检测前台 app，自动调整 refine hint：

- 聊天类（Slack/WeChat/Telegram）→ 口语化，短句
- 文档类（Pages/Word/Notion）→ 书面化，完整标点
- 代码类（Xcode/VS Code/Terminal）→ 不加标点，保留英文原样
- 邮件类（Mail/Outlook）→ 礼貌正式

存储为 workspace 级 refine hint。用户可在 Settings 里按 app 覆盖。

关键：必须是隐式推断 + 用户可覆盖，不做手动模式切换。

### 4.4 Term Dictionary shadow 层

当前：被动观察 3 次一致才 promote。用户重复纠正同一个词时体验差。

方案：首次纠正创建临时 shadow 条目，立刻生效但不持久化。达到阈值后才正式 promote 进 TermDictionary。用户感知上"改一次就记住了"，但系统仍然保守。

### 4.5 智能断句

长段落听写时自动检测语义停顿插入换行。规则：VAD 静音 >1.5s = 新段落。纯规则驱动，不需要模型。

### 4.6 交互设计文档

当前 ARCHITECTURE.md 的 two-button interaction 是实现视角。需要一份产品视角的交互设计文档，覆盖：
- 触发方式完整矩阵（单击、长按、双击、三击、组合键）
- 每个手势在不同状态下的行为
- 未来硬件触发（AirPods、DJI mic）
- 系统快捷键冲突规避

## 5. 参考资料

- [Qwen3-ASR Technical Report (arxiv)](https://arxiv.org/html/2601.21337v1)
- [Qwen3-ASR GitHub](https://github.com/QwenLM/Qwen3-ASR)
- [mlx-qwen3-asr PyPI](https://pypi.org/project/mlx-qwen3-asr/)
- [izwi - local inference playground](https://github.com/agentem-ai/izwi)
- [Karpathy LLM Wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [LobeHub Qwen-ASR skill](https://lobehub.com/skills/stvlynn-skills-qwen-asr)

## 6. 建议优先级

1. Overlay 截断修复（快速 win）
2. Qwen3-ASR-0.6B sidecar 接入（核心价值）
3. 上下文感知 Refine
4. 应用场景隐式适配
5. Term Dictionary shadow 层
6. Wiki compiler（外部 agent 集成）
7. 智能断句
8. 交互设计文档
