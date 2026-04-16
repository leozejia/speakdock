# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后重写，不在这里堆历史过程
- 目标是让开发动作、验证动作和文档始终同轨

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：补齐 `capture` 侧的 live workspace 自驱基线，确保 `compose + capture` 语义继续收敛
- 状态：`In Progress`

## 3. 为什么现在做

刚完成的上一轮，`Refine` 的热路径边界已经基本收稳：

- `make smoke-refine / make smoke-refine-submit-sync / make smoke-refine-manual / make smoke-refine-dirty-undo / make smoke-refine-fallback` 已经到位
- `submit / manual refine / dirty undo / fallback` 的真实边界现在都有脚本化验证
- 继续只在 `compose` 侧细磨，收益会迅速下降

下一条更值钱的主线是 `capture` 一致性：

- 用户已经明确要求同一套 live workspace 规则同时覆盖 `compose + capture`
- `capture` 现在虽然已有核心单测，但还缺少和 `compose` 对等的真实自驱闭环
- `capture` 直接落文件，更容易在“继续口述 / 整理 / 撤回 / 外部手改”这些点上再次漂移

所以下一轮不扩 UI，不引入新模型运行时，先把 `capture` 这半边补到和 `compose` 接近的验证强度。

## 4. 本轮范围

1. 重新审视 `HotPathCoordinator / CaptureFileTarget / WorkspaceReducer` 在 `capture` 模式下的真实调用边界
2. 找出 `capture` 里最容易漂的两个真实场景，优先补最小 failing test
3. 优先补成自驱 smoke，而不是继续堆纯单测或人工点测
4. 保证 `compose + capture` 对共享语义的解释一致
5. 同步文档，避免“规则写的是一套，文件行为又是另一套”

## 5. 明确不做

- 不扩词级学习语义
- 不引入新的模型运行时
- 不做端侧小模型接入
- 不做正式打包发布
- 不改 Wiki 长线方向
- 不做新 UI 入口
- 不为了 `capture` 补验证而改动已稳定的 `compose` 热路径

## 6. 执行顺序

1. 审视现有 `capture` 相关单测、脚本和真实调用点
2. 先补最小 failing test，锁定一个高风险 `capture` 场景
3. 再补最小实现或 smoke 基建
4. 跑定向测试与新的 `capture` 自驱命令
5. 同步文档并记录新的真实边界

## 7. 完成定义

满足以下条件才算完成：

- 至少一条 `capture` 高风险热路径已经有真实自驱 smoke，而不是只靠单测
- `capture` 的文件状态和 workspace 状态在该场景里保持同构
- `compose + capture` 对共享语义的差异已经被文档明确写清
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
- 本轮已完成：`capture` 多段口述现在在 workspace 内存文本和真实文件里都以换行分段；撤回最近一段时也会把这层分隔一起移除
- 本轮已完成：`compose` 路径现在有 `make smoke-compose-continue` 自驱入口，能真实验证“外部手改后继续口述”
- 本轮已完成：`capture` 路径现在有 `make smoke-capture-continue` 自驱入口，能真实验证“文件被外部手改后继续口述，会先同步再按换行追加”
- 本轮已完成：workspace 的 `endLocation` 现在会跟随整理改写、手动改写和撤回后的当前可见文本边界
- 本轮已完成：手动整理现在有独立的 `make smoke-refine-manual` 自驱入口
- 本轮已完成：整理后的外部手改现在会在二级动作前先同步回 workspace，再决定是直接撤回还是先确认
- 本轮已完成：`dirty -> confirm undo -> undo refine` 现在有独立的 `make smoke-refine-dirty-undo` 自驱入口
- 本轮已完成：`Refine fallback` 现在有独立的 `make smoke-refine-fallback` 自驱入口
- 本轮已完成：`submit` 前如果用户手改了当前 workspace，`make smoke-refine-submit-sync` 现在会真实校验整理请求读取的是手改后的当前文本
- 本轮已完成：`submit` 语义已经明确锁定，词级观察保留 pre-sync 差异，发送前 `refine` 仍读取当前可观测文本
- 更早已完成：Settings 的 `Passive Learning` 面板现在能展示 `observed / promoted / conflicted / skippedConfirmed` 状态计数
- 更早已完成：Settings 现在能展示最近学习事件，且只暴露 `alias / canonical / evidence / outcome`
- 更早已完成：项目已经收敛到 `OSLog.Logger + make logs + make traces + make trace-report + make term-learning-report + make smoke-term-learning + make smoke-refine` 的统一调试入口
