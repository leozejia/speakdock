# SpeakDock 架构复核

## 1. 用途

这份文档是当前唯一 live 复核。

- 只记录当前复核周期的结论和待确认项
- 被 plan 消化后归档，不在这里堆历史
- 目标是作为下一轮 CURRENT.md 的输入，而不是独立存在

## 2. 复核时间

- 2026-04-21

## 3. 复核范围

- `README.md`
- `README.zh-CN.md`
- `docs/technical/ARCHITECTURE.md`
- `docs/plans/CURRENT.md`
- `docs/README.md`
- `docs/research/2026-04-10-llm-wiki-methodology.md`
- `docs/research/2026-04-20-next-phase-brainstorm.md`

## 4. 结论

- 活文档口径已经重新收口到 `ActiveWorkspace + SecondaryAction`
- `Streaming Preview / ASR Post-Correction / Workspace Refine / Wiki Compile` 已成为当前统一术语
- `Qwen3-ASR-0.6B via MLX` 当前只保留为优先候选方向，未被写死为已锁定实现
- `Wiki` 的默认浏览方式已经明确为“本地 HTTP server + 浏览器打开 `wiki/` 根目录”
- research 继续保留，但不再反向覆盖架构主模型

## 5. 待进入下一轮 plan 的项

- 端侧 ASR 候选评测页，明确真实失败样本、延迟、内存和热量口径
- `Wiki Compile` 的最小入口和浏览器浏览验证

## 6. 不需要进入 plan 的观察

- 不需要为了术语统一去做全仓实现名重写
- 不需要现在就锁死 sidecar 常驻、量化方案或具体模型封装

## 7. 归档条件

- 下一轮 `CURRENT.md` 接管 focus 时归档
