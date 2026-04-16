# SpeakDock Plan Snapshot

归档时间：`2026-04-16`

来源：上一版 `docs/plans/CURRENT.md`

## 1. 用途

这份文档是已完成轮次的快照，不再承担当前指挥作用。

## 2. 当时阶段

- 阶段：P1 `AI 语音输入法`
- focus：补本地 `trace-report` 汇总入口，沉淀 `Refine / Smoke / 延迟` 的开发样本基线
- 状态：`Completed`

## 3. 为什么当时做

上一轮已经补齐：

- `make smoke-compose`
- `make smoke-refine`
- `make traces`

但 trace 仍然只是“原始行输出”，还不够支撑下一阶段判断：

- `Refine` 最近到底成功了多少次，失败了多少次
- smoke 路径和 live 路径的结果分布是否稳定
- 热路径总耗时、提交耗时是否在漂

所以当时先不碰模型本身，先把本地 trace 变成“可汇总的样本入口”。

## 4. 当时范围

1. 新增 `make trace-report`
2. 把 `trace.finish` 聚合成结果分布和延迟摘要
3. 支持脚本直接读 unified log，也支持从 `stdin` 喂样本，方便测试
4. 同步 README、手测文档、架构文档和 Swift 踩坑文档
5. 跑定向测试、全量测试和 smoke，再用真实 recent trace 验证输出

## 5. 完成结果

- 已完成：新增 `make trace-report`，可本地汇总最近 `trace.finish` 的结果分布和延迟
- 已完成：`trace-report` 默认直读 unified log，也支持显式 `--stdin` 样本输入，便于自动测试
- 已完成：README、手测文档、架构文档和 Swift 踩坑文档已同步
- 已完成：`make test`、`make smoke-compose`、`make smoke-refine` 通过
