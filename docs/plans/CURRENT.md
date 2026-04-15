# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后归档快照，再重写下一轮
- 不在这里堆长期想法、研究摘录或历史过程

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：收口 `Settings` 的原生感、分区层级与 pane 渲染正确性，避免继续把设置页做成漂浮 dashboard
- 状态：`In Progress`

## 3. 为什么现在做

品牌图形和基础壳体已经收口到可用状态，但人工验收继续暴露出更核心的问题：

- 当前 `Settings` 仍然不够像 macOS 原生偏好设置，主观观感偏重、偏乱
- `Refine` 页出现过重复 `连接测试` 区域和左侧渲染异常，说明当前 SwiftUI 结构还不够稳
- 自定义壳体如果继续叠大卡片，会让窗口看起来像外壳和内部各画一层，体验割裂
- sidebar、detail、secondary rail 的层级还需要进一步收敛，不能只靠调颜色补救
- 这一步如果不收干净，后面继续加词典自动增长、LLM/端侧能力时，设置页会越来越难维护

这一轮先把设置页的视觉和结构模型校正到位，再继续推进词典自动增长与后续端侧 / LLM 能力。

## 4. 本轮范围

1. 继续固定 `Settings` 窗口宽度与 pane 栅格，避免切换时产生新的结构漂移
2. 把主编辑区从“很多漂浮卡片”收回到更接近原生偏好设置的层级
3. 修掉 `Refine` 页的重复区域和左侧渲染异常
4. 明确 `sidebar / detail / secondary rail` 的职责，不再让三者都抢视觉主导
5. 保持现有设置行为、本地化和已有功能不回归
6. 同步 live plan、踩坑记录、测试与人工验收

## 5. 明确不做

- 不做词典搜索、筛选和批量编辑
- 不做自动学习词典闭环
- 不做新的 refine 行为策略
- 不做端侧模型接入
- 不做整站级设计系统扩张
- 不做第二套可切换 logo 方案
- 不在这一轮引入花哨动画补设计问题
- 不为了“更像设计稿”而牺牲 macOS 原生控件和可维护性

## 6. 执行顺序

1. 更新 live plan，锁定当前 `Settings` 收口目标
2. 先修真实结构问题，确保 `Refine` / `General` / `Dictionary` 不再出现错误嵌套
3. 收敛主编辑区分层，减少 dashboard 感
4. 校正 secondary rail，只保留状态 / 辅助信息，不再重复主操作
5. 跑测试 / build
6. 做一轮人工界面验收，再决定是否继续细化视觉

## 7. 完成定义

满足以下条件才算这一轮完成：

- pane 切换时窗口宽度和主要内容栅格不再漂移
- `Refine` 不再出现重复 `连接测试` 区域
- 左侧主编辑区不再出现错误嵌套、中文 label 撑裂或异常重排
- 主编辑区、右侧状态区、sidebar 的视觉职责清楚，不再像三层互相叠壳
- 英文和简体中文界面文案不回归
- 现有设置能力、词典能力、refine 配置能力都可正常使用
- `make test` 与 `make build` 通过
- 文档与当前实现保持一致

## 8. 阻塞项

- 当前无代码层阻塞
- 下一轮需要你确认新的 `Settings` 视觉层级和 `Refine` 页体验是否达标

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
- 当前人工验收仍需继续确认：
  设置页主观观感是否足够像 macOS 原生偏好设置
