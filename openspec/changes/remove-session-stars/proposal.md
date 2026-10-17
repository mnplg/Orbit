# Proposal

## Why

会话行里的星标会增加操作噪音，也让用户误以为会话本身需要单独维护收藏状态。当前看板更适合以主体任务为收藏和筛选单位。

## What Changes

- 移除展开会话行中的星标按钮。
- 将任务组顶部星标明确绑定到主体任务。
- “只看星标”保留主体任务筛选能力，并兼容已有会话星标数据。

## Capabilities

### New Capabilities
- `subject-task-stars`: 以主体任务为单位进行星标和筛选。

### Modified Capabilities

## Impact

- 修改 `Sources/main.swift` 的任务组星标和会话行布局。
- 更新 README 使用说明与回归测试。
