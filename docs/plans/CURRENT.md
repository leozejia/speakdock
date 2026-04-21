# SpeakDock Current Focus

## 1. 用途

这份文档是当前唯一 live doc。

- 同时承担 `live plan` 和 `live review`
- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、复核结论和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：`端侧小模型深度调研与候选测评`
- 状态：`In Progress`

## 3. 当前复核结论

- 端侧模型调研必须按角色拆开推进：`ASR / ASR Post-Correction / Workspace Refine`
- `Qwen3-ASR-0.6B via MLX` 仍然只能算候选方向，不能越级写成已锁定实现
- 本轮调研只接受官方/一手资料：官方 repo、官方技术报告、官方模型卡、官方框架文档
- Apple Speech 继续作为系统基线，不因候选模型调研而被提前移出比较集
- `ASR` 的官方资料收敛已经完成第一轮，当前进入文本模型筛选与总测评设计

## 4. 为什么现在做

当前热路径已经稳定到足以开始做下一轮架构判断，但端侧模型仍然停留在“方向判断”而不是“证据判断”。

- 我们已经知道 Apple Speech 是当前可用基线，但它不是长期准确率终局
- `Qwen3-ASR / Whisper / SenseVoice / Moonshine` 的官方资料收敛已经开始有结论
- 文本模型候选如果不继续往下做，就会只剩“大家都觉得可能行”的泛化判断
- 机器边界已经明确：`Apple Silicon M3 / 16GB / macOS 15.7.4`
- 如果不先把候选收敛，后续实现会把“社区口碑”“二手经验”和“架构承诺”混在一起

这一轮先做深调研、shortlist 收敛与测评设计，比直接写模型接入层更值，因为：

- 这决定后续到底先接哪个模型、测什么、以及哪些候选只配做对照组
- 这是低风险、高确定性的文档推进，不会引入新的运行时复杂度
- 先把“值得测”“怎么测”“不值得先测”写清楚，可以减少后续无效试错

所以这一轮不接模型，只收敛证据、候选和测评方法。

## 5. 本轮范围

1. 保留并索引一页独立的 `ASR` 官方资料研究
2. 基于官方资料继续筛文本模型候选：`Qwen3 小模型 / Gemma 3n / Gemma 3 / Apple Foundation Models / Llama 3.2 / Phi-4-mini`
3. 明确 `ASR Post-Correction` 与 `Workspace Refine` 不是同一套 shortlist
4. 固定第一轮测评前提：`Apple M3 / 16 GB / macOS 15.7.4`
5. 产出总研究页，写清候选池、淘汰理由、第一轮 shortlist 和测评设计
6. 同步 `CURRENT / docs index`，确保 live doc 与 research 索引同轨

## 6. 明确不做

- 不在这一轮接入任何本地 ASR 模型
- 不在这一轮直接落本地 `ASR Post-Correction` 或 `Workspace Refine` 实现
- 不使用二手博客、第三方评测视频或社区跑分贴
- 不因为某个候选“看起来强”就提前锁定实现路径

## 7. 执行顺序

1. 先保留 `ASR` 子题的一手资料结论
2. 再补文本模型候选筛选与角色拆分
3. 然后产出总研究页与第一轮测评设计
4. 最后把 docs index 对齐，为下一轮实测或可行性 spike 做准备

## 8. 完成定义

满足以下条件才算完成：

- `ASR` 已有独立一手资料研究页
- 文本模型候选已按 `ASR Post-Correction / Workspace Refine` 拆开筛选
- 总研究页已经写清第一轮 shortlist 与测评设计
- 当前机器边界 `M3 / 16GB / macOS 15.7.4` 已进入判断前提
- 下一轮可以直接基于这份结论制定实测名单或可行性 spike 顺序

## 9. 下一轮候选

- `ASR` shortlist 的实测设计与样本集定义
- `ASR Post-Correction` 的最小可行性 spike
- `Workspace Refine` 的端侧对照实验或 provider 接入顺序

## 10. 当前不进入下一轮的项

- 不锁死 sidecar 常驻、量化方案或具体 Swift 桥接形态
- 不提前决定 streaming 与 final transcript 是否由同一模型承担
- 不把 `Apple Foundation Models` 误写成当前系统版本即可落地主线

## 11. 阻塞项

- 当前无外部阻塞

## 12. 最近完成

- 已完成：`ARCHITECTURE / CURRENT / docs index` 已重新收口到单活文档结构
- 已完成：`Qwen3-ASR-0.6B via MLX` 已被回收到“候选方向”而不是“既定实现”
- 已完成：`Streaming Preview / ASR Post-Correction / Workspace Refine / Wiki Compile` 已成为当前统一术语
- 已完成：`ASR` 一手资料 research 已落地，当前可用作下一页总研究文档的子输入
