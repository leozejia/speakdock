# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：把 `Refine` 的真实提交链路和 workspace 语义收稳，并补齐自驱验证
- 状态：`In Progress`

## 3. 为什么现在做

刚完成的上一轮，已经把词级学习热路径收稳：

- `make smoke-term-learning` 和 `make smoke-term-learning-conflict` 已串行通过
- 词典学习边界现在和真实热路径实现已经对齐
- 继续在 term-learning 上细磨，短期收益会迅速下降

下一条更值钱的主线是 `Refine`：

- `Refine` 现在同时承担“手动整理当前 workspace”和“发送前可选整理”两条路径
- 这两条路径都直接影响 `raw_context / visible_text / dirty / undo` 的关系
- 如果这里边界不稳，用户就会遇到“整理语义说不清、撤回语义不稳定、发送前行为不可预测”的问题

所以下一轮不扩 UI，不引入新模型运行时，先把 `Refine` 的真实热路径继续做扎实。

## 4. 本轮范围

1. 重新审视 `HotPathCoordinator / WorkspaceRefinePreparer / UndoFlowState / WorkspaceReducer` 的真实调用边界
2. 明确“手动整理”和“发送前整理”分别在什么条件下发生，什么场景必须保守跳过
3. 补 `Refine / fallback / dirty / undo / submit` 相关测试
4. 优先把验证做成自驱，而不是依赖人工反复点测
5. 同步文档，避免产品语义和实现再次漂移

## 5. 明确不做

- 不扩词级学习语义
- 不引入新的模型运行时
- 不做端侧小模型接入
- 不做正式打包发布
- 不改 Wiki 长线方向
- 不做新 UI 入口

## 6. 执行顺序

1. 审视现有 `Refine` 相关测试和真实调用点
2. 先补最小 failing test，锁定真实热路径里的整理边界
3. 再补最小实现或修正
4. 跑定向测试与 `make smoke-refine / make smoke-refine-manual / make smoke-refine-dirty-undo / make smoke-refine-fallback`
5. 同步文档并归档本轮结果

## 7. 完成定义

满足以下条件才算完成：

- 手动整理与发送前整理的真实触发边界，已经有明确测试覆盖
- `raw_context / visible_text / dirty / undo` 的关系是可解释且稳定的
- `fallback` 路径不会静默改写用户当前工作区语义
- 验证优先可脚本化、自驱
- 文档能准确说明新的真实边界

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- 上一轮已完成：term-learning 热路径已稳定，相关单测与 smoke 已收口
- 上一轮已完成：`TermDictionary` 的大小写不敏感、独立词边界、最长 alias 优先都已落地
- 上一轮已完成：workspace handoff 前会先做词级修正结算
- 本轮已完成：整理后继续口述会把当前可见文本吸收成新的 `raw_context` 基线，不再保留过期的撤回态
- 本轮已完成：未整理工作区如果被外部手改，同一 live workspace 的下一段口述前会先同步当前文本；这条规则现在同时覆盖 `compose + capture`
- 本轮已完成：workspace 的 `endLocation` 现在会跟随整理改写、手动改写和撤回后的当前可见文本边界
- 本轮已完成：手动整理现在有独立的 `make smoke-refine-manual` 自驱入口
- 本轮已完成：整理后的外部手改现在会在二级动作前先同步回 workspace，再决定是直接撤回还是先确认
- 本轮已完成：`dirty -> confirm undo -> undo refine` 现在有独立的 `make smoke-refine-dirty-undo` 自驱入口
- 本轮已完成：`Refine fallback` 现在有独立的 `make smoke-refine-fallback` 自驱入口
- 更早已完成：Settings 的 `Passive Learning` 面板现在能展示 `observed / promoted / conflicted / skippedConfirmed` 状态计数
- 更早已完成：Settings 现在能展示最近学习事件，且只暴露 `alias / canonical / evidence / outcome`
- 更早已完成：项目已经收敛到 `OSLog.Logger + make logs + make traces + make trace-report + make term-learning-report + make smoke-term-learning + make smoke-refine` 的统一调试入口
