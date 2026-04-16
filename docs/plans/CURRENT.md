# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：把词典学习结果从开发者 smoke/report 基线推进到 Settings 内的用户可读体验
- 状态：`Ready`

## 3. 为什么现在做

现在的事实状态是：

- 仓库里已经有匿名术语夹具
- `TermDictionaryStore` 回放测试、`term-learning-report`、`smoke-term-learning` 已经吃同一份夹具
- 但当前用户侧仍然主要只能看到已确认词典、pending candidate 和少量学习统计

这意味着开发者基线已经收稳，但用户可感知体验还没有跟上：

- 用户还看不清最近到底学到了哪些 alias
- `observed / promoted / conflicted / skippedConfirmed` 这些状态主要还停留在 CLI 报告里
- 如果后面继续调词典学习策略，没有 app 内可读层，产品侧很难判断体验是否成立

所以下一轮先把词典学习结果推进到 Settings 可读层，而不是继续扩新功能。

## 4. 本轮范围

1. 审视当前 `Term Dictionary` Settings 页，确认手工词典和被动学习的边界是否清楚
2. 在 Settings 里补最近学习结果的可读视图，但只暴露词级最小必要信息
3. 让用户能区分 `observed / promoted / conflicted / skippedConfirmed`
4. 保持隐私边界，不记录或暴露完整真实正文
5. 同步 README、技术文档和手测文档
6. 跑测试，确认词典学习和现有 smoke 基线不回退

## 5. 明确不做

- 不改 `Refine` 语义
- 不改模型策略
- 不把词级学习扩成句子级改写
- 不把 Settings 做成日志面板或调试器替代品
- 不记录完整聊天内容、完整转写正文或剪贴板正文
- 不引入新运行时或新后台服务

## 6. 执行顺序

1. 更新 live plan，锁定这一轮是 Settings 内的词典学习可读层
2. 先梳理现有 `TermDictionaryStore` 可直接安全展示的字段
3. 在 Settings 里补最近学习结果和状态分布
4. 同步文档
5. 跑测试和相关 smoke 验证

## 7. 完成定义

满足以下条件才算完成：

- Settings 内能看到最近学习结果，而不是只靠 CLI
- 用户能区分 `observed / promoted / conflicted / skippedConfirmed`
- Settings 暴露的信息仍然只保留词级最小必要字段
- README、手测文档和技术文档都能找到新的入口
- `make test`、`make smoke-term-learning`、`make smoke-term-learning-conflict` 和相关既有基线仍然通过

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- 上一轮已完成：`smoke-term-learning` 默认已直接读取匿名夹具，不再依赖脚本硬编码样本
- 上一轮已完成：新增 `make smoke-term-learning-conflict`，可稳定验证冲突 alias 不晋升
- 上一轮已完成：`smoke-term-learning`、`TermDictionaryStore` 回放测试和 `term-learning-report` 已共享同一份匿名夹具
- 更早已完成：新增 `make term-learning-report`，可直接汇总本地词典学习摘要
- 更早已完成：`TermDictionaryStore` 已持久化最小学习事件，可区分 `observed / promoted / conflicted / skippedConfirmed`
- 更早已完成：测试宿主已支持 command file，可在自驱场景下稳定模拟用户手动改词
- 更早已完成：项目已经收敛到 `OSLog.Logger + make logs + make traces + make trace-report + make term-learning-report + make smoke-term-learning` 的统一调试入口
