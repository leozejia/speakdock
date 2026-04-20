# SpeakDock 架构复核归档

## 1. 复核主题

- 时间：2026-04-20
- 主题：`HotPathCoordinator` 边界、`AX probe` 回归、`ASR` 样本观测

## 2. 复核结论

当时识别出的三个风险都已经进入实现并完成收口：

- `HotPathCoordinator` 边界已明确写死
- `probe-compose` 已补最小 machine-checkable verdict
- `ASR` 样本观测已补 readiness 与失败样本输出

## 3. 当时的输入价值

这次复核的作用不是提出新功能，而是避免两类漂移：

- 复杂度继续无边界地堆进单一协调器
- 诊断继续停留在“人工看日志、靠口头判断”

## 4. 归档原因

这轮复核对应的 plan 已经完成，后续不再由这份复核承担当前指挥作用。
