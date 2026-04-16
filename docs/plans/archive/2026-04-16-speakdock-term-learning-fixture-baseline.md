# SpeakDock Plan Archive

日期：2026-04-16

来源：上一版 `docs/plans/CURRENT.md`

## 已归档 focus

- 阶段：P1 `AI 语音输入法`
- focus：沉淀匿名术语样本夹具与回归基线，开始用 `term-learning-report` 稳定观察词典学习质量

## 归档原因

这一轮已经完成：

- 仓库内新增匿名术语夹具 `Tests/SpeakDockMacTests/Fixtures/term-learning-anonymous-baseline.json`
- 同一份夹具已同时接入 `TermDictionaryStore` 回放测试和 `term-learning-report` 脚本测试
- 夹具可稳定覆盖 `observed / promoted / conflicted / skippedConfirmed`
- 夹具只包含词级最小必要信息，不包含真实聊天正文或真实用户数据

## 本轮完成结果

- 已完成：新增 `TermLearningFixtureSupport`
- 已完成：新增 `TermLearningFixtureBaselineTests`
- 已完成：`TermLearningReportScriptTests` 改为复用匿名夹具，不再内联单独样本
- 已完成：`SpeakDockMacTests` 已显式声明 `Fixtures` test resource
- 已完成：README、技术文档和 docs 索引已同步夹具入口

## 本轮验证

- `make test TEST_FILTER=TermLearning`
- `make test`
- `make smoke-term-learning`
- `make smoke-compose`
- `make smoke-refine`

## 交接说明

下一轮 focus 改为：让匿名术语夹具继续下沉到 `smoke-term-learning`，减少脚本层硬编码样本。
