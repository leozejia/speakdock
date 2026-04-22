# SpeakDock Current Focus

## 1. 用途

这份文档是当前唯一 live doc。

- 同时承担 `live plan` 和 `live review`
- 只记录当前唯一 focus
- 完成后整页重写，不在这里堆历史过程
- 目标是让代码、验证和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：`Workspace Refine contract 收口与最小实现闭环`
- 状态：`Completed`

## 3. 当前复核结论

- 上一轮 `ASR Post-Correction provider / on-device server lifecycle` 已完成并收口
- `Workspace Refine` 现在的产品定义已经明确：
  - 它只处理整个 active workspace
  - 它不是词级纠错
  - 它不是每段录音释放后的 inline 自动步骤
  - 主触发是手动整理，或发送前的可选整理
- 这轮已确认并正在收口的关键点：
  - `WorkspaceRefinePrompt` 必须明确是“工作区整理”语义
  - 它不能再复用“保守转写纠错”话术
  - `manual refine` 的 fallback 真源必须是当前 workspace 文本，不是 `clean text`
- 当前 smoke 已经覆盖：
  - `submit refine`
  - `manual refine`
  - `mixed-language submit refine`
  - `mixed-language manual refine`
  - `dirty undo`
  - `submit observed edit`
  - `capture manual / dirty undo / fallback`
- 当前这轮新补的 smoke 已经强制钉住：
  - `manual refine` 失败时，必须保留当前 workspace 原文，而不是 clean/normalize 后的版本

## 4. 为什么现在做

上一轮主线已经不是阻塞。

现在真正会继续带偏开发的，是 `Refine` 名字虽然没错，但语义还没真正落到“工作区整理”。

如果这一轮不先收口：

- 之后继续接上下文、发送前整理、wiki 或模型能力时，大家会默认它还是“保守纠错”
- 文档、提示词、fallback 和 smoke 会继续各说各话
- 看起来功能在前进，实际上产品边界会越来越模糊

所以这一轮只做一件事：

- 把 `Workspace Refine` 的定义、提示词、fallback 和 smoke 收成同一口径

## 5. 本轮范围

1. 把 `CURRENT` 切到 `Workspace Refine`
2. 把 `Refine` prompt 从“保守纠错”改成“工作区整理”
3. 收口手动整理 / 发送前整理的 fallback 语义
4. 用现有 smoke 补强“当前工作区文本才是 fallback 真源”
5. 同步 `ARCHITECTURE` 与 Swift 踩坑记录

## 6. 明确不做

- 不改 `ASR Post-Correction` provider
- 不改 Apple Speech 主线
- 不把 `selection refine` 升成新的顶层状态
- 不引入新的 `Refine` provider 契约
- 不把 `Workspace Refine` 改成自动逐段执行
- 不在这一轮做 `StyleProfile`
- 不在这一轮做 wiki 新能力

## 7. 执行顺序

1. 先补一个会失败的 smoke，钉住“manual fallback 保留当前 workspace 原文”
2. 再修 `Refine` 热路径的 source / model input / fallback 语义
3. 再把 prompt 与命名改成 `Workspace Refine`
4. 最后同步文档并跑回归

## 8. 完成定义

满足以下条件才算完成：

- `CURRENT` 已切换到 `Workspace Refine`
- `Refine` prompt 已明确是“工作区整理”，不再冒充 ASR 纠错
- `manual refine` 失败时，不会把当前 workspace 偷偷变成 clean text
- `manual refine` 关闭或失败时，保留的是当前 workspace 文本
- `submit refine` 仍保持“失败不阻塞发送”
- `smoke-refine`
- `smoke-refine-fallback`
- `smoke-refine-submit-sync`
- `smoke-capture-refine-fallback`
- 相关 `swift test`
- `ARCHITECTURE` 与 Swift 踩坑记录已同步

## 9. 下一轮候选

- `Workspace Refine` 的上下文打包
- 发送前整理的触发策略细化
- `Compose / Capture` 共用的整理观测报表

## 10. 当前不进入下一轮的项

- 不重开本地 `Workspace Refine` 默认路线
- 不把句级整理混回 `ASR Post-Correction`
- 不把词典学习升级成句级学习
- 不把 provider 扩成 vendor-specific adapter

## 11. 阻塞项

- 当前无外部阻塞

## 12. 最近完成

- 已完成：`ASR Post-Correction provider / on-device server lifecycle` 收口
- 已完成：`/v1/models` readiness 必须校验目标模型真实存在
- 已完成：custom endpoint 与 on-device 两条 `smoke-asr-correction` 闭环
- 已完成：端侧 `mlx_lm.server` 生命周期由 SpeakDock 管理
- 已完成：`WorkspaceRefinePrompt` 已替换旧的保守纠错 prompt 命名与语义
- 已完成：`smoke-capture-refine-fallback` 已能卡住“manual fallback 保留当前 workspace 原文”
- 已完成：compose target identity 已去掉易漂移字段，提交前整理 smoke 再次闭环
- 已完成：`Workspace Refine` 的中英混合 smoke 已补到 `submit + manual` 两条路径
