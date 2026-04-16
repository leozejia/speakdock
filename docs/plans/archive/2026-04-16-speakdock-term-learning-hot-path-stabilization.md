# SpeakDock 阶段归档

## 1. 阶段主题

- 阶段：P1 `AI 语音输入法`
- focus：把真实热路径里的词级手动改词观察链路收稳，并补齐自驱验证
- 状态：`Completed`

## 2. 为什么当时做

上一轮已经把词典学习结果推进到了 Settings 的可读层：

- 用户能在 `Settings -> Dictionary` 里看到状态计数和最近学习事件
- CLI 报告与 Settings 已经对齐到同一套词级最小字段

但当时更核心的问题还在真实热路径：

- 词典学习最终不是为了报告，而是为了在真实 workspace 里稳定记住正确词
- 如果 `Compose / Capture / 提交 / workspace 切换` 这些边界不稳，Settings 面板再清楚也只是展示一个不够可信的来源

所以这一轮没有扩 UI，而是继续把“真实工作区里的手动改词观察”做扎实。

## 3. 本轮实际完成

- `TermDictionary` 对 ASCII alias 改为大小写不敏感匹配
- `TermDictionary` 对 ASCII alias 增加独立词边界约束，不再误伤更长英文词内部
- `TermDictionary` 改为全局最长 alias 优先，避免短 alias 抢先破坏长 alias
- SpeakDock 自己切到新 workspace 前，会先对旧 workspace 做一次词级修正结算，避免静默丢学习
- 词级学习继续保持“只基于 SpeakDock 实际说过并写出的内容”；纯用户自写文本不进入学习
- `Capture` 工作区可直接读取当前文件内容做词级观察；缺文件时保守跳过
- `CURRENT`、`ARCHITECTURE`、`SWIFT_MACOS_PITFALLS` 已与真实实现同步

## 4. 这轮锁住的边界

- 词级学习只处理词或短语，不处理句子级改写
- paste-only fallback 或不可读回目标，不承诺生成词级证据
- 当前 v1 的“workspace 结束”只覆盖 `submit` 或 SpeakDock 自己触发的新 workspace 接管
- 不做全局外部焦点监听

## 5. 验证结果

- `make test` -> pass
- `make smoke-term-learning` -> pass
- `make smoke-term-learning-conflict` -> pass

## 6. 结束判断

这条词典学习热路径已经满足当前阶段完成定义：

- 真实热路径里哪些场景会记录词级修正，已有明确测试覆盖
- `Compose / Capture / 跳过场景` 边界可解释且稳定
- 句子级改写仍然不会进入词典学习
- 验证已优先脚本化、自驱

## 7. 下一轮建议

下一轮更合理的 focus 不是继续细磨词典，而是切回 `Refine`：

- 收稳手动整理与发送前整理的真实边界
- 锁清楚 `raw_context / visible_text / dirty / undo` 的关系
- 让 `make smoke-refine` 真正成为下一条主线的自驱基线
