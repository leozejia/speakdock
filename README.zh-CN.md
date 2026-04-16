# SpeakDock

SpeakDock 是一个不止会打字的 macOS AI 语音输入法。

你说话，它把内容写进当前光标。热路径先走确定性的 `Clean`，保证稳定；你需要进一步整理时，再显式打开模型 `Refine` 对整个 workspace 做保守整理。你只是想先记下来，它会把这段想法保存成本地 Markdown，并把它变成后续进入本地知识库和 LLM Wiki 的入口。

长期目标是做一个会写、会学会正确词汇、会整理、也会记住的语音层，同时把事实源留在你的机器上。

[English](README.md)

## 为什么做

大多数听写工具停在文本输入这一步。这个能力有用，但它没有解决更难的问题：很多语音输入本来就属于一个正在进行的项目、对话、决策或研究线索。

SpeakDock 把语音看成一条本地工作记忆链路的入口：

- `Compose`：当前有安全可编辑目标时，把话写进光标所在位置。
- `Capture`：没有文本目标时，把话保存成本地 Markdown。
- `Wiki`：在后台把值得保留的内容编译成长期知识。

Wiki 方向吸收了 Andrej Karpathy 的 [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) 方法：不要让模型在每次查询时重新从原始文件里找知识，而是让它长期维护一组持续演化的 Markdown wiki 页面。

## 产品方向

SpeakDock 的目标不止是语音转文字。更准确的产品方向，是做一个靠近用户工作现场的小型语音层：

- 在聊天框和文档里快速回复。
- 把不适合写进当前 app 的想法收入本地语音 inbox。
- 做保守清洗，尽量不改写用户原意。
- 支持可撤回编辑和短暂 undo 窗口。
- 在后台把内容编译成 Markdown 知识页。
- 先把 Apple 平台工作流跑顺，其中 macOS 是第一阶段主战场。

本地优先在这里很重要。真正的事实源应该留在用户自己的机器上，落在普通文件里。云端模型可以作为 workspace 整理增强，但不应该定义默认热路径。后续更理想的方向，是让端侧小模型承担大部分清洗、分类和结构化抽取任务，大模型保持可选。

硬件触发也是设计的一部分，但它不是产品前提。像 DJI 麦克风按钮这样的设备，应该只是 `TriggerAdapter` 的一种实现，和键盘、iPhone 动作、快捷指令、小组件或后续硬件并列。上层产品语义不应该被某一个硬件绑定。

## 差异点

大多数 AI 听写产品主打的是在任何 app 里产出漂亮文本。这个切入点很强，SpeakDock 也应该先从这里成立，但它不应该只和别人拼转写润色。

更锋利的方向是本地记忆：

- 已经知道要写到哪里时，直接作为 AI 语音输入法写入。
- 想法还没有目标位置时，先保存成本地 Markdown。
- 模型清洗保持保守，不做不可控重写。
- 后续 Wiki compiler 把保存下来的内容编译成页面、链接、日志和项目记忆。
- 触发源可替换，包括硬件，但产品不绑定某一个设备。

这样 SpeakDock 更像一个语音原生的个人知识工作流，而不只是键盘替代品。

## 当前状态

SpeakDock 现在处于早期 macOS 实现阶段。第一阶段目标是把热路径跑稳：说话、转写、写入或保存，并且在出错时可恢复。

现在已经支持：

- menu bar 应用形态，Dock 图标默认可见。
- 按住 `Fn` 说话，松开结束，双击提交。
- Apple Speech 流式识别，默认语言为 `zh-CN`。
- 语言选项覆盖 `en-US`、`zh-CN`、`zh-TW`、`ja-JP`、`ko-KR`。
- 通过剪贴板粘贴执行 Compose，并临时切换 ASCII 输入源。
- Capture 到本地 Markdown，文件名为 `speakdock-YYYYMMDD-HHMMSS.md`。
- 轻量 overlay，显示 listening、thinking、refining、转写预览和音频电平。
- 确定性的 `Clean`、本地 `Term Dictionary`，以及可选的 OpenAI 兼容 workspace 级 `Refine`。
- 在“可读回文本”的目标里支持保守的被动词级学习，重复且稳定的修正会晋升进本地 active 词典。
- 最近一次写入撤回和 refine 撤回。
- 第三方输入框兼容性诊断。
- Settings 已覆盖 trigger、capture 根目录、本地词典和 refine 配置。
- 基于 `OSLog.Logger` 的 Apple Unified Logging。

还没有交付：

- 正式打包和签名的公开版本。
- 本地 ASR 模型路径。
- 端侧小模型清洗或抽取引擎。
- 后台 Wiki compiler 和 schema 工作流。
- DJI 或其他硬件 trigger adapter。
- iOS 触发或 capture 入口。

## 从源码运行

要求：

- macOS 14 或更高版本。
- Xcode Command Line Tools，或兼容 Swift Package Manager 的 Swift 工具链。
- 麦克风、Speech Recognition 和 Accessibility 权限。

构建并运行：

```bash
make build
make run
```

运行测试：

```bash
make test
```

查看最近日志：

```bash
make logs
make logs LOG_WINDOW=2h
```

查看最近的交互 trace 原始行：

```bash
make traces
make traces TRACE_WINDOW=5m
```

本地汇总最近 trace 的结果分布和延迟：

```bash
make trace-report
make trace-report TRACE_WINDOW=20m
```

不录音、不注入文本，只探测 Compose 兼容性：

```bash
make probe-compose PROBE_SECONDS=30
make logs LOG_WINDOW=2m
```

运行本地自动化 Compose smoke 基线，目标是 SpeakDock 自带测试宿主：

```bash
make smoke-compose
make trace-report TRACE_WINDOW=5m
make traces TRACE_WINDOW=5m
```

运行本地自动化 Refine smoke 基线，命令会临时拉起一个本地 stub server：

```bash
make smoke-refine
make trace-report TRACE_WINDOW=5m
make traces TRACE_WINDOW=5m
```

运行本地自动化词典被动学习 smoke 基线，命令会使用隔离的临时词典：

```bash
make smoke-term-learning
make trace-report TRACE_WINDOW=5m
make traces TRACE_WINDOW=5m
```

## 权限

SpeakDock 只请求当前路径需要的 macOS 权限：

- 麦克风用于录音，并驱动音频电平 overlay。
- Speech Recognition 通过 Apple Speech 生成流式文本和最终文本。
- Accessibility 用于监听默认 `Fn` trigger，并检查或恢复 Compose 的当前文本目标。
- Input Monitoring 当前实现不需要。只有后续更换 trigger 实现时才可能需要。

如果 Accessibility 看起来已经打开，但 `Fn` 仍显示不可用，先在系统设置里删除旧的 SpeakDock 授权项，重新添加当前 `.build/debug/SpeakDock.app`，再启动应用。

## 开发模型

公开 `main` 分支应该保持干净稳定：源码、构建说明、许可证和面向外部的项目说明。

详细架构、执行日志和研究文档不放进公开分支。它们负责指导开发，但公开 README 只在产品方向、启动流程或许可证发生变化时更新。

## 许可证

SpeakDock 使用 Apache License 2.0。见 [LICENSE](LICENSE)。
