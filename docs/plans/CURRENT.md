# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后归档快照，再重写下一轮
- 不在这里堆长期想法、研究摘录或历史过程

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：基于第一轮 Settings 壳体验收，收口窗口一致性、错误控件语义，以及以 app icon 为源的品牌图形统一
- 状态：`In Progress`

## 3. 为什么现在做

第一轮 `Settings` shell 已经落地，但人工验收暴露出新的明确问题：

- 不同 pane 仍会带来横向尺寸和栅格感知差异，切换体验不稳定
- `操作` / `保存` / `显示 Dock 图标` 这类控件语义不成立，继续保留会混淆产品模型
- Dock 应该默认可见，不应该再作为一个需要用户理解和切换的设置项
- menu bar icon 是否稳定可见还需要核查，不应该继续靠猜
- 当前 logo 不只是不够好看，而是 app icon、设置页品牌图和 menu bar glyph 没有形成清晰层级
- app icon 与 menu bar icon 不应该是同一张图直接缩小，前者需要品牌识别，后者需要模板化与极小尺寸可读性

这一轮先把这些基础体验收干净，再继续推进词典自动增长与后续端侧 / LLM 能力。

## 4. 本轮范围

1. 固定 Settings 窗口宽度与 pane 栅格，消除切换时的横向漂移
2. 删除 `显示 Dock 图标` 与无意义的 `保存` / `操作` 区块，Dock 改为默认常驻
3. 核查并修正 menu bar icon 的可见性与入口一致性
4. 重做品牌图形系统：Settings / menu popup 直接复用 app icon 资产，menu bar 维持独立模板 glyph
5. 重画 logo，改为更明确的麦克风语义，并保证静态图形先成立
6. 保持现有设置行为、本地化和已有功能不回归
7. 同步 live plan、测试与人工验收

## 5. 明确不做

- 不做词典搜索、筛选和批量编辑
- 不做自动学习词典闭环
- 不做新的 refine 行为策略
- 不做端侧模型接入
- 不做整站级设计系统扩张
- 不做第二套可切换 logo 方案
- 不在这一轮把动画直接塞进 menu bar 或 app icon 运行时

## 6. 执行顺序

1. 更新 live plan，锁定当前收口目标
2. 固定窗口和内容栅格，消除 pane 切换抖动
3. 清理 `Dock` / `保存` / `操作` 的错误语义，并把 Dock 收敛为默认行为
4. 核查 menu bar icon 入口与模板图形约束
5. 重做 app icon，并让 Settings / menu popup 直接复用同一资源
6. 基于同一语义重做 menu bar template glyph
7. 跑测试 / build，并做一轮人工界面验收

## 7. 完成定义

满足以下条件才算这一轮完成：

- pane 切换时窗口宽度和主要内容栅格不再漂移
- `Dictionary` 保持独立 pane，且与 `General` / `Refine` 的宽度体验一致
- `显示 Dock 图标`、无意义的 `保存`、模糊的 `操作` 不再出现在设置页
- Dock 默认可见，不再需要用户通过设置理解或切换
- menu bar icon 入口状态明确，不再存在“看不到但不确定是否 bug”的状态
- Settings 和 menu popup 中展示的品牌图直接来自同一 app icon 资产
- 新 logo 能直接传达麦克风 / 语音输入语义，且不会再出现 Dock 与设置页图形不一致
- menu bar glyph 在极小尺寸下仍可识别，并符合模板图形预期
- 英文和简体中文界面文案不回归
- 现有设置能力、词典能力、refine 配置能力都可正常使用
- 文档与当前实现保持一致

## 8. 阻塞项

- 当前无外部阻塞
- 下一轮需要你确认新的 logo 和更稳定的 Settings 壳体是否达标

## 9. 最近完成

- `App Language` / `Input Language` 设置模型已拆分，ASR 已只消费 `Input Language`
- Settings / Menu Bar / overlay / 运行时错误文案 已完成 `English + 简体中文` 本地化
- 主 app bundle 已补齐 `en + zh-Hans` 本地化声明，左上角菜单会跟随保存的 `App Language`
- `SettingsPane` 模型已落地，当前固定为 `General / Dictionary / Refine`
- `SettingsView` 已重构为侧边栏 pane 壳体，`Term Dictionary` 已从旧单页中拆出
- Dock 可见性已收敛为默认行为，`显示 Dock 图标` / `保存` / `操作` 残留控件已从设置页移除
- Settings 窗口宽度与次级信息栏宽度已固定，pane 切换不再依赖内容自然撑开
- 品牌图形调研笔记已补到 `docs/research/2026-04-15-brand-icon-research.md`
- `Settings` 与 `menu popup` 现在直接复用生成后的 app icon 资源，不再各画一套品牌图
- app icon 已重画为更明确的麦克风主体，`icns` 与运行时 `png` 均已重新生成
- menu bar glyph 已收敛为独立模板化麦克风图形，不再尝试直接缩小 app icon
- 新的 Settings 视觉层级已落地第一版，当前人工验收仍需继续收口：
  窗口一致性、menu bar 可见性、品牌图形主观验收
