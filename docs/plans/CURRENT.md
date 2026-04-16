# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：沉淀匿名术语样本夹具与回归基线，开始用 `term-learning-report` 稳定观察词典学习质量
- 状态：`Ready`

## 3. 为什么现在做

现在的事实状态是：

- `TermDictionary` 的被动学习能力已经存在
- 本地 smoke 已可稳定跑通 `观察证据 -> 自动晋升 -> 下次命中`
- 本地已有 `make term-learning-report` 可以只读查看学习摘要
- 但当前还没有一组稳定、可匿名共享、可回归的术语样本夹具

这意味着现在虽然“报告入口已存在”，但质量基线还不够稳：

- 每次观察都还偏临场、偏人工
- 很难稳定复现“混输术语、专有名词、冲突 alias”这些真实难点
- 如果后面继续调 `Clean / TermDictionary / Refine` 边界，没有一组小而稳的匿名样本夹具做回归

所以下一轮先补样本基线，而不是继续扩模型。

## 4. 本轮范围

1. 沉淀一组匿名术语样本夹具，覆盖混输术语、冲突 alias、已确认 alias、可晋升 alias
2. 让这些夹具能直接喂给现有词典学习路径和 `term-learning-report`
3. 用固定样本锁住当前 `observed / promoted / conflicted / skippedConfirmed` 的结果分布
4. 保持隐私边界，不记录或暴露完整转写正文
5. 同步 README、技术文档和手测文档
6. 跑定向测试与相关 smoke，确认旧基线不回退

## 5. 明确不做

- 不改 `Refine` 语义
- 不改模型策略
- 不把词级学习扩成句子级改写
- 不把本地观察入口做成云端依赖
- 不记录完整聊天内容、完整转写正文或剪贴板正文
- 不把匿名样本夹具变成真实用户数据导出

## 6. 执行顺序

1. 更新 live plan，锁定这一轮是匿名术语样本夹具与回归基线
2. 先钉住最小行为测试，定义样本夹具必须覆盖哪些 outcome
3. 复用已有 `TermDictionaryStore / smoke-term-learning / term-learning-report` 基础设施补回归入口
4. 同步文档
5. 跑测试和 smoke 验证

## 7. 完成定义

满足以下条件才算完成：

- 仓库里存在一组匿名术语样本夹具
- 夹具可稳定覆盖 `observed / promoted / conflicted / skippedConfirmed`
- `term-learning-report` 可直接对这些样本产出稳定摘要
- 样本夹具不包含真实聊天正文或真实用户数据
- README、手测文档和技术文档都能找到新的入口
- `make test`、`make smoke-term-learning` 和相关既有基线仍然通过

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- 上一轮已完成：新增 `make term-learning-report`，可直接汇总本地词典学习摘要
- 上一轮已完成：`TermDictionaryStore` 已持久化最小学习事件，可区分 `observed / promoted / conflicted / skippedConfirmed`
- 上一轮已完成：词典学习报告保持在 `alias / canonical / evidence / outcome` 级别，不暴露完整正文
- 更早已完成：新增 `make smoke-term-learning`，可用隔离临时词典自驱验证 `观察证据 -> 自动晋升 -> 下次命中`
- 更早已完成：测试宿主已支持 command file，可在自驱场景下稳定模拟用户手动改词
- 更早已完成：词典学习 smoke 默认强制隔离真实词典和真实 refine 配置，不污染用户本地环境
- 更早已完成：新增 `make trace-report`，可本地汇总最近 `trace.finish` 的结果分布和延迟
- 更早已完成：`trace-report` 默认直读 unified log，也支持显式 `--stdin` 样本输入，便于自动测试
- 更早已完成：项目已经收敛到 `OSLog.Logger + make logs + make traces + make trace-report + make term-learning-report + make smoke-term-learning` 的统一调试入口
