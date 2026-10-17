# Spec Delta

## Purpose

提供简洁的省略号操作入口，避免 macOS 原生菜单箭头与自定义图标重叠，同时保留任务和会话的全部操作。

## ADDED Requirements

### Requirement: Action menus show only ellipsis buttons
The board SHALL use a custom popover action panel for subject-task and session actions, with an ellipsis button as the only visible trigger icon.

#### Scenario: Open subject-task actions
- **WHEN** the user clicks the subject-task ellipsis button
- **THEN** a popover shows the existing task actions without a second arrow indicator

#### Scenario: Open session actions
- **WHEN** the user clicks a session ellipsis button
- **THEN** a popover shows the existing session actions without a second arrow indicator
