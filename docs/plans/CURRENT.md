# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后归档快照，再重写下一轮
- 不在这里堆长期想法、研究摘录或历史过程

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：补开发用全链路遥测与自驱 smoke，减少反复人工测试
- 状态：`Completed`

## 3. 为什么现在做

词典被动学习这一轮已经落地，但当前开发闭环仍然过度依赖人工验收：

- 现在日志虽然已经结构化，但还缺“同一次交互”的统一串联，定位问题仍然靠人工拼时间线
- 现在能做 `compose probe`，但它只覆盖 target 捕获，不覆盖整条热路径
- 现在很多改动仍然要你亲手跑一遍真实场景，迭代效率偏低
- 如果不先补开发态可观测性，后面继续做 `Refine`、端侧模型接入、更多 target 兼容性时，排障成本会快速上升

这一轮的目标不是做产品化 analytics，而是搭建开发期闭环：

1. 让一次真实交互从 `press -> audio -> speech -> clean/refine -> compose/capture -> submit` 都能被同一条 trace 串起来
2. 让热路径可以在不依赖真实 `Fn`、真实说话、真实第三方 App 的情况下做自驱 smoke
3. 只把少量真实第三方 App 验证保留到里程碑阶段，而不是每次小改动都人工回归

## 4. 本轮范围

1. 给热路径补 `interaction_id`
2. 给关键阶段补耗时与统一结果码
3. 增加本地 trace 摘要脚本与 `make` 入口
4. 增加 smoke hot path 启动模式，用自动驱动文本提交跑完整热路径
5. 增加稳定测试宿主，用于自动验证注入基线
6. 同步 live plan、架构文档和调试文档

## 5. 明确不做

- 不接远程 telemetry 服务
- 不记录音频内容、完整 transcript、剪贴板正文、Refine 正文
- 不试图把所有第三方 App 变成全自动回归主战场
- 不为了自驱 smoke 改坏正常产品热路径
- 不在这一轮扩张 `Refine` 产品能力

## 6. 执行顺序

1. 更新 live plan，锁定这一轮是开发用可观测性与自驱闭环
2. 先给热路径补统一 trace：交互 ID、阶段耗时、结果码
3. 增加本地 trace 摘要脚本，降低日志阅读成本
4. 增加 smoke hot path 模式，用自动驱动文本 + 稳定测试宿主跑完整链路
5. 增加稳定测试宿主与相关测试
6. 更新文档并跑全量验证

## 7. 完成定义

满足以下条件才算这一轮完成：

- 同一次热路径交互能被统一 `interaction_id` 串联
- 日志能直接看出主要阶段耗时和最终结果
- 本地有摘要命令，不需要每次手工读整段 `log show`
- 我可以在本地跑自驱 smoke，覆盖热路径主链路
- 稳定测试宿主可以承接自动注入基线测试
- 文档明确写出“哪些能自动闭环，哪些仍然需要少量人工验收”

## 8. 阻塞项

- 当前无外部阻塞
- 与真实第三方 App 的最终行为仍然受系统权限、第三方 UI 状态和 App 版本影响

## 9. 最近完成

- `Word Correction` 已回到 `TermDictionary` 之下的被动词级学习模型
- 单次手动修正现在只记录本地观察证据，不再直接新增 `pending candidate`
- 同一 `alias -> canonical` 默认连续一致 `3` 次后自动晋升进 `TermDictionary`
- 冲突映射不会自动晋升，句子级改写不会进入词典学习
- `Settings` 右侧已改成被动学习说明与观察计数；`pending candidate` 只作为旧本地数据的兼容显示保留
- 项目已经收敛到 `OSLog.Logger + make logs + make probe-compose` 的统一调试入口
- 本轮已完成：热路径已经补上统一 `interaction_id`、结果码和阶段耗时摘要
- 本轮已完成：本地新增 `make traces`，不再需要每次手工翻整段 unified log
- 本轮已完成：`SpeakDock` 已支持 smoke hot path mode，可在不依赖真实 `Fn` 和真实说话的前提下自驱热路径
- 本轮已完成：`SpeakDockTestHost` 与 `make smoke-compose` 已落地，可自动验证最小 Compose 注入闭环
