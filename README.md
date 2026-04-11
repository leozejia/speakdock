# SpeakDock

SpeakDock 是一个 macOS 本地优先语音工作流系统。

当前仓库以文档和实现计划为主，macOS v1 先落地，iOS 后续复用同一套核心模型。

目标很简单：

- 用支持的硬件触发录音
- 用户自然说话
- 本地组件完成正确动作
- 结果被路由到当前光标、本地 `MD` 工作区或后台知识层

四个原则：

- 大多数请求本地完成
- 兼容 Obsidian 风格目录
- `DJI` 只是第一个试点硬件 adapter
- 严格区分即时沟通和长期沉淀

当前真相源：

- `docs/technical/ARCHITECTURE.md`

## macOS v1 关键规则

- 默认 trigger 是 `Fn`
- `Fn` 不可用时，不自动切到某个固定热键
- menu bar 必须明确显示 `Fn` 当前不可用
- 用户需要在 Settings 里显式选择替代 trigger 后才能继续
- `DJI` 或其他硬件 adapter 只覆盖输入层，不改上层产品语义

## 权限矩阵

| 权限 | 用途 | 缺失时表现 |
| --- | --- | --- |
| 麦克风 | 录音、波形、电平反馈 | 无法进入 `Listening`，悬浮层应提示麦克风不可用 |
| Speech Recognition | 流式转录、最终文本生成 | 可以开始录音，但不能产出可提交文本，热路径应直接报错 |
| Accessibility | 判定可编辑目标、执行 `Compose` 注入 | `Compose` 直接不可用；不能静默降级成 `Capture` |
| Input Monitoring（条件性） | 全局监听默认 `Fn` trigger | 默认 `Fn` 路径不可用；menu bar 必须提示异常，用户需改用显式配置的替代 trigger |

说明：

- `Input Monitoring` 是否需要，取决于最终采用的 `Fn` 监听实现
- 如果当前走外接硬件 trigger，而不是键盘 `Fn`，这项权限可以不作为前提

## Docs

- `docs/README.md`
- `docs/technical/ARCHITECTURE.md`
- `docs/plans/2026-04-10-speakdock-macos-v1-implementation.md`
- `docs/plans/2026-04-10-speakdock-macos-v1-manual-test.md`
