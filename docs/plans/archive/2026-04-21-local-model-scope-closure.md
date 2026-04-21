# SpeakDock 阶段归档

## 1. 阶段主题

- 阶段：P1 `AI 语音输入法`
- focus：`端侧模型收口：仅保留 ASR Post-Correction，本地 Refine 退出默认路线`
- 状态：`Completed`

## 2. 为什么当时做

第一轮端侧模型调研已经把候选池拉开，但还缺一个更重要的收口：哪些能力值得在底线机器上默认端侧化。

在 `MacBook Air / Apple M3 / 16 GB / macOS 15.7.4` 这个前提下，如果不先写死边界，后续实现很容易把：

- 高配可选
- 产品默认
- 研究候选

混在一起继续推进。

## 3. 本轮实际完成

- 端侧小模型的产品默认范围已经收口到 `ASR Post-Correction`
- `Workspace Refine` 已明确改为默认走云端 LLM
- 本地 `Refine` 只保留为高性能机器上的用户自定义扩展
- `4B` 级本地 `Refine` 已明确退出底线机器默认路线
- `ARCHITECTURE / CURRENT / research` 已同步到同一口径

## 4. 这轮锁住的边界

- 不把本地 `Workspace Refine` 继续推进成产品默认能力
- 不把高性能机器可选路线误写成底线机器 baseline
- 不因为某个模型“能跑”就把它升级成默认主线

## 5. 验证结果

- `docs/technical/ARCHITECTURE.md` 已明确：
  - 默认 `Workspace Refine` 走云端
  - 本地 `Refine` 只作高级自定义扩展
  - 当前端侧主线只保留给 `ASR Post-Correction`
- `docs/plans/CURRENT.md` 与 `docs/research/2026-04-21-on-device-model-research.md` 已同步该决策

## 6. 结束判断

这一轮已经满足完成定义：

- 产品默认路线与高配扩展路线已经拆开
- 底线机器的端侧边界已经写死
- 后续第二轮调研可以直接进入 `ASR Post-Correction` 与云端 `Refine` 路线

## 7. 下一轮建议

下一轮不再重复“本地 Refine 值不值”的讨论，而是：

1. 深入研究 `ASR Post-Correction` 的最小候选集
2. 明确云端 `Workspace Refine` 的 provider 契约与失败回退
