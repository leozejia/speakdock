# SpeakDock 架构模型

## 1. 角色

本文件是 SpeakDock 当前唯一优先的真相源。

后续交互、实现、性能约束，都以这里为准。

## 2. 核心结论

SpeakDock 只做三件事：

- `Compose`：把话写进当前光标
- `Capture`：把话记到本地收纳区
- `Wiki`：把已经留下来的内容，异步编译成长期知识

同时只暴露两个显式交互：

- `说话按钮`
- `整理按钮`

一句话公式：

`语义路由 -> 整理判断 -> 持久化判断 -> 提交 -> 撤回窗口`

硬规则：

`语音输入 != 知识沉淀`

## 3. 两层状态

### 3.1 产品语义层

产品层只保留 3 个状态：

- `Compose`
- `Capture`
- `Wiki`

含义：

- `Compose`
  - 有可编辑光标
  - 目标是当前输入位置
  - 默认是即时文本，不做长期沉淀

- `Capture`
  - 没有可编辑光标
  - 目标是本地 `MD` 工作区或工作目录
  - 默认先留下，再决定后续怎么整理

- `Wiki`
  - 不是实时说话模式
  - 是后台知识整理层
  - 只处理已经持久化的内容

结论：

- 用户实时交互时，只有 `Compose` 和 `Capture`
- `Wiki` 是冷路径，不应该和实时输入抢控制权

### 3.2 运行流程层

运行状态机只描述流程，不描述业务语义：

- `Ready`
- `Listening`
- `Thinking`
- `Committing`
- `UndoWindow`
- `Error`

状态流转：

1. `Ready -> Listening`
2. `Listening -> Thinking`
3. `Thinking -> Committing`
4. `Committing -> UndoWindow`
5. `UndoWindow -> Ready`
6. 任意阶段失败 -> `Error -> Ready`

## 4. 两个按钮

### 4.1 说话按钮

这是主按钮。

规则：

- 按住：进入 `Listening`
- 松开：结束录音，进入 `Thinking`
- 完成后：按当前语义路由提交
- 双击：执行一次 `Enter / Submit`

默认路由：

- 有光标 -> `Compose`
- 无光标 -> `Capture`

双击规则：

- 只在 `Ready` 状态下生效
- 双击时不进入录音
- 在 `Compose` 场景里，等价于帮用户按一次回车
- 对大多数聊天框来说，这通常就是发送
- 发送后，当前工作区结束

### 4.2 整理按钮

这是一个显式的状态按钮，不是独立模式。

它永远只作用于“当前工作区”。

macOS v1 的主入口写死为：

- overlay 上的第二个按钮

补充入口：

- menu bar 可以提供兜底入口

但主交互不放在 menu bar 里，否则“两按钮模型”会失真。

按钮状态机：

1. 当前工作区处于原始态时，按钮语义是 `整理`
2. 整理完成后，按钮语义变成 `撤回`
3. 撤回完成后，按钮语义回到 `整理`

这意味着：

- 第一次点：整理当前工作区
- 第二次点：把当前工作区恢复回原始态
- 撤回后再点：基于当前工作区再次整理

如果当前没有“整理后的结果”可撤回，但仍处于 `UndoWindow` 内：

- 这个按钮临时承接“撤回最近一次提交”

这个设计是成立的，但必须加一条边界：

- 整理按钮只绑定当前 `ActiveWorkspace`
- 工作区切换后，旧工作区不再响应这个快捷按钮

否则用户会不知道“这次撤回到底作用在哪个地方”

### 4.3 为什么这样合理

原因不是按钮少，而是目标明确：

- 说话按钮负责“持续往当前工作区写内容”
- 整理按钮负责“处理当前工作区的内容”

两者职责完全分开，认知负担低。

### 4.4 工作区定义

`Workspace` 才是整理与撤回的真实作用域。

定义：

- `Compose` 下，工作区是当前聚焦输入框里，从光标起始点到当前结束点这一段文本
- `Capture` 下，工作区是当前 `MD` 草稿或当前打开的记录文件
- `Wiki` 不参与这个实时工作区模型

`Compose` 下的 v1 规则尽量简单：

1. 焦点切换到任意输入框时，视为新工作区开始
2. 此刻记录当前光标位置，作为临时起始点
3. 在第一次说话前，用户仍然可以移动光标或手动修改
4. 第一次说话开始后，起始点冻结
5. SpeakDock 只管理这个起始点到当前结束点之间的文本
6. 录音开始时必须捕获当前可编辑目标，提交时优先复用这个目标；不能等 ASR final result 后才首次判定目标

