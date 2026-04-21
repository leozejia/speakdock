# SpeakDock Current Focus

## 1. 用途

这份文档是当前唯一 live doc。

- 同时承担 `live plan` 和 `live review`
- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、复核结论和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：`第二轮调研：ASR Post-Correction 与云端 Refine`
- 状态：`In Progress`

## 3. 当前复核结论

- 端侧小模型当前只保留给 `ASR Post-Correction`
- `Workspace Refine` 默认走云端 LLM，本地 `Refine` 只保留为高配用户自定义扩展
- 文本后纠错这条线只看 `Qwen3.5` 最新模型，不再考虑 `Qwen3.0` 文本模型
- 第二轮调研要解决两个具体问题：
  - 哪些小模型值得进入 `ASR Post-Correction` shortlist
  - 云端 `Refine` 的默认 provider 契约与失败回退应如何写死
- 当前实现里 `Refine` 的失败回退已经存在，但 prompt 语义仍然偏“保守纠错”，还没完全对齐“工作区整理”
- 本轮调研继续只接受官方/一手资料：官方 repo、官方技术报告、官方模型卡、官方框架文档

## 4. 为什么现在做

第一轮已经把“哪些能力不该默认端侧化”收口完了，第二轮要把真正剩下的主线问题做细。

- `ASR Post-Correction` 是当前唯一保留的端侧文本模型入口
- `Workspace Refine` 默认转到云端后，重点不再是本地跑不跑得动，而是默认 provider 契约和失败体验是否正确
- 当前实现已经具备 `ASRCorrectionEngine` 与 `RefineEngine` 两条 seam，现在缺的是候选筛选与规则写死
- 如果不先补这一轮，后面会继续在“模型选型”“provider 选型”“fallback 语义”之间来回漂

所以第二轮依然先做 research 和边界收口，不直接写模型接入或 provider 迁移代码。

## 5. 本轮范围

1. 基于官方资料筛 `ASR Post-Correction` 候选
2. 明确底线机器上的 `pass / shortlist / watchlist / benchmark only`
3. 复核当前 `ASRCorrectionEngine` 和 `RefineEngine` 的真实契约
4. 研究云端 `Workspace Refine` 的默认 provider 契约
5. 把当前已经存在的失败回退语义写清楚，避免后续误改
6. 同步 `CURRENT / research / docs index`

## 6. 明确不做

- 不在这一轮接入任何本地 `ASR Post-Correction` 模型
- 不在这一轮切换 `Workspace Refine` 的云端 provider
- 不在这一轮重新打开本地 `Workspace Refine` 主线
- 不用二手博客、第三方评测视频或社区跑分贴替代官方资料

## 7. 执行顺序

1. 先收 `ASR Post-Correction` 候选与 pass 条件
2. 再收云端 `Refine` 的 provider 契约与 fallback 设计
3. 然后把研究页与 `CURRENT` 对齐
4. 最后给出下一轮最小 spike 顺序

## 8. 完成定义

满足以下条件才算完成：

- `ASR Post-Correction` 已有独立研究页
- 第二轮研究页已经写清 `shortlist / pass / benchmark only`
- 云端 `Workspace Refine` 的默认契约与失败回退已写清
- 当前实现里的 prompt / provider / fallback 漂移已被明确记录
- 下一轮可以直接进入最小可行性 spike

## 9. 下一轮候选

- `ASR Post-Correction` 的最小实测设计
- 云端 `Workspace Refine` 的 prompt 重定义与 provider smoke
- `ASR` 与 `ASR Post-Correction` 的样本协同设计

## 10. 当前不进入下一轮的项

- 不重新讨论本地 `Workspace Refine` 是否应成为默认路线
- 不锁死最终云端厂商
- 不提前写死 `Responses API` 或其他 vendor-specific API 为统一契约

## 11. 阻塞项

- 当前无外部阻塞

## 12. 最近完成

- 已完成：上一轮 `端侧模型收口` 已归档
- 已完成：产品默认路线已经收口为“端侧只保留 `ASR Post-Correction`，`Workspace Refine` 默认云端”
- 已完成：`ASR` 一手资料 research 已落地，可作为第二轮输入
