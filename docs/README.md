# SpeakDock 文档

当前唯一真相源：

- `docs/technical/ARCHITECTURE.md`

快速入口：

- 当前唯一 live plan：`docs/plans/CURRENT.md`
- 仓库启动与权限概览：`README.md`
- 人工验收顺序：`docs/plans/2026-04-10-speakdock-macos-v1-manual-test.md`
- 最近一次阶段快照归档：`docs/plans/archive/2026-04-18-speakdock-asr-first-utterance-stabilization.md`
- 阶段实施执行归档：`docs/plans/archive/2026-04-11-speakdock-macos-v1-execution-log.md`

## 技术

- `docs/technical/ARCHITECTURE.md`
- `docs/technical/SWIFT_MACOS_PITFALLS.md`

## 当前

- `docs/plans/CURRENT.md`
- `docs/plans/2026-04-10-speakdock-macos-v1-manual-test.md`

## 归档

- `docs/plans/archive/2026-04-16-speakdock-term-learning-smoke.md`
- `docs/plans/archive/2026-04-16-speakdock-term-learning-report.md`
- `docs/plans/archive/2026-04-16-speakdock-term-learning-fixture-baseline.md`
- `docs/plans/archive/2026-04-16-speakdock-fixture-driven-term-learning-smoke.md`
- `docs/plans/archive/2026-04-16-speakdock-term-learning-hot-path-stabilization.md`
- `docs/plans/archive/2026-04-16-speakdock-settings-term-learning-readable-layer.md`
- `docs/plans/archive/2026-04-16-speakdock-local-trace-report.md`
- `docs/plans/archive/2026-04-18-speakdock-asr-first-utterance-stabilization.md`
- `docs/plans/archive/2026-04-10-speakdock-macos-v1-implementation.md`
- `docs/plans/archive/2026-04-11-speakdock-macos-v1-execution-log.md`

## 研究

- `docs/research/2026-04-10-llm-wiki-original.md`
- `docs/research/2026-04-10-llm-wiki-zh.md`
- `docs/research/2026-04-10-llm-wiki-methodology.md`
- `docs/research/2026-04-14-typeless-shandianshuo-research.md`
- `docs/research/2026-04-15-brand-icon-research.md`

原则：

- 外部参考放 `research`
- SpeakDock 自己的行为定义最终以 `technical/ARCHITECTURE.md` 为准
- `research` 只能启发入口和表达方式，不能反向覆盖架构主模型
- `docs/plans/CURRENT.md` 是当前唯一 live plan
- 当前 focus 完成后，先把 `CURRENT.md` 快照归档，再开启下一轮
- README 负责入口、权限矩阵和当前支持范围，不替代架构文档
- `archive/` 只保留历史计划、执行记录和阶段性快照，不承担当前指挥作用
- 只保留当前仍然正确、仍然会被执行的文档
- 已被主架构取代的旧文档直接删除