关键约束：

- 工作区不是“上一句”
- 工作区也不是“整个输入框”
- 它是当前这块由 SpeakDock 接管的编辑范围
- `Capture` 首次落盘后自动打开编辑器，这次系统触发的焦点变化仍算同一工作区延续

## 5. 整理模型

整理不是单独模式，而是跨 `Compose / Capture` 的修正能力。

整理触发有两种：

- 用户主动点整理按钮
- 系统根据明确规则做最轻量清洗

强度分三档：

- `Clean`
  - 修正 ASR
  - 补标点
  - 去口头禅
  - 不改结构

- `Restructure-Light`
  - 拆句
  - 调顺序
  - 让表达更顺
  - 不改变原意

- `Restructure-Strong`
  - 明显重写
  - 只在用户明确不满意并再次要求重构时使用

关键原则：

- 长，不等于要整理
- 乱，才需要整理
- “整理”优先于自动猜测

### 5.1 术语词典与自增长边界

`TermDictionary` 是语音输入法层的本地辅助数据，不是产品知识库。

它解决的问题很窄：

- 人名、项目名、产品名、技术词反复识别错误
- 中英文混输里的专有名词被 ASR 拆错或替换
- refine 需要知道哪些词不能被“润色”成常见词

来源只允许两类：

- 用户手动填写
- 用户手动修正 SpeakDock 输出后，由系统生成候选词条，再由用户确认

第一版不允许静默自增长。用户手动改过文本，不能直接被当成词典事实。

原因：

- 手动修改可能只是改语气，不是修术语
- 修改片段可能包含隐私内容
- 自动加入词典会污染后续所有输入
- 一旦词典过拟合，模型和规则都会稳定地产生错误

推荐流程：

1. SpeakDock 记录本次 `raw_context` 与用户最终保留文本之间的差异摘要
2. 只在本地生成候选，例如“是否把 X 记为术语？”
3. 用户确认后写入本地词典
4. 词典用于 `Clean`、ASR 后处理和 `RefineRequest` 上下文
5. 词典命中必须可撤回、可删除、可导出

词典存储规则：

- 不进入 Git
- 不写入公开仓库
- 默认保存在用户本地 Application Support 或等价的本地配置目录
- 不记录完整聊天内容、完整转写正文或剪贴板内容
- 只保存用户明确确认过的术语、别名、替换规则和可选备注

`StyleProfile` 与 `TermDictionary` 分开。

- `TermDictionary` 负责“词是什么”
- `StyleProfile` 负责“用户偏好怎么写”

第一阶段只实现 `TermDictionary`。`StyleProfile` 等语音修改和技能层稳定后再评估。

## 6. Workspace 数据模型

SpeakDock 对外不需要暴露一长串状态名。

对外只需要讲两个概念：

- `Workspace`
- `raw_context`

其中：

- `raw_context`
  - 当前工作区里的原始口头表达累计结果
  - 它是整理前基线
  - 工作区结束后清空

实现层内部可以私有维护少量状态，但不应该上升成产品概念：

- 光标起始点
- 当前结束点
- 当前可见文本
- `dirty`

其中 `dirty` 只是内部状态监控：

- 它表示整理后的结果，是否又被用户手动改过
- 它不需要成为界面概念

核心原则：

- 默认不做 `history`
- 工作区生命周期结束后，直接清空
- 只保留当前工作区最小可逆信息

### 6.1 基线更新规则

当工作区已经建立，但还没发生第一次说话时：

- 光标起始点仍然可以变化
- 用户可以先手动编辑，再开始说话

当第一次说话开始后：

- 光标起始点冻结
- 后续语音持续追加到同一个 `raw_context`
- 整理动作只处理这个工作区内的文本

### 6.2 Compose 的 v1 保守边界

`Compose` 的产品模型是精确的。

但 macOS v1 的实现边界必须保守。

硬规则：

- v1 不承诺跨任意 app 的完美工作区追踪
- v1 不承诺跨任意 app 的完美 `dirty` 检测
- v1 不承诺跨任意 app 的完美精确撤回

v1 只在这些条件同时成立时，认为 `Compose Workspace` 仍然可控：

- 当前焦点仍在同一个可编辑目标
- SpeakDock 仍然持有这次写入会话的上下文
- 当前目标仍然可观测、可注入

一旦出现以下任一情况，立即结束当前 `Compose Workspace`：

