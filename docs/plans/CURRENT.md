# SpeakDock Current Focus

## 1. 用途

这份文档是当前唯一 live doc。

- 同时承担 `live plan` 和 `live review`
- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、复核结论和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：`端侧模型收口：仅保留 ASR Post-Correction，本地 Refine 退出默认路线`
- 状态：`In Progress`

## 3. 当前复核结论

- 端侧模型调研必须按角色拆开推进：`ASR / ASR Post-Correction / Workspace Refine`
- 当前产品决策已收口：端侧小模型只保留给 `ASR Post-Correction`
- `Workspace Refine` 默认走云端 LLM，不再把本地 `Refine` 当产品默认路线
- 高性能机器可通过用户自定义方式接本地 `Refine`，但这不进入当前 baseline
- 本轮调研只接受官方/一手资料：官方 repo、官方技术报告、官方模型卡、官方框架文档
- Apple Speech 继续作为系统基线，不因候选模型调研而被提前移出比较集

## 4. 为什么现在做

当前热路径已经稳定到足以开始做下一轮架构判断，但“哪些能力值得端侧化”刚刚得到新的硬件边界。

- 我们已经知道 Apple Speech 是当前可用基线，但它不是长期准确率终局
- `Qwen3-ASR / Whisper / SenseVoice / Moonshine` 的官方资料收敛已经开始有结论
- 机器边界已经明确：`Apple Silicon M3 / 16GB / macOS 15.7.4`
- 这台 `MacBook Air 16GB` 已被确定为底线机器，意味着重型本地 `Refine` 方案不值得进入默认路线
- 如果不先把这个边界写死，后续实现会继续把“高配可选”“产品默认”“研究候选”混在一起

这一轮先做收口与测评设计，比直接写模型接入层更值，因为：

- 这决定后续到底先接哪个模型、测什么、以及哪些候选直接 `pass`
- 这是低风险、高确定性的文档推进，不会引入新的运行时复杂度
- 先把“产品默认”“高配可选”“不进入主线”写清楚，可以减少后续无效试错

所以这一轮不接模型，只收敛证据、边界和测评方法。

## 5. 本轮范围

1. 保留并索引一页独立的 `ASR` 官方资料研究
2. 把端侧文本模型主线收口到 `ASR Post-Correction`
3. 明确 `Workspace Refine` 默认走云端 LLM，本地 `Refine` 只保留为用户自定义扩展
4. 固定第一轮测评前提：`Apple M3 / 16 GB / macOS 15.7.4`
5. 产出总研究页，写清哪些方案进入主线、哪些方案只留作高配可选
6. 同步 `CURRENT / docs index`，确保 live doc 与 research 索引同轨

## 6. 明确不做

- 不在这一轮接入任何本地 ASR 模型
- 不在这一轮直接落本地 `ASR Post-Correction` 或 `Workspace Refine` 实现
- 不使用二手博客、第三方评测视频或社区跑分贴
- 不因为某个候选“看起来强”就提前锁定实现路径
- 不把 `4B` 级本地 `Refine` 写进产品默认路线

## 7. 执行顺序

1. 先保留 `ASR` 子题的一手资料结论
2. 再把文本模型主线收口到 `ASR Post-Correction`
3. 然后产出总研究页与第一轮测评设计
4. 最后把 docs index 对齐，为下一轮实测或可行性 spike 做准备

## 8. 完成定义

满足以下条件才算完成：

- `ASR` 已有独立一手资料研究页
- 文本模型主线已经明确收口到 `ASR Post-Correction`
- `Workspace Refine` 已明确为云端默认，本地只作高配自定义扩展
- 总研究页已经写清第一轮 shortlist 与测评设计
- 当前机器边界 `M3 / 16GB / macOS 15.7.4` 已进入判断前提
- 下一轮可以直接基于这份结论制定实测名单或可行性 spike 顺序

## 9. 下一轮候选

- `ASR` shortlist 的实测设计与样本集定义
- `ASR Post-Correction` 的最小可行性 spike
- `Workspace Refine` 的云端 provider 能力与失败回退设计

## 10. 当前不进入下一轮的项

- 不锁死 sidecar 常驻、量化方案或具体 Swift 桥接形态
- 不提前决定 streaming 与 final transcript 是否由同一模型承担
- 不把 `Apple Foundation Models` 误写成当前系统版本即可落地主线
- 不再推进本地 `Workspace Refine` 作为产品默认能力

## 11. 阻塞项

- 当前无外部阻塞

## 12. 最近完成

- 已完成：`ARCHITECTURE / CURRENT / docs index` 已重新收口到单活文档结构
- 已完成：`Qwen3-ASR-0.6B via MLX` 已被回收到“候选方向”而不是“既定实现”
- 已完成：`Streaming Preview / ASR Post-Correction / Workspace Refine / Wiki Compile` 已成为当前统一术语
- 已完成：`ASR` 一手资料 research 已落地，当前可用作下一页总研究文档的子输入
- 已完成：产品默认路线已收口为“端侧只保留 `ASR Post-Correction`，`Workspace Refine` 默认云端”
