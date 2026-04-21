# SpeakDock Current Focus

## 1. 用途

这份文档是当前唯一 live doc。

- 同时承担 `live plan` 和 `live review`
- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、复核结论和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：`端侧 ASR 官方资料调研与 shortlist 收敛`
- 状态：`In Progress`

## 3. 当前复核结论

- `Qwen3-ASR-0.6B via MLX` 仍然只能算候选方向，不能越级写成已锁定实现
- 端侧模型调研必须按角色拆开推进，当前只先收 `ASR`，不把 `ASR Post-Correction / Workspace Refine` 混进同一轮
- 本轮调研只接受官方/一手资料：官方 repo、官方技术报告、官方模型卡、官方框架文档
- Apple Speech 继续作为系统基线，不因候选模型调研而被提前移出比较集

## 4. 为什么现在做

当前热路径已经稳定到足以开始做下一轮架构判断，但端侧 ASR 仍然停留在“方向判断”而不是“证据判断”。

- 我们已经知道 Apple Speech 是当前可用基线，但它不是长期准确率终局
- `Qwen3-ASR / Whisper / SenseVoice / Moonshine` 的讨论已经开始出现，但还没有一份只基于官方资料的收敛结论
- 机器边界已经明确：`Apple Silicon M3 / 16GB / macOS 15.7.4`
- 如果不先把候选收敛，后续实现会把“社区口碑”“二手经验”和“架构承诺”混在一起

这一轮先做官方资料调研与 shortlist 收敛，比直接写模型接入层更值，因为：

- 这决定后续到底先接哪个模型、测什么、以及哪些候选只配做对照组
- 这是低风险、高确定性的文档推进，不会引入新的运行时复杂度
- 先把“值得测”和“不值得先测”写清楚，可以减少后续无效试错

所以这一轮不接模型，只收敛证据、候选和测评入口。

## 5. 本轮范围

1. 只基于官方资料复核 `Apple Speech / Qwen3-ASR-0.6B / Whisper / SenseVoice / Moonshine`
2. 对每个候选写清楚：官方来源、擅长、不擅长、是否值得进中文实时语音输入 shortlist
3. 明确哪些判断已经有官方证据，哪些地方仍然资料不足
4. 形成可直接进入后续综合 research doc 的 ASR 子提纲
5. 同步 `CURRENT / docs index`，确保 live doc 与 research 索引同轨

## 6. 明确不做

- 不在这一轮接入任何本地 ASR 模型
- 不在这一轮开始 `ASR Post-Correction` 或 `Workspace Refine` 模型筛选
- 不使用二手博客、第三方评测视频或社区跑分贴
- 不因为某个候选“看起来强”就提前锁定实现路径

## 7. 执行顺序

1. 先完成 ASR 候选的官方资料收集
2. 再输出候选对比与 shortlist 判断
3. 然后把 research 文档与 docs index 对齐
4. 最后再进入下一轮模型测评设计

## 8. 完成定义

满足以下条件才算完成：

- 五个 ASR 候选都已有官方来源落表
- 每个候选都已有明确的 `擅长 / 不擅长 / shortlist 判断 / 资料缺口`
- 当前机器边界 `M3 / 16GB / macOS 15.7.4` 已进入判断前提
- 下一轮可以直接基于这份结论制定实测名单

## 9. 下一轮候选

- 端侧 ASR shortlist 的实测设计与样本集定义
- `ASR Post-Correction` 的候选研究与角色边界
- `Workspace Refine` 的本地/远端模型筛选

## 10. 当前不进入下一轮的项

- 不锁死 sidecar 常驻、量化方案或具体 Swift 桥接形态
- 不提前决定 streaming 与 final transcript 是否由同一模型承担

## 11. 阻塞项

- 当前无外部阻塞

## 12. 最近完成

- 已完成：`ARCHITECTURE / CURRENT / docs index` 已重新收口到单活文档结构
- 已完成：`Qwen3-ASR-0.6B via MLX` 已被回收到“候选方向”而不是“既定实现”
- 已完成：`Streaming Preview / ASR Post-Correction / Workspace Refine / Wiki Compile` 已成为当前统一术语