- 焦点切换
- 用户显式提交发送
- 当前 app 或控件无法再被可靠观测
- SpeakDock 无法再确认自己正在管理哪一段文本

当工作区处于未整理态时：

- 用户手动修改当前工作区文本，可以直接吸收进新的 `raw_context`
- 这意味着后续“整理”会基于用户最新版本继续工作

这样更符合直觉，因为此时用户还没有进入“可撤回的整理态”。

### 6.3 整理与撤回规则

当用户点击 `整理`：

- 以当前 `raw_context` 为输入
- 生成重构后的当前可见文本
- 同时保留 `raw_context` 作为可撤回基线

当用户再次点击按钮：

- 如果 `dirty = false`，直接把 `raw_context` 写回工作区
- 如果 `dirty = true`，先提示：
  - `你刚刚修改过，确定要回滚吗？`

回滚后：

- 当前文本恢复为 `raw_context`
- `dirty = false`

这就满足了：

- 用户先连续说几句，再统一整理
- 整理后可以一键撤回
- 用户改过整理结果时，不会被静默覆盖

## 7. 路由规则

### 7.1 Compose

触发条件：

- 当前有明确可编辑光标

macOS v1 的工程化定义写死为：

- 只有在拿到 `Accessibility` 的聚焦元素，且该元素被判定为可编辑文本目标时，才进入 `Compose`
- 可以把 `AXFocusedUIElement` 作为默认判定入口
- `AXFocusedUIElement` 不允许只查 system-wide object；VS Code / Electron / 微信类 app 可能返回 `kAXErrorNoValue` 或不暴露 focused window，必须 fallback 到 frontmost application、focused/main window、window list 与 app children 的 AX tree
- frontmost fallback 必须有深度与访问数量上限，避免复杂第三方 App 的 AX tree 无界遍历
- 如果某个高优先级 App 能确认前台进程和窗口，但完全不暴露可编辑 AX 节点，可以通过显式 bundle allow-list 启用 paste-only fallback；该 fallback 只能绑定当前前台进程和 bundle，提交时如果前台不再是同一进程则必须失败
- 当前 paste-only allow-list 只包含 `com.tencent.xinWeChat`
- “可安全注入”是 `Compose` 成立条件的一部分，不只是附加优化

失败边界：

- 如果权限缺失、目标不可判定、或当前控件不可可靠注入，则不静默降级到 `Capture`
- 这种情况应直接提示 `Compose` 当前不可用
- 如果当前目标不接受粘贴，也视为 `Compose` 失败，而不是自动改写成 `Capture`
- 如果本次录音按下时已经捕获到 `Compose` target，则提交时必须优先尝试该 target；即使已有 `Capture` 文件处于打开状态，也不能让 Capture continuation 抢先接管

默认行为：

- 输出到 `Cursor`
- 默认 `Transient`
- 默认只做 `Clean`
- 默认持续写入当前 `Workspace`

适用场景：

- 聊天
- 邮件
- 搜索
- 文本输入

### 7.2 Capture

触发条件：

- 当前没有明确可编辑光标

默认行为：

- 松开按钮后，先记录这一段 `raw_context`
- 立即新建一份本地 `MD` 文档
- 把这段内容写进去
- 自动用用户默认文本编辑器打开这份文档
- 光标停在最后一个字后面
- 默认 `Working`
- 默认只做 `Clean`
- 后续语音继续追加到这同一份文档的当前 `Workspace`

后续追加语义写死为：

- 首次落盘后，后续语音一律追加到同一文件尾部
- v1 不跟随默认编辑器里的当前光标
- v1 不把已打开编辑器重新解释成新的 `Compose Target`
- 文件是权威，编辑器只是用户当前看到的载体

兼容边界：

- 如果某个默认编辑器对外部文件刷新不及时，v1 仍以文件写入成功为准
- 这不阻塞 `Capture` 成立

存储规则：

- Settings 默认把用户桌面作为根目录
- 用户可以改成任意本地目录
- 必须提供一键迁移，把已有 `Capture` 文档整体迁走
- 迁移完成后，后续新文件写入新的根目录

迁移规则：

- 这是 macOS v1 必做项，不延期
- v1 只要求“整体搬迁”
- 如果目标目录出现冲突，迁移直接中止并提示用户处理
- v1 不做复杂合并、同步或双向修复

命名规则：

- 文件名默认使用时间戳
- 文件名不依赖首句摘要
- 文件名前缀植入品牌
- 推荐格式：`speakdock-YYYYMMDD-HHMMSS.md`

