# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：把真实热路径里的词级手动改词观察链路收稳，并补齐自驱验证
- 状态：`In Progress`

## 3. 为什么现在做

刚完成的上一轮，已经把词典学习结果推进到了 Settings 的可读层：

- 用户现在能在 `Settings -> Dictionary` 里看到状态计数和最近学习事件
- CLI 报告与 Settings 也已经对齐到同一套词级最小字段

但更核心的问题还在真实热路径本身：

- 词典学习最终不是为了报告，而是为了在真实 workspace 里稳定记住正确词
- 当前 `WordCorrectionObservationRecorder` 已经存在，但还需要继续收紧真实 `Compose / Capture` 路径的边界
- 如果这条链路不够稳，Settings 面板再清楚也只是展示一个不够可信的来源

所以下一轮不扩 UI，先把“真实工作区里的手动改词观察”继续做扎实。

## 4. 本轮范围

1. 重新审视 `WordCorrectionObservationRecorder` 和 `HotPathCoordinator` 的真实调用边界
2. 明确哪些路径允许记录词级修正，哪些路径必须保守跳过
3. 补 `Compose / Capture / 无法读回 / 句子级改写` 相关测试
4. 优先把验证做成自驱，而不是依赖人工反复点测
5. 同步文档，避免产品语义和实现再次漂移

## 5. 明确不做

- 不扩 `Refine` 语义
- 不把词级学习升级成句子级改写
- 不引入新的模型运行时
- 不做正式打包发布
- 不改 Wiki 长线方向

## 6. 执行顺序

1. 审视现有 `WordCorrectionObservationRecorder` 测试和真实调用点
2. 先补最小 failing test，锁定真实热路径的词级观察边界
3. 再补最小实现或修正
4. 跑定向测试与相关 smoke
5. 同步文档并归档本轮结果

## 7. 完成定义

满足以下条件才算完成：

- 真实热路径里哪些场景会记录词级修正，已经有明确测试覆盖
- `Compose / Capture / 跳过场景` 的边界是可解释且稳定的
- 句子级改写仍然不会进入词典学习
- 验证优先可脚本化、自驱
- 文档能准确说明新的真实边界

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- 当前轮已完成：`TermDictionary` 对 ASCII alias 现在按大小写不敏感的独立词边界匹配，不再误伤更长英文词内部
- 当前轮已完成：词级学习现在只会基于 SpeakDock 实际说过并写出的内容；纯用户自写文本不会进入学习
- 当前轮已完成：`Capture` 工作区现在也能读取当前文件内容做词级观察；缺文件时保守跳过
- 当前轮已完成：`WordCorrectionObservationRecorderTests` 已覆盖 `Compose / Capture / 文件缺失跳过` 三类基础边界
- 上一轮已完成：Settings 的 `Passive Learning` 面板现在能展示 `observed / promoted / conflicted / skippedConfirmed` 状态计数
- 上一轮已完成：Settings 现在能展示最近学习事件，且只暴露 `alias / canonical / evidence / outcome`
- 上一轮已完成：README、手测文档、架构文档和 Swift 踩坑记录已同步到新的词级可读层
- 更早已完成：`smoke-term-learning`、`TermDictionaryStore` 回放测试和 `term-learning-report` 已共享同一份匿名夹具
- 更早已完成：项目已经收敛到 `OSLog.Logger + make logs + make traces + make trace-report + make term-learning-report + make smoke-term-learning` 的统一调试入口
