# SpeakDock Plan Snapshot

归档时间：`2026-04-16`

来源：上一版 `docs/plans/CURRENT.md`

## 1. 用途

这份文档是已完成轮次的快照，不再承担当前指挥作用。

## 2. 当时阶段

- 阶段：P1 `AI 语音输入法`
- focus：补 `TermDictionary` 的本地质量观察入口，沉淀真实样本与结果摘要，减少后续调优时对手翻日志的依赖
- 状态：`Completed`

## 3. 为什么当时做

当时已经有：

- `make smoke-term-learning`
- 隔离词典下的自驱 `观察证据 -> 自动晋升 -> 下次命中`

但还没有一个便宜、只读、隐私保守的开发入口，用来直接看当前词典学习层到底发生了什么。

所以这一轮补的是本地观察层，而不是模型：

- 让开发者不用翻 JSON 或手看代码，就能看到词典学习摘要
- 能直接区分 `observed / promoted / conflicted / skippedConfirmed`
- 保持输出只包含 `alias / canonical / evidence / outcome` 这类最小必要信息

## 4. 当时范围

1. 为 `TermDictionaryStore` 增加最小学习事件持久化
2. 新增 `make term-learning-report`
3. 让开发阶段可低成本查看当前学习结果分布
4. 不记录完整聊天内容、完整转写正文或剪贴板正文
5. 同步 README、手测文档和技术文档
6. 跑定向测试、全量测试和 smoke 验证

## 5. 完成结果

- 已完成：`TermDictionaryStore` 现在会在本地快照里持久化最小学习事件
- 已完成：新增 `make term-learning-report`，可直接汇总本地词典学习结果
- 已完成：报告可区分 `observed / promoted / conflicted / skippedConfirmed`
- 已完成：输出保持在 `alias / canonical / evidence / outcome` 级别，不暴露完整正文
- 已完成：README、手测文档、架构文档和 Swift 踩坑文档已同步
- 已完成：`make test`、`make smoke-term-learning` 通过