目录规则：

- v1 不做复杂层级
- 先保证开箱即用
- 如无额外需要，直接写在用户设定的根目录下

适用场景：

- 记录灵感
- 记录草稿
- 随手记一句

工作区规则：

- 第一句结束并落盘后，`Capture` 会把“无输入框状态”转换成“已打开文档的编辑状态”
- 这不是新工作区，而是同一工作区的继续
- 用户切到别的文件、别的输入框，或显式结束当前记录时，当前工作区才结束

### 7.3 Wiki

进入条件：

- 用户明确要求保留到知识层
- 或后台从 `Capture` 内容中做冷路径提升

默认行为：

- 不阻塞热路径
- 异步编译
- 可以产出 MD 文档、wiki 页面或知识卡片

结论：

- `Wiki` 不是说话当下的主目标
- 它是持久化后的后台处理层

## 8. 总结、待办不是顶层状态

`总结`、`待办提取`、`卡片化` 都不应该再做成顶层状态。

更合理的归位方式是：

- 它们是 `Capture` 之后的派生处理
- 或 `Wiki` 编译阶段的后台产物

这样更稳，因为用户真正先关心的是：

- 我这句话写到哪里
- 要不要整理
- 要不要留下来

而不是先在脑中切一个复杂模式。

## 9. 撤回边界

撤回必须是一等能力。

规则：

- 每次提交后进入短暂 `UndoWindow`
- 整理后的文本，必须能一键回到整理前
- 文件写入必须能回滚本次变更
- `Wiki` 后台任务在执行前可取消，执行后要能回滚本次产物

macOS v1 先写死这些实现细节：

- `UndoWindow = 8 秒`
- 入口优先复用 overlay 上的第二按钮
- 超过窗口后，按钮恢复为普通“整理”

最关键的交互边界：

- 撤回只对当前 `ActiveWorkspace` 生效
- 用户切换工作区后，旧工作区失去快捷撤回资格
- 如果用户改过整理后的文本，撤回前必须确认
- 双击发送后，当前工作区立即结束

按钮优先级：

1. 如果最近一次动作是“整理”，按钮语义优先是“撤回整理”
2. 否则，如果最近一次动作是“提交写入”且仍在 8 秒内，按钮语义是“撤回最近一次提交”
3. 否则，按钮语义回到“整理”

回滚粒度：

- `Compose`
  - v1 只在仍可控的同一工作区内尝试回滚
  - 不承诺跨 app 的理想精确回滚

- `Capture`
  - 回滚粒度是“删除最近一次追加到文件尾部的那一段文本”
  - 不是整个文件快照回滚

- `Wiki`
  - 仍按后台任务语义处理

这不是缺陷，而是为了保持两按钮模型的确定性。

## 10. 技术模块边界

v1 技术细节整体参考 [README_CN.md](/Users/zejiawu/Projects/Project-Atlas/labs/thirdparty/voice-input-src/README_CN.md) 的交互与系统能力，但 SpeakDock 不能把模型和提供方写死。

硬规则：

- `DJI` 只是输入层的一个设备实现
- 它不是产品前提
- 输入层必须可以替换
- 同一套交互语义，应该能被不同输入源复用

这意味着：

- 可以来自 macOS 键盘按钮
- 可以来自主流麦克风按钮
- 可以来自 iPhone / iOS 侧的远程按钮
- 后面也可以接更多硬件，但不改变上层产品模型

必须拆成可替换模块：

- `TriggerAdapter`
  - 负责把不同来源的触发信号统一成同一套事件
  - 例如：按下开始、松开结束、双击提交
  - `DJI` 只是其中一个 adapter，不是核心架构

- `AudioCapture`
  - 负责录音、VAD、电平、波形数据

- `ASREngine`
  - 默认本地优先
  - 支持替换不同识别引擎

- `RefineEngine`
  - 接入保守整理与纠错能力
  - 第一阶段使用 OpenAI-compatible 接口验证效果
  - 端侧小模型是目标方向，但不能成为当前热路径前提
  - 支持接入用户自定义的大模型 API 或本地模型服务

- `WorkspaceRouter`
  - 决定写入 `Compose / Capture / Wiki`

- `TargetAdapter`
  - 负责光标注入、文件写入、剪贴板恢复、输入源切换

- `WikiCompiler`
  - 负责冷路径整理、MD 产物、知识编译

规则：

