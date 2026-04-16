# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：让匿名术语夹具继续下沉到 `smoke-term-learning`，减少脚本层硬编码样本
- 状态：`Ready`

## 3. 为什么现在做

现在的事实状态是：

- 仓库里已经有匿名术语夹具
- 夹具已经能驱动 `TermDictionaryStore` 回放测试和 `term-learning-report` 脚本测试
- 但 `smoke-term-learning` 仍然把样本硬编码在 shell 脚本里

这意味着现在测试层和 smoke 层还没有完全收敛成同一套样本源：

- 测试里新增一个匿名场景后，shell smoke 不会自动跟上
- smoke 失败时，也很难快速切换到“晋升场景 / 冲突场景 / 已确认场景”定位问题
- 继续保留两套样本维护，后面只会再次漂移

所以下一轮先让 smoke 也吃到匿名夹具，而不是继续扩新功能。

## 4. 本轮范围

1. 让 `smoke-term-learning` 支持从仓库内匿名夹具读取样本，而不是只吃脚本硬编码字符串
2. 保持默认 smoke 行为可用，不破坏现有 `make smoke-term-learning`
3. 至少补两个 fixture-driven smoke 场景：稳定晋升、冲突不晋升
4. 继续保持隐私边界，不记录或暴露完整真实正文
5. 同步 README、技术文档和手测文档
6. 跑测试和相关 smoke，确认旧基线不回退

## 5. 明确不做

- 不改 `Refine` 语义
- 不改模型策略
- 不把词级学习扩成句子级改写
- 不把 smoke 变成真实用户数据导出入口
- 不记录完整聊天内容、完整转写正文或剪贴板正文
- 不引入新运行时或新后台服务

## 6. 执行顺序

1. 更新 live plan，锁定这一轮是 fixture-driven `smoke-term-learning`
2. 先定义 smoke 夹具 schema 和默认回退行为
3. 复用已有匿名夹具和 `run-smoke-term-learning.sh` 基础设施补入口
4. 同步文档
5. 跑测试和 smoke 验证

## 7. 完成定义

满足以下条件才算完成：

- `smoke-term-learning` 可以直接读取仓库内匿名夹具
- 默认 smoke 入口仍然可直接运行
- 至少两个 fixture-driven 场景可稳定通过
- 匿名夹具不包含真实聊天正文或真实用户数据
- README、手测文档和技术文档都能找到新的入口
- `make test`、`make smoke-term-learning` 和相关既有基线仍然通过

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- 上一轮已完成：仓库内新增匿名术语夹具 `Tests/SpeakDockMacTests/Fixtures/term-learning-anonymous-baseline.json`
- 上一轮已完成：同一份夹具已同时驱动 `TermDictionaryStore` 回放测试和 `term-learning-report` 脚本测试
- 上一轮已完成：夹具已稳定覆盖 `observed / promoted / conflicted / skippedConfirmed`
- 更早已完成：新增 `make term-learning-report`，可直接汇总本地词典学习摘要
- 更早已完成：`TermDictionaryStore` 已持久化最小学习事件，可区分 `observed / promoted / conflicted / skippedConfirmed`
- 更早已完成：新增 `make smoke-term-learning`，可用隔离临时词典自驱验证 `观察证据 -> 自动晋升 -> 下次命中`
- 更早已完成：测试宿主已支持 command file，可在自驱场景下稳定模拟用户手动改词
- 更早已完成：项目已经收敛到 `OSLog.Logger + make logs + make traces + make trace-report + make term-learning-report + make smoke-term-learning` 的统一调试入口
