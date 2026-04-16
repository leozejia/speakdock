# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后归档快照，再重写下一轮
- 不在这里堆长期想法、研究摘录或历史过程

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：先纠正 `TermDictionary / Word Correction / Refine` 的模型定义，再据此重排下一轮实现
- 状态：`In Progress`

## 3. 为什么现在做

Settings 与品牌壳体已经收口到可继续开发的状态，但当前文档里的能力边界已经出现偏移，需要先校正模型再继续开发：

- 当前文档把“词典学习”和“显式候选确认流”绑得太紧，已经不符合你确认过的产品心智
- 当前文档里 `Refine` 仍然混入了“纠错”表述，容易让词级事实修正和 workspace 级整理继续串味
- 如果不先把模型定义写正，后面继续实现会把过渡代码误当长期架构
- 词典学习、`Clean`、`Refine`、端侧整理模型和后续 LLM 能力都依赖这层边界清楚

这一轮先把文档里的层级关系校正到位：`TermDictionary` 是词级事实层，`Word Correction` 是词典下的被动学习机制，`Refine` 是 workspace 级整理层。文档对齐后，再按这套模型重排实现。

## 4. 本轮范围

1. 把 `TermDictionary / Word Correction / Refine` 的职责边界写正
2. 明确 `Word Correction` 只处理词或短语，永远不碰句子
3. 明确 `Refine` 只负责整个 workspace 的整理，不负责词级事实判断
4. 明确默认 `Refine` 不做强制翻译；翻译只能是显式意图或显式模式
5. 在 live plan 中写清当前 `pending candidate` 只是过渡实现，不是长期产品模型
6. 同步架构文档与当前 live plan，防止后续实现继续带着旧认知前进

## 5. 明确不做

- 不在这一轮继续扩张代码实现
- 不在这一轮继续优化 UI
- 不把句子级改写纳入词典学习
- 不把翻译混进默认 `Refine`
- 不把当前过渡性的 `pending candidate` UI 误写成最终产品心智
- 不为了补文档去重写归档历史

## 6. 执行顺序

1. 更新 live plan，锁定这轮先纠正文档模型
2. 更新 `ARCHITECTURE.md` 中 `TermDictionary / Refine / Clean` 的定义
3. 明确 `Word Correction` 是词典下的被动学习机制，而不是独立对外能力
4. 写清当前实现中的过渡项和下一轮真正要做的实现方向
5. 完成文档检查后，再开启下一轮代码实现

## 7. 完成定义

满足以下条件才算这一轮完成：

- 文档中不再把句子级修改写进词典学习语义
- 文档中不再把 `Refine` 写成词级纠错能力
- 文档中明确 `Refine` 是 workspace 级整理，默认不强制翻译
- 文档中明确 `Word Correction` 从属于 `TermDictionary`
- live plan 明确写出当前代码里的过渡实现和下一轮真正实现方向
- 文档与这次确认过的设计意图一致

## 8. 阻塞项

- 当前无代码层阻塞
- 本轮完成后，需要按新模型重排下一轮实现计划

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
