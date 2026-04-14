# SpeakDock

SpeakDock 是一个 macOS 本地优先语音工作流系统。当前仓库已经落地 macOS v1 参考实现，产品行为以 `docs/technical/ARCHITECTURE.md` 为准，任务顺序和收尾状态分别记录在实现计划与执行日志里。

## Quick Start

```bash
cd labs/speakdock
make build
make run
make test
make logs
make probe-compose PROBE_SECONDS=30
```

常用文档：

- `docs/technical/ARCHITECTURE.md`
- `docs/plans/2026-04-10-speakdock-macos-v1-implementation.md`
- `docs/plans/2026-04-10-speakdock-macos-v1-manual-test.md`
- `docs/plans/2026-04-11-speakdock-macos-v1-execution-log.md`

## 当前已支持

- menu bar app 形态，默认无 Dock 图标
- 默认 `Fn` 的 `按住说话 / 松开结束 / 双击提交`
- `Fn` 不可用时的明确告警，以及用户显式选择替代 trigger
- `Listening / Thinking / Refining` overlay、实时波形、partial transcript
- Apple Speech 流式识别，默认 `zh-CN`，支持 `en-US / zh-CN / zh-TW / ja-JP / ko-KR`
- `Compose` 路径的剪贴板注入、临时 ASCII 输入源切换与恢复
- `Capture` 路径的 `speakdock-YYYYMMDD-HHMMSS.md` 落盘、自动打开、持续追加
- `整理 / 撤回 / UndoWindow = 8 秒 / 双击提交`
- 保守 refine、OpenAI 兼容接口、失败时 fail-open
- Settings 里的 `Choose & Migrate…`、`Test`、`Save`

## macOS v1 关键规则

- 默认 trigger 是 `Fn`
- `Fn` 不可用时，不自动切到某个固定热键
- menu bar 必须明确显示 `Fn` 当前不可用
- 用户需要在 Settings 里显式选择替代 trigger 后才能继续
- `Compose` 不可用时直接报错，不能静默降级成 `Capture`
- refine 是可选能力，默认热路径不能被 refine 失败阻塞
- `DJI` 或其他硬件 adapter 只覆盖输入层，不改上层产品语义

## 权限矩阵

| 权限 | 用途 | 缺失时表现 |
| --- | --- | --- |
| 麦克风 | 录音、波形、电平反馈 | 无法进入 `Listening`，悬浮层应提示麦克风不可用 |
| Speech Recognition | 流式转录、最终文本生成 | 可以开始录音，但不能产出可提交文本，热路径应直接报错 |
| Accessibility | 判定可编辑目标、执行 `Compose` 注入、当前 `Fn` event tap 授权提示 | `Compose` 直接不可用；默认 `Fn` 路径不可用时 menu bar 必须提示异常 |
| Input Monitoring（条件性） | 仅当后续替换为依赖输入监听的 `Fn` 实现时使用 | 当前实现不预期出现在 Input Monitoring 列表；如果未来需要，menu bar 必须提示异常 |

说明：

- 当前实现的 `Fn` event tap 优先走 Accessibility 授权
- `Input Monitoring` 是否需要，取决于后续是否更换 `Fn` 监听实现
- 如果当前走外接硬件 trigger，而不是键盘 `Fn`，这项权限可以不作为前提

## 当前不在 macOS v1 范围内

- iOS 壳层与跨端同步
- 后台 Wiki / 知识层写回
- 面向具体第三方应用的深度适配规则库
- 超出手动验收单范围的性能与长期稳定性结论

## 手动验收重点

- `Fn` 默认路径、替代 trigger、menu bar 告警
- `Compose / Capture / Undo / 双击提交`
- `Choose & Migrate…`、`Test / Save`
- refine 真实网络往返、overlay 状态与权限失败路径

## 调试日志

- 当前实现使用 Apple Unified Logging / `OSLog.Logger`
- subsystem 固定为 `com.leozejia.speakdock`
- category 覆盖 `lifecycle / permission / trigger / audio / speech / compose / capture / refine`
- 查看最近日志：

```bash
make logs
make logs LOG_WINDOW=2h
```

- 快速扫测第三方 App 的 `Compose` 兼容性：

```bash
make probe-compose PROBE_SECONDS=30
make logs LOG_WINDOW=2m
```

- `probe-compose` 只检查前台 App 的可编辑目标，不录音、不注入、不改剪贴板
- 日志不得记录音频内容、转写正文、剪贴板内容或 API Key
