# Proposal

## Why

任务组当前会把星标会话优先展示，导致较早完成的会话遮住刚刚活跃的会话。用户打开看板时无法立即看到主体任务下最新的工作上下文。

## What Changes

- 任务组的预览会话按最后活跃时间选择，最近活跃的会话始终置顶展示。
- 展开任务组后，所有仍可见的会话按最后活跃时间从新到旧排列。
- 星标继续表示筛选和保留偏好，但不改变活跃时间排序。
- 主体任务摘要时间跟随最新可见会话的活跃时间。

## Capabilities

### New Capabilities
- `session-activity-order`: 按会话活跃时间组织任务组预览和展开列表。

### Modified Capabilities

## Impact

- 修改 `Sources/main.swift` 中任务组排序、预览和摘要时间逻辑。
- 更新生命周期自测和 README 中关于会话排序的说明。
