# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后归档快照，再重写下一轮
- 不在这里堆长期想法、研究摘录或历史过程

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：把 `Word Correction` 落成 `TermDictionary` 之下的被动词级学习链路
- 状态：`Completed`

## 3. 为什么现在做

模型文档已经校正完成，下一步必须把代码也拉回同一套心智，否则产品会继续被过渡实现带偏：

- 现在代码还在把一次手动修改直接写成 `pending candidate`，这不符合“被动学习 + 重复证据晋升”的设计
- 如果不先把证据层做出来，后面 `Refine`、端侧整理、LLM 接入都会继续混入词级事实判断
- 用户的真实体验应该是“说完就发、必要时手改、系统自己慢慢学”，而不是用户理解一套显式候选流
- 这一轮需要把“词典事实”“词级被动学习”“workspace 级整理”在代码里彻底拆开

这一轮从最小闭环开始：只做词级观察、证据累计、达到阈值后自动晋升到 `TermDictionary`。句子级整理仍然留在 `Refine`，不混入词典学习。

## 4. 本轮范围

1. 把一次性 `pending candidate` 路径改成“先记词级证据，不立刻晋升”
2. 增加本地证据存储，只保存最小词级映射与计数，不保存整段文本历史
3. 让重复且一致的词级修正达到阈值后自动进入 `TermDictionary`
4. 明确冲突映射不会自动晋升，避免把不稳定修正写成事实
5. 明确句子级改写不会进入词典学习
6. 同步 live plan / 架构文档 / 手测文档，写清当前实现边界

## 5. 明确不做

- 不在这一轮接入 LLM 或端侧整理模型
- 不在这一轮扩张 `Refine` 能力
- 不把句子级改写纳入词典学习
- 不把翻译混进默认 `Refine`
- 不保存整段聊天内容、整段 transcript 或剪贴板历史
- 不为了兼容旧心智继续强化显式候选流

## 6. 执行顺序

1. 更新 live plan，锁定这一轮是词级被动学习实现
2. 先用测试钉住“第一次只记证据，第三次一致才晋升”
3. 落地最小证据模型与本地持久化
4. 补上冲突映射与句子级过滤
5. 更新架构文档和手测文档，收口这一轮

## 7. 完成定义

满足以下条件才算这一轮完成：

- 第一次手动词级修正只记录证据，不直接进入激活词典
- 同一映射达到阈值后会自动写入 `TermDictionary`
- 冲突映射不会被自动晋升
- 句子级改写不会进入词典学习
- 本地只保存最小词级证据，不保存整段文本历史
- 文档与代码都符合这次确认过的产品模型

## 8. 阻塞项

- 当前无外部阻塞
- 这一轮完成后，再决定词典设置页如何展示“观察中”的词级证据

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
- 当前代码里的 `pending candidate` 仍是过渡实现，只用于验证词级观察链路，不代表最终产品心智
- 本轮开始优先纠正文档：`TermDictionary` 是词级事实层，`Word Correction` 从属于词典，`Refine` 是 workspace 级整理层
- 当前 live focus 已切到下一步：把“观察证据 -> 达阈值晋升词典”的真实学习链路做出来
- 本轮已完成：手动词级修正现在先写入本地观察证据，不再直接新增 `pending candidate`
- 本轮已完成：同一 `alias -> canonical` 默认连续一致 `3` 次后自动晋升进 `TermDictionary`
- 本轮已完成：冲突映射不会自动晋升，句子级改写不会进入词典学习
- `Settings` 右侧已改成被动学习说明与观察计数；`pending candidate` 只作为旧本地数据的兼容显示保留
