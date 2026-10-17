# Proposal

## Why

一个会话可能同时服务多个主体任务，单一 `parentID` 无法表达这种复用关系；菜单入口也需要恢复为更熟悉的省略号形式。

## What Changes

- 支持一个会话绑定到多个主体任务，并分别从某个主体任务移除。
- 保留旧数据兼容，手动绑定关系可持久化。
- 菜单使用 `...` 作为入口，同时不额外绘制自定义箭头。

## Capabilities

### New Capabilities
- `multi-subject-session-binding`: 支持会话多主体绑定。

### Modified Capabilities

## Impact

- 修改 `BoardTask` 关系数据、分组查询、绑定操作和菜单布局。
- 更新分组回归测试。
