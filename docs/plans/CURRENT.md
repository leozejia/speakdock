# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后归档快照，再重写下一轮
- 不在这里堆长期想法、研究摘录或历史过程

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：重构 `Settings` 信息架构，拆出独立 `Dictionary` pane，并把设置界面收敛成更稳定的 macOS app shell
- 状态：`In Progress`

## 3. 为什么现在做

当前 `Settings` 还是旧的单页滚动结构：

- `Term Dictionary` 已经不是小设置项，而是会持续增长的数据面板
- 继续把词典和通用设置堆在一起，会让信息层级继续恶化
- 现有视觉语言也过于松散，无法支撑 SpeakDock 作为长期工具的产品质感

这一轮先把设置壳体做正，再继续推进词典自动增长与后续端侧 / LLM 能力。

## 4. 本轮范围

1. 引入侧边栏 pane 架构：`General` / `Dictionary` / `Refine`
2. 把 `Term Dictionary` 从通用设置页拆成独立工作面
3. 重做 Settings 的层级、间距、材质和导航反馈
4. 保持现有设置行为、本地化和已有功能不回归
5. 同步 live plan、测试与人工验收

## 5. 明确不做

- 不做词典搜索、筛选和批量编辑
- 不做自动学习词典闭环
- 不做新的 refine 行为策略
- 不做端侧模型接入
- 不做整站级设计系统扩张

## 6. 执行顺序

1. 建立 pane 模型与双语文案入口
2. 拆分 `SettingsView` 为侧边栏 + pane 内容区
3. 把 `Dictionary` 迁移成独立 pane
4. 调整视觉层级与操作区布局
5. 跑测试 / build，并做一轮人工界面验收

## 7. 完成定义

满足以下条件才算这一轮完成：

- Settings 不再是单页长滚动结构
- `Dictionary` 成为独立 pane
- `General` / `Dictionary` / `Refine` 的信息边界清晰
- 英文和简体中文界面文案不回归
- 现有设置能力、词典能力、refine 配置能力都可正常使用
- 文档与当前实现保持一致

## 8. 阻塞项

- 当前无外部阻塞
- 仍需要一轮人工视觉验收来确认新壳体的观感和密度

## 9. 最近完成

- `App Language` / `Input Language` 设置模型已拆分，ASR 已只消费 `Input Language`
- Settings / Menu Bar / overlay / 运行时错误文案 已完成 `English + 简体中文` 本地化
- 主 app bundle 已补齐 `en + zh-Hans` 本地化声明，左上角菜单会跟随保存的 `App Language`
- `SettingsPane` 模型已落地，当前固定为 `General / Dictionary / Refine`
- `SettingsView` 已重构为侧边栏 pane 壳体，`Term Dictionary` 已从旧单页中拆出
- 新的 Settings 视觉层级已落地第一版，当前需要人工验收决定下一轮细修
