# SpeakDock 阶段归档

## 1. 阶段主题

- 阶段：P1 `AI 语音输入法`
- 完成 focus：把词典学习结果从开发者 smoke/report 基线推进到 Settings 内的用户可读体验
- 状态：`Completed`

## 2. 为什么做这一轮

在这一轮开始前，词典学习链路虽然已经有：

- 匿名夹具
- `TermDictionaryStore` 回放测试
- `make term-learning-report`
- `make smoke-term-learning`

但用户侧还只能看到：

- 已确认术语
- 遗留 pending candidate
- 少量静态说明

这会导致词典学习是否成立，主要还得靠 CLI 报告判断，产品侧不够直观。

## 3. 本轮完成

1. 给 `TermDictionaryStore` 补了稳定的展示投影：
   - `learningEventCount(for:)`
   - `recentLearningEvents(limit:)`
2. 在 Settings 的 `Dictionary -> Passive Learning` 面板里补了真正可读的用户层：
   - `observed / promoted / conflicted / skippedConfirmed` 状态计数
   - 最近学习事件列表
   - 仅展示 `alias / canonical / evidence / outcome`
3. 补齐了中英文文案：
   - 最近学习
   - 状态标签
   - evidence 文案
   - 隐私说明
4. 同步了 README、手测文档、架构文档和 Swift 踩坑记录。

## 4. 明确保持不变

- 没有改 `Refine` 语义
- 没有把词典学习扩成句子级改写
- 没有让 Settings 变成日志面板
- 没有记录完整正文或真实聊天内容

## 5. 验证结果

- `make test TEST_FILTER=TermDictionaryStoreTests`
- `make test TEST_FILTER=AppLocalizerTests`

这轮落地后，Settings 与 CLI 报告已经共享同一条隐私边界：只展示词级最小必要字段。

## 6. 下一轮建议

下一轮更合理的 focus，不是继续扩 Settings，而是把真实热路径里的手动改词观察链路继续收稳：

- 明确 `WordCorrectionObservationRecorder` 在真实 `Compose / Capture` 路径里的边界
- 保证只记录词级修正，不碰句子级整理
- 继续把可回放验证优先做成自驱
