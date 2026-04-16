# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：补 `TermDictionary` 被动学习的自驱闭环，减少这条链路对人工手测的依赖
- 状态：`Ready`

## 3. 为什么现在做

现在的事实状态是：

- `TermDictionary` 的被动学习能力已经存在
- 本地已能记录词级观察证据
- 同一 `alias -> canonical` 连续一致 `3` 次后已可自动晋升进 active 词典
- 但当前还缺一条稳定、可重复、自驱的端到端回归路径

这意味着现在虽然“能力存在”，但验证仍然偏手工：

- 还要靠人工在真实输入框里说话、改词、重复改词
- 很难稳定复现“证据累计 -> 晋升 -> 下次命中”整条链路
- 后面如果继续扩大目标覆盖或调整观察策略，没有便宜的回归基线

所以这一轮要补的不是新产品语义，而是这条词级学习链路的本地自驱闭环。

## 4. 本轮范围

1. 设计并落地 `TermDictionary` 被动学习的本地自驱验证入口
2. 覆盖 `generated text -> manual correction evidence -> promotion -> next-hit apply` 主链路
3. 尽量复用现有 `SpeakDockTestHost / smoke / trace-report` 基础设施
4. 不污染用户真实词典数据
5. 同步 README、手测文档和架构文档
6. 跑定向测试、全量测试和相关 smoke

## 5. 明确不做

- 不改 `Refine` 语义
- 不改模型策略
- 不扩第三方 App 自动回归矩阵
- 不把词级学习扩成句子级改写

## 6. 执行顺序

1. 更新 live plan，锁定这一轮是 `TermDictionary` 自驱闭环
2. 先写最小失败测试，钉住“证据累计与晋升”目标行为
3. 复用或扩展本地测试宿主，把整条链路自动跑通
4. 同步文档
5. 跑测试和 smoke 验证

## 7. 完成定义

满足以下条件才算完成：

- 本地可以自驱验证词级观察证据累计
- 本地可以自驱验证达到阈值后自动晋升进 active 词典
- 本地可以自驱验证下一次输出能命中新晋升词典
- 运行过程不污染用户真实词典数据
- README、手测文档和技术文档都能找到新的验证入口
- `make test`、现有 smoke 和相关新基线仍然通过

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- 上一轮已完成：新增 `make trace-report`，可本地汇总最近 `trace.finish` 的结果分布和延迟
- 上一轮已完成：`trace-report` 默认直读 unified log，也支持显式 `--stdin` 样本输入，便于自动测试
- 更早已完成：新增 `make smoke-refine`，本地可自驱 `Refine HTTP -> apply -> submit`
- 更早已完成：smoke refine 只在运行时注入配置，不污染用户真实 refine 设置
- 更早已完成：smoke host ready 时序和状态落盘等待已补稳，`smoke-compose / smoke-refine` 可重复回归
- 更早已完成：项目已经收敛到 `OSLog.Logger + make logs + make traces + make trace-report` 的统一调试入口
