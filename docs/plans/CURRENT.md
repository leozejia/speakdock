# SpeakDock Current Focus

## 1. 用途

这份文档是当前唯一 live doc。

- 同时承担 `live plan` 和 `live review`
- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、复核结论和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：`ASR Post-Correction 双轨基线固定，准备最小接线`
- 状态：`In Progress`

## 3. 当前复核结论

- 第二轮 research 已完成，当前不再继续扩大候选池
- `ASR Post-Correction` 继续保持：
  - 社区运行优化版优先
  - 官方原版只在结果异常时作为诊断锚点
- 当前精确顺序已收敛为：
  - 主候选：`mlx-community/Qwen3.5-2B-OptiQ-4bit`
  - 对照候选：`mlx-community/Qwen3.5-2B-4bit`
  - 结构替代：`mlx-community/gemma-3-1b-it-4bit`
  - 独立 ASR 线：`mlx-community/Qwen3-ASR-0.6B-4bit`
- 两个 `4bit` 不是同一个东西：
  - `Qwen3.5-2B-4bit` 是普通统一 `4-bit` 转换版
  - `Qwen3.5-2B-OptiQ-4bit` 是 `4/8-bit` 混合精度版，目标 `4.5 BPW`
- 首轮真实结果已经足够排除 `0.8B` 线：
  - `mlx-community/Qwen3.5-0.8B-OptiQ-4bit`：`12/48`
  - `mlx-community/Qwen3.5-0.8B-4bit`：`9/48`
  - `Qwen/Qwen3.5-0.8B`：`12/48`
- 同一套 few-shot 夹具下，`2B` 线结果为：
  - `mlx-community/Qwen3.5-2B-OptiQ-4bit`：`15/48`，`over-edit = 1`
  - `mlx-community/Qwen3.5-2B-4bit`：`13/48`，`over-edit = 2`
- 当前 `2B-OptiQ-4bit` 的 prompt profile 对照结果为：
  - `fewshot`：`16/48`，`over-edit = 1`
  - `fewshot_terms`：`24/48`，`over-edit = 1`
  - `fewshot_terms_homophone`：`28/48`，`over-edit = 1`
- 当前 `2B-OptiQ-4bit` 在“工程片段提示”这一轮之后更新为：
  - `fewshot_terms_homophone + engineering fragment hints`：`33/48`，`over-edit = 1`
  - `mixed` 从 `5/12` 提升到 `8/12`
  - `term` 从 `5/12` 提升到 `7/12`
  - `homophone` 仍停在 `7/12`
  - `p50 latency` 从约 `1081ms` 降到约 `949ms`
  - `p95 latency` 从约 `1637ms` 降到约 `1162ms`
- 当前 `2B-OptiQ-4bit` 在“命中式术语 / 同音 / 模型 ID 提示”这一轮之后更新为：
  - `fewshot_terms_homophone + hit-based hints`：`44/48`，重跑仍为 `44/48`
  - `over-edit = 1`
  - `fallback = 0`
  - `term = 11/12`
  - `mixed = 10/12`
  - `homophone = 12/12`
  - `control = 11/12`
  - `p50 latency ≈ 948ms`
  - `p95 latency ≈ 1242ms`
  - `peak rss ≈ 905MB ~ 1029MB`
- 当前剩余 4 个误差已经收敛到小边角：
  - `Apple Speech` 大小写
  - `Qwen` 首字母大小写
  - 个别中文前缀丢失
  - 个别句末标点被抹平
- 当前结论已经从“继续猜 prompt”切换为：
  - `2B-OptiQ-4bit` 已经是唯一成立的本地后纠错候选
  - 当前最佳 eval profile 仍是 `fewshot_terms_homophone`
  - 当前命中式提示层已经把本地线推进到可准备接线的门槛
  - 下一步应转为最小接线路由与运行期保护，不再继续无脑堆提示
- `ASR Post-Correction` 是路由前层，不单独区分 `Compose / Capture`
- 当前 app 已经具备现成接线积木：
  - `ASRCorrectionEngine`
  - `make asr-post-correction-eval`
  - `make asr-post-correction-eval-report`
  - `make smoke-asr-correction`
  - `make asr-correction-report`
  - `make asr-sample-report`
- checked-in runner 已经能真实跑 `mlx-community/Qwen3.5-2B-OptiQ-4bit`
- `make asr-post-correction-eval` 默认 profile 已切到 `fewshot_terms_homophone`
- 已补最小远端对比入口：
  - `make asr-post-correction-openai-eval`
  - 本地 `.env` / `.env.example`
  - 仅用于离线评测对比，不接入 app 默认热路径
- 首轮远端对比结果已经拿到：
  - `gpt-5.4` via OpenAI-compatible：`38/48`
  - `over-edit = 1`
  - `term = 11/12`
  - `mixed = 6/12`
  - `homophone = 10/12`
  - `control = 11/12`
  - `p50 latency ≈ 2445ms`
  - `p95 latency ≈ 5135ms`
- 云端候选本轮已完成第一轮固定：
  - `gpt-5.3-chat-latest`：`40/48`；重跑 `39/48`
  - `gpt-5.3-codex-spark`：`39/48`
  - `gpt-5.4`：`38/48`；重跑 `37/48`
  - `gpt-5.4-mini`：`37/48`
  - 当前默认推荐：`gpt-5.3-chat-latest`
  - 不推荐默认使用 `gpt-5.3-codex-spark`
  - 原因不是它不能用，而是：
    - 它是 `Codex` 实时编程专用线
    - 在产品定位上不该作为 SpeakDock 的通用后纠错默认模型
    - 它还有独立的 `Codex` 限额和速率口径
