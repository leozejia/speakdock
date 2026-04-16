# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后归档快照，再重写下一轮
- 不在这里堆长期想法、研究摘录或历史过程

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：把 `Refine` 收回到 workspace 级整理，并改成 submit 前批量处理
- 状态：`Completed`

## 3. 为什么现在做

词典被动学习和开发用观测闭环已经落地，但当前 `Refine` 的触发时机还停留在旧实现：

- 当前代码仍会在每次录音松手后对单段文本 inline 整理，再立即提交
- 这和现在确认过的产品模型冲突：词级纠错属于 `TermDictionary`，句子级表达整理属于整个 `Workspace`
- 用户真实感知应该是“边说边写，必要时手改，发送前才对整块工作区做一次可选整理”
- 如果不先把 `Refine` 的边界和触发时机校正，后面再接端侧小模型或更强整理时会继续放大偏差

这一轮的目标是把实现拉回当前产品心智：

1. 录音阶段只做 `ASR -> Clean -> Workspace append`
2. `Refine` 只处理当前整个 `Workspace` 的表达整理，不承担词级纠错
3. 自动整理的默认触发点改到 `submit` 前，而不是每次说完一段就触发
4. 手动整理入口继续保留，作为显式整理和调试入口

## 4. 本轮范围

1. 更新 live plan、架构文档和手测文档，写清 `TermDictionary / Refine / Workspace` 新边界
2. 把自动整理从“录音后 inline”改成“submit 前针对整个 workspace”
3. 保留手动整理 / 撤回能力，但不再把它当成默认热路径
4. 同步设置页与菜单里的 `Refine` 文案，让它描述“发送前整理工作区”而不是“逐段 cleanup”
5. 跑定向测试、自驱 smoke 和全量验证，确保热路径没有被改坏

## 5. 明确不做

- 不在这一轮引入端侧小模型
- 不把句子级修改纳入词典学习
- 不做风格画像、翻译模式或多档整理强度切换
- 不重做整套 workspace 数据模型
- 不牺牲现有 smoke / trace / probe 调试入口

## 6. 执行顺序

1. 更新 live plan，锁定这一轮是 workspace 级整理时机校正
2. 先用测试钉住“录音阶段不自动整理，submit 前才整理整个 workspace”
3. 改造 `HotPathCoordinator` 和相关 helper，把默认整理触发点移到 submit 前
4. 同步 Settings / Menu / 手测文案
5. 跑定向测试、smoke 和全量验证

## 7. 完成定义

满足以下条件才算这一轮完成：

- 一次录音释放后只追加 clean 文本，不再自动触发 `Refine`
- `submit` 前会基于当前 `Workspace` 做一次可选整理；失败时自动回退到未整理文本
- 手动整理 / 撤回仍然成立
- `TermDictionary` 和 `Refine` 的职责边界在文档与代码里一致
- 设置页、菜单和手测文案都不再描述旧的逐段 inline 整理

## 8. 阻塞项

- 当前无外部阻塞
- `submit` 前整理会再次触达当前 compose target，可用性仍然受第三方 App AX 状态影响

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
- 本轮已完成：录音阶段不再自动触发 `Refine`，现在只做 `Clean -> Workspace append`
- 本轮已完成：`submit` 前会基于当前整个 workspace 做一次可选整理；失败时直接回退到当前工作区文本
- 本轮已完成：手动整理现在优先读取当前工作区真实文本，而不是只看旧的 `raw_context`
- 本轮已完成：Settings / Menu / 手测文档已改成“发送前整理当前工作区”的表述，不再描述旧的逐段 inline 整理
