# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：`docs 真值源收口`
- 状态：`Completed`（待下一轮 focus 接管）

## 3. 为什么现在做

当前热路径、诊断入口和词级学习链路已经基本稳定，但 docs 里还存在一个更直接的风险：实现已经往前推进，活文档的术语和候选方向却开始混写。

- `Refine / ASR Correction / WikiCompiler` 的实现名、研究名和对外表达没有完全统一
- `Qwen3-ASR-0.6B via MLX` 在部分文档里被写得过于像已锁定实现
- `CURRENT / review / docs index` 里还残留旧 focus、空壳 review 和过期索引

这一轮先收口文档，比直接继续加功能更值，因为：

- 不先收口，下一阶段接本地 ASR、Wiki 和 workspace 行为时会继续漂
- 这属于低复杂度、高确定性的修正，不引入新的产品状态
- 当前用户和实现都需要一份唯一正确的术语表

所以这一轮不追新入口，只把真值源重新对齐。

## 4. 本轮范围

1. 统一产品术语：`Streaming Preview / ASR Post-Correction / Workspace Refine / Wiki Compile`
2. 把 `Qwen3-ASR-0.6B via MLX` 明确回“优先候选方向”，不写成已锁定实现
3. 把 `Wiki` 默认浏览方式写死为“本地 HTTP server + 浏览器打开 `wiki/` 根目录”
4. 修复 `CURRENT / review / docs index / README` 的活文档状态
5. 明确 research 只是研究输入，不能反向覆盖架构主模型

## 5. 明确不做

- 不在这一轮接入本地 ASR 模型
- 不在这一轮实现 `Wiki Compile`
- 不把 research 脑爆直接升级成架构承诺
- 不为了术语对齐去做全仓实现名 mass rename

## 6. 执行顺序

1. 先收口 `ARCHITECTURE` 的术语、候选边界和 Wiki 浏览方式
2. 再同步 `README / README.zh-CN`
3. 然后修复 `CURRENT / review / docs index`
4. 最后检查 research 是否仍然越界

## 7. 完成定义

满足以下条件才算完成：

- `ARCHITECTURE / README / CURRENT` 对核心术语口径一致
- live 文档不再出现“待定 + 旧 focus 混写”或空壳 review
- `Qwen / Refine / Wiki` 的文档边界清楚区分“已定 / 候选 / 研究”
- research 继续保留，但不再反向覆盖真值源

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- 已完成：`ARCHITECTURE` 已补统一术语表，明确 `Streaming Preview / ASR Post-Correction / Workspace Refine / Wiki Compile`
- 已完成：`Qwen3-ASR-0.6B via MLX` 已回收到“优先候选方向”，不再在真值源里当成已锁定实现
- 已完成：`Wiki` 默认浏览方式已明确为“本地 HTTP server + 浏览器打开 `wiki/` 根目录”
- 已完成：`CURRENT / review / docs index / README` 已重新收口，活文档不再混写旧 focus

## 10. 下一轮建议

- 补一页独立的端侧 ASR 候选评测文档，再决定模型、量化和运行形态
- 回到 `ActiveWorkspace + SecondaryAction` 主线，继续推进 `Compose / Capture` 的下一轮实现
