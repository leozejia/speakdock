# SpeakDock Current Focus

## 1. 用途

这份文档是当前唯一 live doc。

- 同时承担 `live plan` 和 `live review`
- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、复核结论和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：`ASR Post-Correction provider 收口与端侧 server 生命周期接线`
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
- 当前 app 内最小接线路由已经固定为 `provider`：
  - `disabled`
  - `onDevice`
  - `customEndpoint`
- `onDevice` 第一版固定方案已经写死为：
  - 直接复用外部 `mlx_lm.server`
  - SpeakDock 负责拉起、重配和停止
  - app 退出时必须关闭它自己拉起的 server
  - 默认 loopback endpoint 固定为 `http://127.0.0.1:42100/v1`
  - 默认模型固定为 `Qwen3.5-2B-OptiQ-4bit`
  - 不要求 `apiKey`
- `customEndpoint` 继续保留给云端或用户自定义服务
- 当前这一轮明确不做：
  - 下载器
  - 常驻 daemon
  - model inventory
  - readiness / 健康检查页面
- 当前默认产品行为仍然保持：
  - `ASR Post-Correction` 是可选层，默认关闭
  - 失败直接回退到 `Clean`
  - `Workspace Refine` 继续与它分层，不混写
- 当前最小运行期诊断已经补上：
  - `mlx_lm.server` 找不到时，直接判失败，不再静默尝试
  - 端侧 server 启动后会轮询 `/v1/models`
  - 设置页会显示 `starting / ready / failed`
  - 日志会明确写出启动失败或 readiness 失败
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
- 本轮 live focus 已从“评测收口”切到“provider 与生命周期接线”

## 4. 为什么现在做

第二轮 research 已经把方向收住了，runner 也已经落地，本地 `2B` 线也不再停留在早期试探阶段。

- 如果不把当前状态写死，后续很容易又回到“继续加 prompt 看看”的旧状态
- 当前已经不缺评测入口，也不缺候选池，缺的是把已收敛结论接回真实路由
- 如果 provider、运行方式和生命周期不先写死，后面又会回到“模型测了很多，但 app 没真正接上”的旧状态
- 只有先把“哪条线成立、成立到什么程度、由谁管理生命周期”写死，下一轮实现才不会重新扩散

所以当前阶段转为：

- 本地 provider 契约固定为 `disabled / onDevice / customEndpoint`
- `onDevice` 第一版固定为 `mlx_lm.server`
- SpeakDock 接手它的生命周期，settings 变化同步，app 退出即停
- 最小诊断与保护已经落地，下一步只允许做更小的模型可用性细化，不继续扩大 prompt 实验面

## 5. 本轮范围

1. 把 `ASR Post-Correction` 的 provider 契约写进 live doc
2. 把 `Settings -> runtime resolve -> hot path` 的配置链接起来
3. 让 `onDevice` provider 通过 `mlx_lm.server` 跑在独立进程里
4. 让 SpeakDock 负责启动、重配和退出时停服
5. 同步 `CURRENT` 与架构文档

## 6. 明确不做

- 不做模型下载器
- 不做系统常驻 daemon
- 不做 model inventory
- 不做 provider 健康检查页
- 不在这一轮改 `Workspace Refine`
- 不在这一轮替换 Apple Speech
- 不把 `Compose / Capture` 拆成两套路由

## 7. 执行顺序

1. 先固定文档里的 provider 与生命周期边界
2. 再把 `Settings -> resolver -> runtime` 接起来
3. 然后让 `onDevice` provider 通过 `mlx_lm.server` 受 SpeakDock 生命周期管理
4. 最后进入最小诊断与运行期保护

## 8. 完成定义

满足以下条件才算完成：

- `provider` 合同已经固定为 `disabled / onDevice / customEndpoint`
- `onDevice` 默认配置已经固定到 loopback `mlx_lm.server`
- `onDevice` 不再要求 `apiKey`
- SpeakDock 已能在启动时同步 provider 配置
- settings 变化时已能重配或停掉端侧 server
- app 退出时已能关闭它拉起的 server
- 缺少 `mlx_lm.server` 时已能明确失败
- `onDevice` 已有最小 readiness 探测与设置页状态反馈
- `CURRENT` 与 `ARCHITECTURE` 已同步到同一口径
- 不需要再靠口头解释“到底谁管 server 生命周期”

## 9. 下一轮候选

- model 可用性与缺失原因细化
- provider 失败细节收束
- `Workspace Refine` prompt 重定义

## 10. 当前不进入下一轮的项

- 不重新打开本地 `Workspace Refine` 默认路线
- 不提前把 `Qwen3-ASR` 混进文本后纠错线
- 不重新开始本地文本模型 shortlist
- 不把端侧 server 升级成系统常驻服务

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
- 已完成：`ASR Post-Correction` provider 契约已收口到 `disabled / onDevice / customEndpoint`
- 已完成：`onDevice` 第一版已固定为由 SpeakDock 管理生命周期的 `mlx_lm.server`
- 已完成：`mlx_lm.server` 缺失诊断、readiness 探测和设置页状态反馈已落地
