# Proposal

## Why

任务和会话菜单同时绘制了自定义省略号与系统下拉指示，窄窗口中两个图标重叠，降低了操作识别度。

## What Changes

- 使用单一的下拉箭头作为主体任务和会话菜单入口。
- 保留菜单内容和操作不变。

## Capabilities

### New Capabilities
- `clear-menu-entry`: 提供不重复的菜单视觉入口。

### Modified Capabilities

## Impact

- 修改 `Sources/main.swift` 中两个 SwiftUI `Menu` 的 label。
