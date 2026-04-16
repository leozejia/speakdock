# SpeakDock Plan Snapshot

归档时间：`2026-04-16`

来源：上一版 `docs/plans/CURRENT.md`

## 1. 用途

这份文档是已完成轮次的快照，不再承担当前指挥作用。

## 2. 当时阶段

- 阶段：P1 `AI 语音输入法`
- focus：补 `TermDictionary` 被动学习的自驱闭环，减少这条链路对人工手测的依赖
- 状态：`Completed`

## 3. 为什么当时做

当时已经明确：

- `TermDictionary` 的被动学习能力已经存在
- 同一 `alias -> canonical` 连续一致 `3` 次后已可自动晋升进 active 词典
- 但验证还严重依赖人工在真实输入框里重复说话、改词、再重试

这意味着能力虽然存在，但缺少一条便宜、稳定、可重复的本地回归路径。

所以这一轮补的不是新产品语义，而是：

- 让 `观察证据 -> 自动晋升 -> 下次命中` 这条链路能自驱跑通
- 减少这条能力后续演化时对人工手测的依赖
- 同时保证不污染用户真实词典和真实 refine 配置

## 4. 当时范围

1. 设计并落地 `TermDictionary` 被动学习的本地自驱验证入口
2. 覆盖 `generated text -> manual correction evidence -> promotion -> next-hit apply` 主链路
3. 尽量复用现有 `SpeakDockTestHost / smoke / trace-report` 基础设施
4. 运行过程不污染用户真实词典数据
5. 同步 README、手测文档和架构文档
6. 跑定向测试、全量测试和相关 smoke

## 5. 完成结果

- 已完成：新增 `make smoke-term-learning`，可用隔离临时词典自驱验证 `观察证据 -> 自动晋升 -> 下次命中`
- 已完成：测试宿主已支持 command file，可在自驱场景下稳定模拟用户手动改词
- 已完成：词典学习 smoke 默认强制隔离真实词典和真实 refine 配置，不污染用户本地环境
- 已完成：README、手测文档、架构文档和 Swift 踩坑文档已同步
- 已完成：`make test`、`make smoke-compose`、`make smoke-refine`、`make smoke-term-learning`、`make trace-report TRACE_WINDOW=5m` 通过
