# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后归档快照，再重写下一轮
- 不在这里堆长期想法、研究摘录或历史过程

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：收口 `人工修正 -> 本地候选 -> 用户确认` 的 `TermDictionary` 闭环
- 状态：`In Progress`

## 3. 为什么现在做

Settings 与品牌壳体已经收口到可继续开发的状态，下一步必须回到更接近产品核心价值的词典闭环：

- 当前 `TermDictionary` 只有手动录入与候选确认入口，缺少“用户改对一次，系统下次更懂”的闭环
- 已有 `candidate extractor`、本地持久化、Settings 确认流都已经就位，真正缺的是热路径接线
- 如果继续把主线放在 UI 微调，会让产品看起来完成了很多，但核心学习能力仍然缺席
- 词典闭环是后续 `Refine` 上下文、端侧小模型、LLM wiki 的共同基础，应该先把最小正确路径收口

这一轮先把“人工修正生成候选，但不静默入库”的本地闭环做实，再继续往 `Refine` 上下文和后续更强能力推进。

## 4. 本轮范围

1. 把用户手动修正后的差异接入本地候选生成流程
2. 候选只进入 `pending`，不允许静默写入 confirmed dictionary
3. 对 confirmed / pending 做去重，避免同一候选反复堆积
4. 保持现有 `Clean` 热路径、Settings 词典页和本地持久化不回归
5. 明确当前 v1 的观测边界，并把文档改成和真实实现一致
6. 同步 live plan、测试与人工验收说明

## 5. 明确不做

- 不做静默自动入库
- 不做全量历史记录或完整文本落盘
- 不做端侧模型接入
- 不做新的 `Refine` 策略扩张
- 不做词典搜索、筛选、批量编辑和导出
- 不承诺跨任意 app 的完美手改检测
- 不为了做候选闭环去引入重型后台常驻能力

## 6. 执行顺序

1. 更新 live plan，锁定词典候选闭环
2. 先补 `TermDictionaryStore` 的人工修正候选写入与去重
3. 再把工作区结束前的最终文本快照接入候选生成
4. 跑 focused tests、`make test`、`make build`
5. 更新文档，明确 v1 支持范围与人工验收方式
6. 做一轮真实 app 手动验收

## 7. 完成定义

满足以下条件才算这一轮完成：

- 用户手动修正 SpeakDock 输出后，可以生成本地 pending candidate
- pending candidate 仍需用户显式 `Confirm / Dismiss`
- confirmed 与 pending 不会因同一候选重复堆积
- 不记录完整聊天正文、完整转写或剪贴板全文
- 当前 v1 的可观测边界在文档里写清楚，不再靠口头约定
- 现有 `Clean`、Settings、词典持久化能力不回归
- `make test` 与 `make build` 通过
- 文档与当前实现保持一致

## 8. 阻塞项

- 当前无代码层阻塞
- 本轮完成后，需要你用真实聊天输入框做一轮人工验收

## 9. 最近完成

- `App Language` / `Input Language` 设置模型已拆分，ASR 已只消费 `Input Language`
- Settings / Menu Bar / overlay / 运行时错误文案 已完成 `English + 简体中文` 本地化
- 主 app bundle 已补齐 `en + zh-Hans` 本地化声明，左上角菜单会跟随保存的 `App Language`
- `SettingsPane` 模型已落地，当前固定为 `General / Dictionary / Refine`
- `SettingsView` 已重构为侧边栏 pane 壳体，`Term Dictionary` 已从旧单页中拆出
- Dock 可见性已收敛为默认行为，`显示 Dock 图标` / `保存` / `操作` 残留控件已从设置页移除
- Settings 窗口宽度与次级信息栏宽度已固定，pane 切换不再依赖内容自然撑开
- 品牌图形调研笔记已补到 `docs/research/2026-04-15-brand-icon-research.md`
- Swift/macOS 唯一踩坑记录已补到 `docs/technical/SWIFT_MACOS_PITFALLS.md`
- `Settings` 与 `menu popup` 现在直接复用生成后的 app icon 资源，不再各画一套品牌图
- app icon 已重画为更明确的麦克风主体，`icns` 与运行时 `png` 均已重新生成
- menu bar glyph 已收敛为独立模板化麦克风图形，不再尝试直接缩小 app icon
- Settings 主壳已改为统一窗体表面，detail 不再是壳里再套一个独立大卡片
- `General / Dictionary / Refine` 已收敛到统一双列节奏，减少 pane 切换时的壳体割裂感
- `Refine` 右侧重复 `连接测试` 区域已移除，改为单一 `当前状态` 面板
- `Settings` 左侧主编辑区已从重卡片结构收回到更轻的原生表单层级
- `LabeledContent` 造成的窄容器渲染异常已从 `Settings` 主路径移除
- `Refine` 已进一步重构为单一主操作区：配置与测试合并，右侧不再镜像空配置
- `Refine` 右侧信息栏已改为主路径工作方式说明，不再重复显示整理开关与占位字段
- sidebar 顶部全局整理状态 badge 已移除，减少页面内外重复监控
- 当前主线已切回词典闭环，UI 收口进入已完成态，不再作为 live focus
- `TermDictionaryStore` 已新增人工修正候选写入入口，并补齐 pending / confirmed 去重护栏
- `EditableTextObservationContext` 已落地，用于从可观测输入框的前后文边界中保守提取当前工作区文本
- `HotPathCoordinator` 已在 `submit` 前接入手动修正候选记录；当前只对可读回文本的 compose 目标生效
- `ARCHITECTURE.md` 与手动验收文档已同步到当前真实边界：候选基线取最后一次渲染文本，paste-only 目标保守跳过