- P1 不引入常驻端侧小模型
- 云端模型是可选增强，不是主依赖
- 端侧小模型选型必须基于真实失败样本、延迟、内存和热量数据
- API 必须走标准可配置接口，不能和某一家服务深绑定

### 10.1 处理流水线

SpeakDock 不应该依赖一个大而全的单体模型。

更合理的是一条分层流水线：

1. 触发信号接入
2. 录音与 VAD
3. 流式 ASR
4. 术语纠错与基础清洗
5. 工作区与路由判断
6. 可选整理 / refine
7. 输出到 `Compose / Capture`
8. 可选后台 `Wiki` 编译

这意味着：

- 热路径先完成用户当前动作
- 冷路径再做知识层维护
- 本地小组件优先，云端增强后置

### 10.2 本地优先原则

macOS v1 应优先组合小而专的模块，而不是依赖一个常驻的大模型。

优先组合：

- `VAD`
- `ASR`
- 术语词典
- 轻量本地整理模型
- 确定性模板
- 置信度门控

解释：

- `VAD` 负责开始/结束边界
- `ASR` 负责实时转录
- 术语词典负责名称、产品名、技术词汇
- 轻量本地模型负责轻整理和纠错
- 确定性模板保证输出可控
- 置信度门控决定是否保守直出，还是进入更重的 refine

macOS v1 的工程收口写死为：

- 默认热路径不依赖本地整理模型
- `Clean` 先只定义为确定性清洗
- 包括：
  - 标点修正
  - 口头禅清理
  - 术语词典修正
- `Refine` 是可选增强
- 没开 refine 时，热路径直接按 `Clean` 结果提交
- 以后若加入本地整理模型，也挂在 `Refine` 或更强整理层之后，而不是反向污染默认热路径

模型角色必须拆开：

- `asr`
  - 负责语音转文本
  - 当前 macOS v1 走 Apple Speech
  - 本地 ASR 选型后置，不能阻塞 P1

- `clean`
  - 负责确定性清洗、术语词典替换和非常保守的口头噪声处理
  - P1 重点建设

- `refine`
  - 负责用户显式启用或显式触发的整理
  - 当前走 OpenAI-compatible 接口
  - 后续可替换成本地小模型或本地服务

- `extract`
  - 负责从 capture 中抽取实体、任务、项目和候选词条
  - 不进入 P1 热路径

- `wiki_compile`
  - 负责后台编译 wiki 页面
  - 必须是冷路径

端侧小模型研究进入 P2/P3 之前，必须先有这些输入：

- 真实 ASR 失败样本
- 术语词典命中和误伤样本
- OpenAI-compatible refine 的质量和延迟样本
- idle / hot path / refine path 的内存和热量测量
- 需要本地模型承担的明确角色，而不是笼统的“用小模型”

### 10.3 macOS v1 参考实现约束

如果沿用 [README_CN.md](/Users/zejiawu/Projects/Project-Atlas/labs/thirdparty/voice-input-src/README_CN.md) 这条参考实现路径，macOS v1 还应承接以下约束。

这些约束是 macOS v1 的参考实现要求，不等于整个产品永远写死在某个技术栈里。

- 应用形态
  - 以 `menu bar` 工具为主
  - `LSUIElement` 运行，无 Dock 图标
  - 优先走 macOS 14+ 能力

- 默认触发路径
  - v1 默认键盘按住说话
  - 默认映射可以是 `Fn`
  - 如果使用 `Fn`，则需要类似 `CGEvent tap` 的全局监听能力
  - 同时要抑制事件透传，避免触发系统 emoji 面板
  - `Fn` 是默认 trigger，不是唯一 trigger
  - 如果 `Fn` 监听不稳定、权限缺失、或被外部设备占用，v1 不自动切到某个固定热键
  - 这时 menu bar 必须明确显示 `Fn` 当前不可用
  - 用户只能通过 Settings 显式选择替代 trigger 后继续使用
  - 替代 trigger 只替换输入源，不改变“按住说话 / 松开结束 / 双击提交”的语义
  - 如果权限缺失导致 trigger 不可用，menu bar 必须明确显示当前 trigger 不可用
  - 默认 `Fn` 路径下，“不弹系统 emoji 面板”是硬验收标准
  - 后续硬件 adapter 可以覆盖默认触发源

