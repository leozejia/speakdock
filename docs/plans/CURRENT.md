# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：补 `TermDictionary` 的本地质量观察入口，沉淀真实样本与结果摘要，减少后续调优时对手翻日志的依赖
- 状态：`Ready`

## 3. 为什么现在做

现在的事实状态是：

- `TermDictionary` 的被动学习能力已经存在
- 本地 smoke 已可稳定跑通 `观察证据 -> 自动晋升 -> 下次命中`
- 但真实调优时，仍然要靠开发者自己翻日志或进本地文件，才能判断观察层到底发生了什么

这意味着现在虽然“链路可回归”，但质量判断还不够便宜：

- 最近到底记录了多少词级证据
- 哪些 `alias -> canonical` 已经接近晋升阈值
- 哪些 alias 已经出现冲突，因此被系统保守拦住
- 这些判断仍然缺一个稳定、低成本、隐私保守的本地观察入口

所以这一轮优先补的也不是模型，而是词典学习的本地质量观察层。

## 4. 本轮范围

1. 设计并落地 `TermDictionary` 的本地只读观察入口或报告入口
2. 让开发阶段能低成本看到 `observed / promoted / conflicted / skipped` 这类结果分布
3. 尽量复用现有 `trace-report / smoke-term-learning / TermDictionaryStore` 基础设施
4. 保持隐私边界，不记录或暴露完整转写正文
5. 同步 README、技术文档和手测文档
6. 跑定向测试与相关 smoke，确认旧基线不回退

## 5. 明确不做

- 不改 `Refine` 语义
- 不改模型策略
- 不把词级学习扩成句子级改写
- 不把本地观察入口做成云端依赖
- 不记录完整聊天内容、完整转写正文或剪贴板正文

## 6. 执行顺序

1. 更新 live plan，锁定这一轮是词典学习质量观察层
2. 先钉住最小行为测试，定义报告入口要暴露哪些只读事实
3. 复用已有 store / smoke / trace 基础设施补观察入口
4. 同步文档
5. 跑测试和 smoke 验证

## 7. 完成定义

满足以下条件才算完成：

- 本地存在一个便宜的观察入口，能直接看到词级学习结果摘要
- 开发者可以分辨 `观察中 / 已晋升 / 已冲突或被跳过` 的状态
- 观察入口不暴露完整正文，只保留词级最小必要信息
- README、手测文档和技术文档都能找到新的入口
- `make test`、`make smoke-term-learning` 和相关既有基线仍然通过

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- 上一轮已完成：新增 `make smoke-term-learning`，可用隔离临时词典自驱验证 `观察证据 -> 自动晋升 -> 下次命中`
- 上一轮已完成：测试宿主已支持 command file，可在自驱场景下稳定模拟用户手动改词
- 上一轮已完成：词典学习 smoke 默认强制隔离真实词典和真实 refine 配置，不污染用户本地环境
- 更早已完成：新增 `make trace-report`，可本地汇总最近 `trace.finish` 的结果分布和延迟
- 更早已完成：`trace-report` 默认直读 unified log，也支持显式 `--stdin` 样本输入，便于自动测试
- 更早已完成：新增 `make smoke-refine`，本地可自驱 `Refine HTTP -> apply -> submit`
- 更早已完成：smoke refine 只在运行时注入配置，不污染用户真实 refine 设置
- 更早已完成：smoke host ready 时序和状态落盘等待已补稳，`smoke-compose / smoke-refine` 可重复回归
- 更早已完成：项目已经收敛到 `OSLog.Logger + make logs + make traces + make trace-report + make smoke-term-learning` 的统一调试入口
