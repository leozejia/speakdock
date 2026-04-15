# SpeakDock 品牌图形调研笔记

日期：2026-04-15

## 结论

这一轮不应该再把 `Dock icon`、`Settings 品牌图`、`menu bar glyph` 当成同一个层级的问题来处理。

- `Dock / app icon` 应该是完整品牌资产，负责识别度、记忆点和材质表达
- `Settings` 与 `menu popup` 如果需要展示品牌图，应该直接复用同一份 `app icon` 资源，避免再次画一套“差不多但不一样”的图
- `menu bar icon` 不应该直接缩小 app icon，而应该是极小尺寸下可识别的模板化图形
- 动画如果要做，应该放在后续官网 / README / 宣传素材的 `SVG motion` 上，不应该先塞进运行中的 menu bar 或 app icon

## 为什么这样定

### 1. app icon 和 menu bar icon 的职责不同

Apple 对 `app icon` 的要求是可识别、可记忆、在极短时间内表达 app 的核心特征。它可以有更完整的形体、材质和层级。

但 `menu bar` 上的图标尺寸很小，图形职责更接近“状态入口”。这里更重要的是：

- 单色
- 高对比
- 细节极少
- 在浅色 / 深色系统外观里都稳定可读

所以这两者必须是同一语义、不同载体，而不是“一张图缩小”。

### 2. Settings 品牌图不应该再手画第二份

这一轮用户已经明确指出：

- Dock 图标和 Settings 图标不一致
- 现有麦克风 logo 语义不清

从实现上最稳的做法不是再优化一套 SwiftUI 近似图，而是让 `Settings` 和 `menu popup` 直接复用 app icon 资源。

### 3. 动画不是当前 app icon 问题的第一解

这轮的主要问题仍然是静态形体不成立。

在静态图没有站住之前，先上动画只会放大问题。后续如果要做 `SVG` 动画，应该遵守两条原则：

- 只做轻量的 `transform / opacity` 类动画
- 遵守 `prefers-reduced-motion`

## 对 SpeakDock 的直接落地

1. `app icon` 改成更明确的麦克风主体，保留少量品牌色作为“信号”而不是整块霓虹主色
2. `Settings` 和 `menu popup` 直接使用同一 app icon 资源
3. `menu bar` 单独保留一个模板化麦克风 glyph，只保留极少必要结构
4. 本轮不在运行时 icon 上做动画
5. 后续若做官网 / README 动效，再从同一麦克风语义延展出轻动画版本

## 参考

- Apple Human Interface Guidelines: App icons
  https://developer.apple.com/design/human-interface-guidelines/app-icons
- Apple AppKit: `NSImage.isTemplate`
  https://developer.apple.com/documentation/appkit/nsimage/istemplate
- Apple Human Interface Guidelines: SF Symbols
  https://developer.apple.com/design/human-interface-guidelines/sf-symbols
- MDN: `prefers-reduced-motion`
  https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion
- MDN: `animateTransform`
  https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element/animateTransform
- web.dev: High-performance CSS animations
  https://web.dev/articles/animations-guide