- 权限模型
  - macOS v1 至少要覆盖这些权限：
    - 麦克风权限
    - Speech Recognition 权限
    - Accessibility 权限
    - Input Monitoring
  - 其中 `Input Monitoring` 是条件性权限，只在默认 `Fn` 监听方案确实依赖它时才要求
  - 当前 macOS v1 参考实现的 `Fn` event tap 授权入口优先走 Accessibility；如果后续切换到依赖输入监听的实现，再启用 Input Monitoring 口径
  - 每项权限都必须写清功能与失败表现：
    - 麦克风权限缺失
      - 不能录音
      - 不能驱动实时波形
      - 应直接提示录音不可用
    - Speech Recognition 权限缺失
      - 可以进入录音态，但不能产出最终文本
      - 热路径不能假装成功提交
    - Accessibility 权限缺失
      - 不能可靠判定当前可编辑目标
      - `Compose` 必须直接报不可用，不能静默改写成 `Capture`
      - 当前参考实现下，默认 `Fn` trigger 也会提示 Accessibility 授权
    - Input Monitoring 缺失
      - 仅当当前 `Fn` 监听实现依赖 Input Monitoring 时，默认 `Fn` trigger 不可用或不稳定
      - menu bar 必须提示 trigger 异常，并引导用户改用显式配置的替代 trigger
  - README 和人工验收清单都必须同步这一套权限口径

- ASR 与语言
  - 优先流式转录
  - macOS v1 优先走 Apple Speech 这类系统能力
  - 默认语言为简体中文 `zh-CN`
  - 菜单栏提供语言切换
  - v1 至少覆盖：英语、简体中文、繁体中文、日语、韩语
  - 语言偏好本地保存，例如 `UserDefaults`

- 录音反馈
  - 需要一个底部居中的悬浮反馈层
  - 如果走 Swift 参考路径，可优先采用 `NSPanel + NSVisualEffectView`
  - 反馈层要实时展示转录状态
  - 波形必须由真实音频电平驱动，而不是假动画
  - 波形应承接 README 里的多柱状、RMS 驱动、弹性宽度这些要求
  - `Thinking / Refining` 状态要明确可见
  - CoreAudio audio tap block 必须保持非 `MainActor` 隔离
  - 如果宿主对象是 `@MainActor`，tap block 必须通过非隔离 factory / handler 创建，不能在 `@MainActor` 方法内直接内联 closure
  - tap block 内只做 buffer 转发与轻量电平计算；任何 UI 更新都必须显式跳回 `MainActor`

- 文本注入
  - macOS `Compose` 路径优先兼容剪贴板 + `Cmd+V` 粘贴注入
  - 遇到 CJK 输入源时，需要先临时切到 ASCII 输入源
  - 注入完成后恢复原输入源与原剪贴板

- Refinement
  - `RefineEngine` 需要支持 OpenAI 兼容接口
  - 设置项至少包括 `Base URL / API Key / Model`
  - 菜单栏要有启用/禁用开关与设置入口
  - 设置页至少支持 `Test / Save`
  - `API Key` 字段必须可以完全清空
  - refine 提示词必须非常保守
  - 只修复明显识别错误，不擅自润色重写
  - 如果结果本来正确，应原样返回
  - 如果启用 refine，用户要能看到明确的 `Refining...` 反馈

- 构建与交付
  - 参考实现优先保持可脚本化构建
  - 如果走 Swift 参考路径，优先保持 `SPM + Makefile`
  - 产物应能稳定生成可运行的 app bundle

- 调试与观测
  - macOS v1 使用 Apple Unified Logging / `OSLog.Logger` 作为长期调试日志方案
  - subsystem 固定为 `com.leozejia.speakdock`
  - category 至少覆盖 `lifecycle / permission / trigger / audio / speech / compose / capture / refine`
  - 日志只记录状态、边界事件、权限结果、错误类型和非敏感枚举
  - 不记录音频内容、转写正文、剪贴板内容、API Key、完整 refine 请求正文
  - Apple Speech 任务错误必须记录脱敏的 `NSError.domain` 与 `NSError.code`，用于区分系统 ASR、权限、会话和短音频类失败
  - CoreAudio realtime tap 回调内不直接写日志；只在录音启动、停止、失败等边界记录
  - 本地调试入口优先通过 `make logs` 或等价的 `log show --predicate 'subsystem == "com.leozejia.speakdock"'`
  - 第三方 App `Compose` 兼容性扫测优先通过 `make probe-compose` 执行；probe 只检查前台 App 的可编辑目标，不录音、不注入、不改剪贴板

### 10.4 与 README_CN 的反向映射

当前更合理的关系不是“SpeakDock 跟着 README_CN 走”，而是：

