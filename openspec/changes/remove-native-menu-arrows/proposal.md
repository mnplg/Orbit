# Proposal

## Why

macOS 的 SwiftUI `Menu` 会自动绘制下拉箭头，和任务板自定义的 `...` 同时出现。这个组合无法通过简单样式隐藏系统箭头，导致菜单入口视觉重复。

## What Changes

- 用自定义按钮和弹出面板替代任务卡、会话行的 `Menu`。
- 只显示 `...` 按钮，保留原有菜单操作。

## Capabilities

### New Capabilities
- `popover-actions`: 提供无重复箭头的任务操作面板。

### Modified Capabilities

## Impact

- 修改 `Sources/main.swift` 的任务卡和会话行菜单呈现方式。
