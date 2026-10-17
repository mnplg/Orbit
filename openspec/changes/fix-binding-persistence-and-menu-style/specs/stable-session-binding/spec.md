# Spec Delta

## Purpose

让用户手动建立的主体任务与会话关系在应用重启后继续有效，同时让菜单入口只显示一个系统下拉指示。

## ADDED Requirements

### Requirement: Manual bindings survive relaunch
The board SHALL persist a manually bound session's subject-task relationship before the next relaunch, and automatic polling SHALL preserve that relationship.

#### Scenario: Restart after binding
- **WHEN** a user binds a conversation to a subject task and restarts the board
- **THEN** the conversation remains under the same subject task

### Requirement: Menus use one system indicator
The board SHALL render no custom arrow or ellipsis alongside the native menu indicator.

#### Scenario: Compact menu control
- **WHEN** a task or session menu is rendered in the floating board
- **THEN** exactly one dropdown indicator is visible