- SpeakDock 先定义自己的产品模型
- 再把 [README_CN.md](/Users/zejiawu/Projects/Project-Atlas/labs/thirdparty/voice-input-src/README_CN.md) 映射回 macOS v1 实现层

也就是：

- `README_CN` 是参考实现切片
- SpeakDock 是上层产品架构

对应关系如下。

- `Fn 按住说话 -> 松开注入`
  - 映射到 SpeakDock 的 `说话按钮`
  - 在 macOS v1 中，`Fn` 只是默认 trigger
  - 在总架构中，它属于 `TriggerAdapter`

- `menu bar + LSUIElement`
  - 映射到 `SpeakDockMac` 壳层
  - 这是 macOS v1 形态，不是整个产品唯一形态

- `流式 ASR + 默认 zh-CN + 菜单语言切换`
  - 映射到 `ASREngine` 与 macOS v1 设置层
  - SpeakDock 保留这些要求，但不把实现锁死在单一服务

- `底部胶囊悬浮窗 + 实时波形 + Refining 状态`
  - 映射到 macOS v1 的录音反馈层
  - 这是 `Listening / Thinking / Refining` 的具体 UI 落点

- `剪贴板 + Cmd+V + 输入源切换`
  - 映射到 `TargetAdapter`
  - 这是 macOS `Compose` 路径的具体注入策略

- `OpenAI 兼容 refine + Base URL / API Key / Model`
  - 映射到 `RefineEngine`
  - SpeakDock 在其之上再加一层：端侧小模型优先，云端 refine 可选

- `Swift + SPM + Makefile`
  - 映射到 macOS v1 参考实现路径
  - 这是工程交付选择，不是产品模型本身

反过来看，SpeakDock 相比 `README_CN` 多定义了这些上层规则：

- `Compose / Capture / Wiki` 三态
- `Workspace + raw_context`
- `整理 / 撤回`
- `Capture` 落本地 `MD` 并形成持续工作区
- `DJI` 只是输入层 adapter
- `macOS first, iOS second`

结论：

- `README_CN` 没有被废掉
- 它已经被吸收到 SpeakDock 的 macOS v1 实现层
- 以后讨论实现时，可以把它当作“macOS 参考 profile”来对照

## 11. 平台策略

可以用一个仓库开发，也可以放在一个 Xcode 工程里统一管理。

但不应该做成一个完全同构的 app 壳。

路线优先级先写死：

- `macOS first`
- `iOS second`

原因：

- SpeakDock 的核心价值，首先成立在 macOS
- menu bar、全局触发、光标注入、外挂硬件接入，都先在 macOS 验证
- iOS 不应该和 macOS 并行分散注意力
- 先把 macOS 的工作区模型、整理模型、输入层 adapter 打磨稳定，再把核心下沉到 iOS

更合理的是：

- 一个共享核心
- 两个平台壳层

推荐结构：

- `SpeakDockCore`
  - 共享工作区模型
  - 共享 `ASR / Refine / Router / Wiki` 接口
  - 共享可插拔 adapter 协议

- `SpeakDockMac`
  - 负责 menu bar
  - 负责全局按键与硬件触发
  - 负责光标注入、剪贴板、输入源切换
  - 负责本地 MD capture

- `SpeakDockiOS`
  - 负责 iPhone 按钮入口
  - 负责 App Intents / Shortcuts / Action Button
  - 负责 iOS 本地 capture 与后续同步

原因很简单：

- macOS 擅长全局触发、全局文本注入、外挂硬件接入
- iOS 擅长单机快速 capture、按钮入口、系统捷径入口
- 两者共享核心逻辑，但平台能力边界不同

## 12. iOS 角色

iOS 可以做，但不要照搬 macOS。

iOS 不是 v1 主战场。

更准确的节奏是：

- v1 先做 macOS
- 等 macOS 跑顺后，再做 iOS

iOS 的第一阶段定位：

- iOS 是轻入口
- 不是完整替代 macOS 的全局输入器
- 先不做“跨 app 语音输入法”主攻线

建议 iOS 先承担两件事：

- 作为远程触发器
- 作为本地 capture 入口

明确延后：

- iOS keyboard extension
- iOS 跨 app compose

这些都放到 macOS 路线稳定之后再评估

### 12.1 iOS 远程触发

如果你把 `DJI` 这条最难的外挂硬件路径打通，后面的 iPhone 按钮其实会简单很多。

iPhone 侧本质上只是另一个 `TriggerAdapter`：

- Action Button
- Shortcuts
- App Intent
- 小组件或控制中心入口

