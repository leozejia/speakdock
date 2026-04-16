# SpeakDock Plan Archive

日期：2026-04-16

来源：上一版 `docs/plans/CURRENT.md`

## 已归档 focus

- 阶段：P1 `AI 语音输入法`
- focus：让匿名术语夹具继续下沉到 `smoke-term-learning`，减少脚本层硬编码样本

## 归档原因

这一轮已经完成：

- 默认 `make smoke-term-learning` 已直接回放仓库匿名夹具里的 `promotion` 场景
- 新增 `make smoke-term-learning-conflict`，可稳定验证冲突 alias 不晋升
- `smoke-term-learning`、`TermDictionaryStore` 回放测试、`term-learning-report` 已经共享同一份匿名夹具
- 仍保留 legacy 参数回退，但默认路径不再依赖脚本硬编码样本

## 本轮完成结果

- 已完成：`Tests/SpeakDockMacTests/Fixtures/term-learning-anonymous-baseline.json` 新增 `smokeScenarios`
- 已完成：`run-smoke-term-learning.sh` 改为 fixture-driven 场景加载
- 已完成：`Makefile` 新增 `smoke-term-learning-conflict`
- 已完成：README、手测文档、架构文档和 Swift 踩坑文档同步入口

## 本轮验证

- `make test TEST_FILTER=BuildScriptTests`
- `make test TEST_FILTER=TermLearningFixtureBaselineTests`
- `make smoke-term-learning`
- `make smoke-term-learning-conflict`
- `make test`

## 交接说明

下一轮 focus 改为：把词典学习结果从开发者 smoke/report 基线推进到 Settings 内的用户可读体验。
