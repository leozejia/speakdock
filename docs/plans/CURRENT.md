# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：补本地 `trace-report` 汇总入口，沉淀 `Refine / Smoke / 延迟` 的开发样本基线
- 状态：`Completed`

## 3. 为什么现在做

上一轮已经补齐：

- `make smoke-compose`
- `make smoke-refine`
- `make traces`

但现在的 trace 仍然只是“原始行输出”，还不够支撑下一阶段判断：

- `Refine` 最近到底成功了多少次，失败了多少次
- smoke 路径和 live 路径的结果分布是否稳定
- 热路径总耗时、提交耗时是否在漂

架构文档已经写清楚，在进入端侧小模型研究前，必须先有：

1. `Refine` 质量和延迟样本
2. 术语词典命中与误伤样本
3. 更稳定的本地调试观察入口

所以这一轮先不碰模型本身，先把本地 trace 变成“可汇总的样本入口”。

## 4. 本轮范围

1. 新增 `make trace-report`
2. 把 `trace.finish` 聚合成结果分布和延迟摘要
3. 支持脚本直接读 unified log，也支持从 `stdin` 喂样本，方便测试
4. 同步 README、手测文档、架构文档和 Swift 踩坑文档
5. 跑定向测试、全量测试和 smoke，再用真实 recent trace 验证输出

## 5. 明确不做

- 不接远程 telemetry 服务
- 不写新的本地数据库或持久化样本仓
- 不改产品热路径
- 不改 `Refine` 提示词或模型策略
- 不扩第三方 App 自动回归矩阵

## 6. 执行顺序

1. 更新 live plan，锁定本轮是 `trace-report`
2. 先写脚本执行测试，钉住摘要输出格式
3. 新增 `report-traces.py` 与 `Makefile` 入口
4. 同步文档
5. 跑测试、smoke 和真实 `trace-report`

## 7. 完成定义

满足以下条件才算完成：

- `make trace-report TRACE_WINDOW=5m` 能直接输出可读摘要
- 脚本支持从 `stdin` 读取 trace 样本，便于自动测试
- 至少能看到 `kind / result / origin / route / latency` 五类摘要
- README、手测文档和技术文档都能找到这条入口
- `make test`、`make smoke-compose`、`make smoke-refine` 仍然通过

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- 上一轮已完成：新增 `make smoke-refine`，本地可自驱 `Refine HTTP -> apply -> submit`
- 上一轮已完成：新增本地 OpenAI-compatible stub server，不再依赖真实远端接口做基础回归
- 上一轮已完成：smoke refine 只在运行时注入配置，不污染用户真实 refine 设置
- 上一轮已完成：smoke host ready 时序和状态落盘等待已补稳，`smoke-compose / smoke-refine` 可重复回归
- 更早已完成：项目已经收敛到 `OSLog.Logger + make logs + make traces` 的统一调试入口
- 本轮已完成：新增 `make trace-report`，可本地汇总最近 `trace.finish` 的结果分布和延迟
- 本轮已完成：`trace-report` 默认直读 unified log，也支持显式 `--stdin` 样本输入，便于自动测试