这些都应该映射到同一套事件：

- 开始
- 结束
- 提交

### 12.2 iOS Capture

iOS 的 `Capture` 直接进备忘录，这个方向可以。

但更准确地说，应该把“备忘录”看成 iOS 的一个 `TargetAdapter`，而不是产品数据模型本身。

推荐的 v1 定位：

- macOS 的 `Capture` 默认落本地 `MD`
- iOS 的 `Capture` 默认落系统备忘录 / Quick Note

这样做的好处是：

- 用户心智顺
- 开箱即用
- iPhone 上不需要先教育用户一个新的文件系统

但有一条边界必须记住：

- iOS 进备忘录可以是默认目标
- 不能让“备忘录”反过来定义整个产品的数据模型

## 13. v1 基线

基线机器：

- MacBook Air M3
- 16GB 内存
- macOS 14+

约束：

- 常驻占用尽量压到 10% 预算内
- 热路径必须轻
- `Compose` 和 `Capture` 不能依赖重型云端链路
- `Wiki` 必须异步

### 13.1 基线解释

这个基线不是为了追求最低配置，而是为了尽早暴露热量、内存、常驻负担问题。

判断方式不是“能不能跑起来”，而是：

- 在正常知识工作环境里能不能长期开着
- 会不会让机器变热、变卡、变得不可信

默认评估场景应接近真实使用：

- 浏览器标签页已打开
- 聊天工具已打开
- Markdown 编辑器已打开
- 可能同时有音乐或会议音频

### 13.2 CPU 预算

不同运行状态，预算不同。

- `Ready`
  - 平均 CPU 尽量低于 2%
  - 理想状态接近空闲

- `Listening`
  - 平均 CPU 尽量控制在 10% 到 15%
  - 避免反复短语音时持续升温

- `Thinking`
  - 允许短时突刺
  - 20% 到 40% 的短 burst 可以接受
  - 但不能对常见短输入持续高占用数秒

- `Committing / Background`
  - 提交后应尽快回落到接近空闲
  - 后台 `Wiki` 任务必须可延迟、可批量、可打断

### 13.3 内存预算

这类产品对内存纪律的要求高于纯 CPU 峰值。

- idle 常驻内存，优先压在 500MB 以内
- 常见本地操作的 active working set，优先压在 1.5GB 以内
- 较重路径可以短时到 3GB
- 但多 GB 常驻不应成为 v1 常态

硬规则：

- 如果本地模型栈导致多 GB 常驻，说明架构过重

### 13.4 延迟预算

SpeakDock 必须让人感觉立即可用。

- `Compose`
  - 短语音松开后，最终注入通常应在 500ms 到 1s 内完成

- `Capture`
  - 短语音松开后，生成并打开 `MD` 通常应在 1s 到 2s 内完成

- `整理 / refine`
  - 常见短输入通常应在约 2s 内完成
  - 更长内容可以更慢，但必须可预期

用户可以接受短暂 `Thinking`。

用户不能接受“不知道刚刚到底有没有成功”。

### 13.5 热量、电池、前台体验

因为基线机器是无风扇设备，所以热量不是附属问题，而是一等约束。

要求：

- 重复短语音不应让机器明显发热
- 连续使用几分钟后，不应出现明显系统迟滞
- 不应做持续后台推理慢慢积热

电池要求：

- idle 耗电应接近可忽略
- 高频短语音不应造成明显续航焦虑
- 如果某个模型必须常驻内存，必须证明延迟收益值得

前台体验要求：

- 文本注入不能让当前 app 明显卡顿
- 文件写入不能阻塞 UI 线程
- 后台 `Wiki` 不应干扰输入、浏览、编辑

### 13.6 首轮测量清单

在选定最终模型组合前，至少要先测这些流程：

1. 默认触发源已接入时的 idle 开销
2. 本地 ASR 的短 `Compose` 热路径
3. 本地 `Capture` 生成并打开 `MD` 的完整路径
4. 本地轻整理 / refine 的短输入路径
5. 连续使用 10 到 15 分钟的热量与稳定性
6. 运行时内存占用

## 14. 当前结论

你现在这套设计，整体上是清晰的，而且比之前更舒服。

真正成立的关键不在“三态两键”本身，而在下面两条：

- `Wiki` 必须降级成后台层，不能和实时输入并列争抢交互
- `整理按钮` 必须绑定当前工作区，而不是最近一句语音

如果这两条守住，这个模型就是可实现且可用的。