- 当前固定夹具下，本地线已经超过云端默认线：
  - 本地 `2B-OptiQ-4bit`：`44/48`
  - 云端 `gpt-5.3-chat-latest`：`40/48`
  - 这只是当前 SpeakDock 域内夹具结论，不外推成通用模型结论
- runner 已覆盖一个真实踩坑：
  - `peak_rss_mb` 必须兼容 bytes / kilobytes 两种 `ru_maxrss` 单位
  - 模型偶发吐出 `输入 / 输出` 包裹层时，runner 必须做清洗
  - 某些 Cloudflare 风格的 OpenAI-compatible 网关会拒绝 Python 默认请求形态，远端 eval 需要走 `curl`
  - 对本地 `2B` 来说，追加“只在命中时出现”的工程片段提示，比继续无脑堆 few-shot 更值
- 本轮 live focus 继续不碰默认热路径，但已经进入“准备最小接线”的阶段

## 4. 为什么现在做

第二轮 research 已经把方向收住了，runner 也已经落地，本地 `2B` 线也不再停留在早期试探阶段。

- 如果不把当前状态写死，后续很容易又回到“继续加 prompt 看看”的旧状态
- 当前已经不缺评测入口，也不缺候选池，缺的是把已收敛结论接回真实路由
- 只有先把“哪条线成立、成立到什么程度”写死，下一轮实现才不会重新扩散

所以当前阶段转为：

- 云端默认线固定到 `gpt-5.3-chat-latest`
- 本地线固定到 `mlx-community/Qwen3.5-2B-OptiQ-4bit + fewshot_terms_homophone`
- 下一步只允许做最小接线与保护，不继续扩大 prompt 实验面

## 5. 本轮范围

1. 把本地 `2B` 最新 `44/48` 结果写回 live doc
2. 固定当前本地默认评测组合，不再继续扩候选
3. 为下一步 app 内最小接线明确边界
4. 只保留极小输出保护项，不引入重后处理链
5. 同步 `CURRENT`

## 6. 明确不做

- 不在这一轮继续扩大候选池
- 不在这一轮继续堆新的 prompt 花样
- 不在这一轮改 `Workspace Refine`
- 不在这一轮替换 Apple Speech
- 不把 `Compose / Capture` 拆成两套评测
- 不把 `Codex-Spark` 误写成 SpeakDock 的通用默认模型
- 不做重量级文本后处理管线

## 7. 执行顺序

1. 先固定文档里的双轨基线
2. 再以 `mlx-community/Qwen3.5-2B-OptiQ-4bit` 作为唯一本地接线候选
3. 然后只补最小运行期保护
4. 最后再决定是否灰度进入真实热路径

## 8. 完成定义

满足以下条件才算完成：

- 已有独立的 `ASR Post-Correction` 最小实测设计页
- 样本真源、bucket、字段、数量已经写死
- `0.8B` 与 `2B` 的首轮结果已经写回文档
- 当前唯一继续候选已经收敛到 `mlx-community/Qwen3.5-2B-OptiQ-4bit`
- checked-in runner 与 make 入口已经落地
- 当前最佳 profile 已经收敛到 `fewshot_terms_homophone`
- 当前本地最佳结果已经稳定在 `44/48`
- 不需要再靠口头解释“为什么是这版，不是那版”

## 9. 下一轮候选

- `ASR Post-Correction` app 内最小接线路由
- 极小输出保护项
- `Workspace Refine` prompt 重定义

## 10. 当前不进入下一轮的项

- 不重新打开本地 `Workspace Refine` 默认路线
- 不提前把 `Qwen3-ASR` 混进文本后纠错线
- 不重新开始本地文本模型 shortlist

## 11. 阻塞项

- 当前无外部阻塞

## 12. 最近完成

- 已完成：`第二轮调研：ASR Post-Correction 与云端 Refine` 已归档
- 已完成：`Qwen3-ASR / Qwen3.5-Omni / 文本后纠错模型` 的命名边界纠偏
- 已完成：`ASR Post-Correction` 最小 shortlist 已收口
- 已完成：`ASR Post-Correction` 最小实测设计页已落地
- 已完成：匿名基线夹具、离线评测报表脚本与 `make asr-post-correction-eval-report` 入口已落地
- 已完成：`0.8B / 2B / OptiQ / 普通 4bit` 的首轮真实对照
- 已完成：当前唯一继续候选收敛到 `mlx-community/Qwen3.5-2B-OptiQ-4bit`
- 已完成：checked-in `run-asr-post-correction-eval.py` 与 `make asr-post-correction-eval` 入口已落地
- 已完成：runner 真实回归已验证，并修正 `peak_rss_mb` 单位归一化
- 已完成：`fewshot / fewshot_terms / fewshot_terms_homophone` 的首轮 prompt 对照
- 已完成：默认 eval profile 已切到 `fewshot_terms_homophone`
- 已完成：本地 `2B` 的工程片段提示层已落地，真实结果从 `28/48` 提升到 `33/48`
- 已完成：本地 `2B` 的命中式术语 / 同音 / 模型 ID 提示层已落地，真实结果从 `33/48` 提升到 `44/48`
- 已完成：同一夹具下，本地 `2B` 结果已超过当前云端默认线
