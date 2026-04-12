# SpeakDock macOS v1 手动验收

## 1. 测试环境

- 基线机器：`MacBook Air M3 / 16GB / macOS 14+`
- 默认语言：`zh-CN`
- 默认 capture 根目录：桌面
- 默认 trigger：`Fn`

## 2. 权限矩阵

| 权限 | 功能 | 缺失时预期表现 |
| --- | --- | --- |
| 麦克风 | 录音、波形、电平 | 不能进入有效录音；界面明确提示麦克风不可用 |
| Speech Recognition | 流式转录、最终文本 | 不能产出可提交文本；不能假装提交成功 |
| Accessibility | 判定可编辑目标、`Compose` 注入 | `Compose` 直接不可用；不能静默降级成 `Capture` |
| Input Monitoring（条件性） | 全局监听默认 `Fn` | `Fn` 路径不可用；menu bar 明确提示，需显式切到替代 trigger |

## 3. 启动与基础形态

1. 启动应用后，menu bar 图标可见。
2. 应用没有 Dock 图标。
3. Settings 可以正常打开。
4. 首次使用默认 `Fn` trigger 时，如果系统弹出 Accessibility 授权提示，应授权并重启应用。

## 4. 默认 Trigger

1. 按住 `Fn` 时进入 `Listening`。
2. 松开 `Fn` 时结束录音并进入后续处理。
3. 双击 `Fn` 时触发一次 `Enter / Submit`。
4. 默认 `Fn` 路径下不弹系统 emoji 面板。

## 5. Trigger 异常与替代

1. 当默认 `Fn` 路径不可用时，menu bar 明确显示 trigger 异常。
2. 系统不会自动切到某个固定替代热键。
3. 用户可以在 Settings 里显式选择替代 trigger。
4. 切换后，替代 trigger 仍保持 `按住说话 / 松开结束 / 双击提交` 语义。
5. 如果 menu bar 显示 `Accessibility Required`，先到系统设置授予辅助功能权限，再重启应用。

## 6. ASR 与语言

1. 首次启动默认语言是简体中文。
2. 切换到英语、繁体中文、日语、韩语后，新会话生效。
3. 录音过程中 overlay 能实时看到 partial transcript。

## 7. Overlay 与状态反馈

1. 录音时出现底部悬浮层。
2. 波形由真实音频电平驱动，不是固定假动画。
3. `Listening / Thinking / Refining` 状态可见。
4. overlay 上第二按钮可见。

## 8. Compose

1. 在可编辑文本框里可以稳定注入文本。
2. 中文输入法场景下仍能稳定注入。
3. 当前目标不可可靠注入时，直接提示 `Compose` 不可用。
4. `Compose` 失败时不会静默改写成 `Capture`。

## 9. Capture

1. 当前无输入框时，首句会生成 `speakdock-YYYYMMDD-HHMMSS.md`。
2. 文件默认写到桌面。
3. 首次落盘后会自动打开用户默认文本编辑器。
4. 后续语音继续追加到同一文件尾部。
5. 不跟随默认编辑器当前光标。
6. 在 Settings 点击 `Choose & Migrate…` 后，支持一键整体迁移。
7. 目标目录冲突时，迁移中止并提示。

## 10. 整理与撤回

1. 点击第二按钮可以对当前工作区执行整理。
2. 整理后再次点击，会撤回到 `raw_context`。
3. 如果整理后的文本被手动修改，再撤回前会先确认。
4. `UndoWindow = 8 秒`。
5. 超过 `8` 秒后，按钮恢复普通整理语义。

## 11. Refine

1. refine 默认关闭。
2. `Base URL / API Key / Model` 可以保存并重新加载。
3. `API Key` 可以被完全清空。
4. 点击 `Test` 时，不完整配置会直接报错；完整配置会返回明确结果。
5. Settings 至少支持 `Test / Save`。
6. 启用 refine 后，界面能明确显示 `Refining...`。

## 12. 基线性能

1. 在基线机器上常驻时，前台体验没有明显卡顿。
2. `Ready` 状态平均 CPU 尽量低于 `2%`。
3. `Listening` 状态平均 CPU 尽量控制在 `10%` 到 `15%`。
4. 连续短语音使用时，不应明显持续升温。
