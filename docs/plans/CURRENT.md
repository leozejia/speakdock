# SpeakDock Current Plan

## 1. 用途

这份文档是当前唯一 live plan。

- 只记录当前阶段唯一 focus
- 完成后归档快照，再重写下一轮
- 不在这里堆长期想法、研究摘录或历史过程

## 2. 当前阶段

- 阶段：P1 `AI 语音输入法`
- 当前 focus：拆分 `App Language` 与 `Input Language`，纠正现有单一 `languageCode` 模型
- 状态：`In Progress`

## 3. 为什么现在做

当前实现把“界面语言”和“语音识别语言”混成了同一个设置：

- UI 侧把它当成唯一语言入口
- ASR 侧直接拿它决定识别 locale
- 这会让产品语义继续漂移，并阻碍真正的界面本地化

这一轮要把模型一次拆正，不保留长期双轨语义。

## 4. 本轮范围

1. 用新的设置模型替换单一 `languageCode`
2. 引入独立的 `App Language`
3. 保留独立的 `Input Language`
4. 让菜单栏、Settings 和相关状态文案走统一本地化入口
5. 同步测试、README、人工验收和执行归档

## 5. 明确不做

- 不做自动识别说话语言
- 不做跟随当前键盘输入法
- 不做按 App 记忆输入语言
- 不做混合语言自动切换
- 不做端侧模型语言检测

## 6. 执行顺序

1. 重构设置模型：`App Language` / `Input Language`
2. 调整 ASR 接线，只消费 `Input Language`
3. 收敛 UI 文案入口，建立原生本地化资源
4. 更新菜单栏、Settings、overlay 等可见文案
5. 补齐测试与文档，完成一轮人工验收

## 7. 完成定义

满足以下条件才算这一轮完成：

- `App Language` 只影响界面文案
- `Input Language` 只影响语音识别
- 不再存在运行时“一个字段双重语义”
- 至少交付 `English + 简体中文` 界面本地化
- 既有输入语言集合不回归
- 文档索引和人工验收清单同步

## 8. 阻塞项

- 当前无外部阻塞

## 9. 最近完成

- `App Language` / `Input Language` 设置模型已拆分，ASR 已只消费 `Input Language`
- Settings / Menu Bar / trigger 状态文案已接入原生本地化入口，当前提供 `English + 简体中文`
- `build-app.sh` 已复制 SwiftPM 资源 bundle，`make build` 产物会带上本地化资源
- `Term Dictionary` 已接入 Settings，并完成本地持久化与测试
- README / 手动验收 / 执行日志的上一轮漂移已回收
- dated 计划与执行日志已移入 `docs/plans/archive/`
