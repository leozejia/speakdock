# SpeakDock 阶段归档

## 1. 阶段主题

- 阶段：P1 `AI 语音输入法`
- focus：`第二轮调研：ASR Post-Correction 与云端 Refine`
- 状态：`Completed`

## 2. 为什么当时做

第一轮已经把“端侧只保留 `ASR Post-Correction`，`Workspace Refine` 默认云端”收口完了，但还缺第二层更细的判断：

- 哪些小模型值得进入 `ASR Post-Correction` shortlist
- 云端 `Workspace Refine` 的 provider 契约和失败回退是否已经足够稳定

如果这一步不先做，后续实现会继续在：

- 模型候选
- provider 选择
- prompt 语义
- fallback 边界

之间来回漂。

## 3. 本轮实际完成

- `ASR` 与 `ASR Post-Correction` 的角色已经拆开
- `Qwen3-ASR`、`Qwen3.5-Omni`、文本后纠错模型三条线已经拆开，不再混写
- `ASR Post-Correction` 的最小 shortlist 已经收口到：
  - `Qwen3.5-0.8B`
  - `Qwen3.5-2B`
  - `Gemma 3 1B`
- `Workspace Refine` 默认继续走 OpenAI-compatible `chat/completions`
- 当前 `Refine` 最大的真实问题已明确是 prompt 语义漂移，不是 provider 契约不够

## 4. 这轮锁住的边界

- 不把 `Qwen3.5-Omni` 误写成底线机器上的默认本地路线
- 不把文本小模型误写成“`Qwen3.5-ASR` 已公开存在”
- 不重新打开本地 `Workspace Refine` 默认路线
- 不因为 seam 已存在就跳过模型准入评测

## 5. 验证结果

- `docs/technical/ARCHITECTURE.md`、`docs/plans/CURRENT.md` 与第二轮 research 页口径已经对齐
- `ASRCorrectionEngine` 与 `RefineEngine` 的当前契约已经复核清楚
- `Refine` 失败回退边界已经有文档化结论

## 6. 结束判断

这一轮已经满足完成定义：

- `ASR Post-Correction` 候选池已有明确收口
- 云端 `Workspace Refine` 默认契约已写清
- 当前 prompt / provider / fallback 漂移点已被点名

下一步不该继续重复 research，而该进入：

- `ASR Post-Correction` 最小实测设计

## 7. 下一轮建议

下一轮只做一件事：

1. 把 `ASR Post-Correction` 的样本、指标、闸门和最小 spike 顺序写死
