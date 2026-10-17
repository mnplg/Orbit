# Proposal

## Why

自动按项目目录归组适合默认使用，但用户还需要把不同项目或不同来源的会话手动组合到一个主体任务中。同时，主体任务摘要目前显示全部会话数，无法准确表达当前状态下还有多少会话需要处理。

## What Changes

- 在主体任务菜单中增加“绑定会话”，可选择任意自动收集的会话加入该主体任务。
- 在会话菜单中增加“移出主体任务”，支持调整自定义分组。
- 主体任务摘要中的会话数只统计与当前摘要状态相同的会话。

## Capabilities

### New Capabilities
- `manual-session-binding`: 允许用户自定义主体任务与会话的组合关系。
- `status-session-count`: 让主体任务摘要显示当前状态对应的会话数量。

### Modified Capabilities

## Impact

- 修改 `Sources/main.swift` 的分组操作、任务卡菜单和摘要计算。
- 不改变 Qoder/Cursor 自动发现和默认项目归组。
