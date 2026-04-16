# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后归档快照，再重写下一轮
- 不在这里堆长期想法、研究摘录或历史过程

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：补 `Refine` 的本地自驱闭环，覆盖真实 HTTP 整理路径
- 状态：`Completed`

## 3. 为什么现在做

`Refine` 已经回到 workspace 级整理，但当前开发闭环还有一段空白：

- 现在 `smoke-compose` 只能覆盖最小 Compose 注入，不覆盖真实 `Refine` 请求编码、HTTP 往返、发送前整理和最终提交
- 如果每次验证 `Refine` 都要依赖真实远端接口和手工点击，开发效率仍然偏低
- 下一阶段接端侧模型或更强整理前，需要先有一条稳定、可重复的本地 `Refine` 基线

这一轮的目标是补上开发态最后一块关键闭环：

1. 本地起一个极小的 OpenAI-compatible stub server
2. 让 `SpeakDock` 在 smoke 模式下走真实 `Refine HTTP -> workspace apply -> submit` 路径
3. 不污染用户真实 settings 或词典
4. 把这条能力沉淀成固定命令，继续减少人工验证

## 4. 本轮范围

1. 新增 `smoke-refine` 开发命令
2. 新增本地 refine stub server 脚本
3. 扩展 smoke launch options 与 runner，让 app 能在开发态走 submit 前整理闭环
4. 只对 smoke 运行时注入 refine 配置，不改用户真实 settings
5. 同步 README、手测文档和架构文档
6. 跑定向测试、全量测试、`smoke-compose` 和 `smoke-refine`

## 5. 明确不做

- 不接真实云端接口账号
- 不新增产品层 UI
- 不改 `Refine` 提示词和产品语义
- 不扩大第三方 App 自动回归矩阵
- 不破坏现有 `smoke-compose / traces / probe-compose`

## 6. 执行顺序

1. 更新 live plan，锁定这一轮是 `Refine` 自驱闭环
2. 先用测试钉住新的 smoke 启动参数和脚本入口
3. 扩展 smoke runner 和 `HotPathCoordinator`
4. 增加本地 refine stub server 与 `smoke-refine` 命令
5. 同步文档并跑验证

## 7. 完成定义

满足以下条件才算这一轮完成：

- 本地可以通过一条命令跑完整 `Refine` smoke
- 这条 smoke 覆盖真实 HTTP 请求、响应解码、发送前整理和最终输入框结果
- smoke 运行不污染用户真实 refine 配置
- README、手测文档和架构文档都能找到这条入口
- 现有 `smoke-compose` 和全量测试仍然通过

## 8. 阻塞项

- 当前无外部阻塞
- 真实第三方 App 上的最终手感仍然要保留少量人工验收

## 9. 最近完成

- `Word Correction` 已回到 `TermDictionary` 之下的被动词级学习模型
- 单次手动修正现在只记录本地观察证据，不再直接新增 `pending candidate`
- 同一 `alias -> canonical` 默认连续一致 `3` 次后自动晋升进 `TermDictionary`
- 冲突映射不会自动晋升，句子级改写不会进入词典学习
- `Settings` 右侧已改成被动学习说明与观察计数；`pending candidate` 只作为旧本地数据的兼容显示保留
- 项目已经收敛到 `OSLog.Logger + make logs + make probe-compose` 的统一调试入口
- 上一轮已完成：热路径已经补上统一 `interaction_id`、结果码和阶段耗时摘要
- 上一轮已完成：本地新增 `make traces`，不再需要每次手工翻整段 unified log
- 上一轮已完成：`SpeakDock` 已支持 smoke hot path mode，可在不依赖真实 `Fn` 和真实说话的前提下自驱热路径
- 上一轮已完成：`SpeakDockTestHost` 与 `make smoke-compose` 已落地，可自动验证最小 Compose 注入闭环
- 上一轮已完成：录音阶段不再自动触发 `Refine`，现在只做 `Clean -> Workspace append`
- 上一轮已完成：`submit` 前会基于当前整个 workspace 做一次可选整理；失败时直接回退到当前工作区文本
- 上一轮已完成：手动整理现在优先读取当前工作区真实文本，而不是只看旧的 `raw_context`
- 上一轮已完成：Settings / Menu / 手测文档已改成“发送前整理当前工作区”的表述，不再描述旧的逐段 inline 整理
- 本轮已完成：新增 `make smoke-refine`，可在本地自驱 `Refine HTTP -> apply -> submit`
- 本轮已完成：新增本地 OpenAI-compatible stub server，不再依赖真实远端接口做基础回归
- 本轮已完成：smoke refine 只在运行时注入配置，不污染用户真实 refine 设置
- 本轮已完成：smoke host ready 时序和状态落盘等待已补稳，`smoke-compose / smoke-refine` 可重复回归
