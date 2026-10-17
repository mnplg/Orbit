# Spec Delta

## Purpose

规定桌面看板中主体任务与会话信息的层级及 Cursor 导入入口的显示方式，让分组更紧凑，同时保留用户查看单条会话所需的完整信息。

## ADDED Requirements

### Requirement: Compact aligned group
The group header SHALL display the subject title right aligned in its title area and SHALL use a compact summary. Session rows SHALL share the same content alignment and retain their existing title, source, state, and relative time content.

#### Scenario: Multiple sessions
- **WHEN** a group contains multiple sessions
- **THEN** its compact header and aligned session rows are readable without truncating source or status labels unnecessarily

### Requirement: Cursor manual import removal
The board SHALL remove the manual “跟踪 Cursor 对话” entry and sheet, while continuing to poll sessions already present in saved data.

#### Scenario: Existing tracked Cursor session
- **WHEN** the board starts with a previously imported Cursor session
- **THEN** it continues to update that session, while no manual import control is shown
