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
2. 默认设置下应用在 Dock 中可见，且 Settings 中不再提供 `Show Dock Icon` 之类的可见性切换项。
3. Settings 可以正常打开。
4. 首次使用默认 `Fn` trigger 时，如果系统弹出 Accessibility 授权提示，应授权并重启应用。
5. 正常用户态重复启动 SpeakDock 时，不应出现第二个常驻实例；系统应复用现有实例并把它带到前台。

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
6. 如果系统设置里 `SpeakDock` 已打开但 menu bar 仍显示 `Accessibility Required`，删除旧授权项，重新添加当前 `.build/debug/SpeakDock.app`，再重启应用。

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

## 8.1 Compose 兼容性扫测

1. 运行 `make probe-compose PROBE_SECONDS=30`。
2. 在 probe 运行期间依次聚焦待测 App 的真实输入框，例如 VS Code、微信、浏览器、Notes。
3. probe 结束后运行 `make logs LOG_WINDOW=2m`。
4. 日志中目标 App 出现 `compose probe result ... availability=available`，并且前面有 `compose target capture succeeded`，可视为该输入框通过 Compose target 捕获。
5. 如果出现 `compose target frontmost fallback failed` 或 `availability=noTarget`，把该 App 的 bundle id 与同段日志作为兼容性缺口记录。
6. 微信如果出现 `compose target capture using paste-only frontmost application fallback` 和 `availability=available`，说明通过微信专用 paste-only 捕获；仍需做真实 `Fn` 录音注入确认粘贴行为。
7. probe 不替代最终注入验收；通过 probe 后，仍需对重点 App 做一次真实 `Fn` 录音注入。

## 8.2 开发期自动化基线

1. 运行 `make smoke-compose`。
2. 该命令会自动启动 `SpeakDockTestHost`，再以 smoke mode 启动 `SpeakDock`。
3. `SpeakDock` 会在不依赖真实 `Fn` 和真实说话的前提下，把指定文本注入测试宿主。
4. smoke 成功后，说明最小 `Compose` 热路径闭环仍然成立。
5. 运行 `make smoke-compose-continue` 时，命令会走“第一次注入 -> 测试宿主模拟用户改字 -> 第二次继续口述”路径，验证同一 `Compose` workspace 的 live continuation 语义。
6. 运行 `make smoke-capture-continue` 时，命令会走“第一次 capture 写文件 -> 脚本模拟外部改字 -> 第二次继续口述”路径，验证同一 `Capture` workspace 会先同步文件当前内容，再按换行追加第二段。
7. smoke 成功或失败后，都可以运行 `make trace-report TRACE_WINDOW=5m` 快速看最近结果分布和延迟摘要。
8. 需要回到原始明细时，再运行 `make traces TRACE_WINDOW=5m` 查看最近交互结果码和阶段耗时。
9. 运行 `make smoke-refine` 时，命令会额外临时拉起一个本地 OpenAI-compatible stub server。
10. `smoke-refine` 成功后，说明 `Refine HTTP -> workspace apply -> submit` 这条开发闭环仍然成立。
11. 运行 `make smoke-refine-manual` 时，命令会直接走“写入当前 workspace -> 手动整理”路径，验证不提交时也能把整理结果写回目标。
12. 运行 `make smoke-refine-dirty-undo` 时，命令会走“写入当前 workspace -> 手动整理 -> 模拟用户改字 -> 二次点击确认撤回”路径，验证真实热路径里的 `dirty -> confirm undo -> undo`。
13. 运行 `make smoke-refine-fallback` 时，命令会强制让 stub server 返回失败，验证发送前整理失败时仍按当前 workspace 文本提交。
14. 运行 `make smoke-refine-submit-sync` 时，命令会先模拟用户手改当前 workspace，再触发送前整理，并校验发送到 stub server 的整理文本已经同步为手改后的版本。
15. 运行 `make smoke-term-learning` 时，命令会使用隔离的临时词典和测试宿主，回放匿名 `promotion` 场景，验证 `词级观察 -> 晋升 -> 下次命中`。
16. 运行 `make smoke-term-learning-conflict` 时，命令会回放匿名 `conflict` 场景，验证冲突 alias 不会被错误晋升。
17. 两条 `smoke-term-learning` 都成功后，说明 `TermDictionary` 的被动学习链路已有更完整的本地自驱基线。
18. 运行 `make term-learning-report` 时，可以直接查看当前本地词典学习摘要；输出只包含 `alias / canonical / evidence / outcome`，不包含完整正文。

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
4. 二级动作触发前，SpeakDock 会先重新读取当前工作区；如果发现用户已经改过字，会先把这次改动同步成 `dirty`。
5. `UndoWindow = 8 秒`。
6. 超过 `8` 秒后，按钮恢复普通整理语义。

## 11. Refine

1. refine 默认关闭。
2. `Base URL / API Key / Model` 可以保存并重新加载。
3. `API Key` 可以被完全清空。
4. 点击 `Test` 时，不完整配置会直接报错；完整配置会返回明确结果。
5. Settings 至少支持 `Test / Save`。
6. 松开录音后，SpeakDock 只追加 clean 文本，不会因为 refine 已开启就立刻对单段文本做 inline 整理。
7. 启用 refine 后，手动点击整理或执行发送前整理时，界面能明确显示 `Refining...`。
8. 默认 refine 不强制翻译输入语言；如果出现翻译行为，必须来自显式模式或显式意图。

## 12. Term Dictionary

1. Settings 中可以手动添加 `Canonical term + aliases`。
2. alias 为空、或与 canonical term 相同的条目不会保存成功。
3. 已确认条目可删除，删除后重新启动仍保持删除状态。
4. 已确认条目保存在用户本地，不进入仓库 Git 管理。
5. 在“可直接读回文本”的 compose 输入框里，手动改正 SpeakDock 刚刚写入的词并提交后，单次修改只会新增本地观察证据，不会直接进入激活词典。
6. 同一 `alias -> canonical` 连续一致出现 `3` 次后，才会自动进入已确认术语。
7. 如果同一个 alias 出现冲突 canonical，系统不会自动晋升，继续保留在本地观察层。
8. 句子级改写不会进入词典学习。
9. 对 paste-only fallback 或无法可靠读回文本的目标，不要求一定生成词级证据；系统应保守跳过，而不是静默入库。
10. 如果用户本地还残留旧版本的 `pending candidate`，Settings 可以继续显式 `Confirm / Dismiss` 这批遗留项，但新链路不会再新增它们。
11. `Settings -> Dictionary -> Passive Learning` 能看到“观察中 / 已晋升 / 有冲突 / 已确认”四类状态计数。
12. `Recent Learning` 只显示 `alias / canonical / evidence / outcome` 这些词级最小字段，不显示完整正文。
13. `Recent Learning` 为空时，会明确显示空状态，而不是只剩一块静态说明。
14. `Capture` 工作区如果用户直接改了本地 Markdown，再执行发送，系统可以读取当前文件内容并产生词级观察证据。

## 13. 基线性能

1. 在基线机器上常驻时，前台体验没有明显卡顿。
2. `Ready` 状态平均 CPU 尽量低于 `2%`。
3. `Listening` 状态平均 CPU 尽量控制在 `10%` 到 `15%`。
4. 连续短语音使用时，不应明显持续升温。
