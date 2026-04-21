# SpeakDock 阶段归档

## 1. 阶段主题

- 阶段：P1 `AI 语音输入法`
- focus：`docs 真值源收口`
- 状态：`Completed`

## 2. 为什么当时做

在热路径、词典学习、诊断入口逐步稳定后，最大的风险已经不是实现空缺，而是文档开始漂：

- `CURRENT / review / README / ARCHITECTURE` 的职责边界开始混写
- `Qwen3-ASR-0.6B via MLX` 在部分文档里被写得过于像既定实现
- `Refine / ASR Correction / Wiki` 的研究名、实现名和产品术语没有完全对齐

这一轮的目标不是追新功能，而是先把唯一真值源重新固定住。

## 3. 本轮实际完成

- `docs/technical/ARCHITECTURE.md` 已统一主术语：`Streaming Preview / ASR Post-Correction / Workspace Refine / Wiki Compile`
- `docs/plans/CURRENT.md` 已收回为当前唯一 live doc，同时承担 live plan 和 live review
- `docs/reviews/CURRENT.md` 已删除，review 不再单独漂移
- `README / docs/README.md` 已回到入口与索引职责，不再替代架构文档
- `Qwen3-ASR-0.6B via MLX` 已重新明确为“优先候选方向”，不是已锁定实现

## 4. 这轮锁住的边界

- 不在这一轮接入本地 ASR 模型
- 不在这一轮实现 `Wiki Compile`
- 不把 research 脑爆直接升级成架构承诺
- 不为了术语统一去做全仓实现名 mass rename

## 5. 验证结果

- `ARCHITECTURE / README / CURRENT / docs index` 已回到单一职责
- 活文档不再残留旧 focus 与分离 review 结构
- research 继续保留，但不再反向覆盖 `ARCHITECTURE`

## 6. 结束判断

这一轮已经满足完成定义：

- SpeakDock 当前行为定义已重新收口到 `docs/technical/ARCHITECTURE.md`
- `docs/plans/CURRENT.md` 已成为唯一 live doc
- 术语、候选边界和索引口径已重新一致

## 7. 下一轮建议

下一轮不该直接写模型接入代码，而应先完成端侧小模型的深度调研、候选筛选和测评设计，再决定真正值得进入实现的模型组合。
