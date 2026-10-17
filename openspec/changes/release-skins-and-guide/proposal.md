# Proposal

## Why

程序已经能在本机运行，但换电脑使用时缺少明确的分发入口和使用说明；同时用户希望在默认深色之外拥有更轻松的萌系视觉选择。

## What Changes

- 增加可持久化的皮肤切换，保留默认深色并新增原创电气萌黄主题。
- 提供发布打包脚本，输出可复制的 macOS 压缩包。
- 提供面向使用者的中文 HTML 使用文档。

## Capabilities

### New Capabilities
- `board-skins`: 在看板内切换并保存视觉主题。
- `distribution-guide`: 打包应用并提供安装、连接和排错说明。

### Modified Capabilities

## Impact

- 修改 `Sources/main.swift` 的主题模型和 SwiftUI 样式。
- 新增发布脚本与 `使用文档.html`，不引入第三方依赖。
