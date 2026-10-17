# Spec Delta

## Purpose

让用户可以把自动收集的 Qoder 和 Cursor 会话重新组合到自定义主体任务中，并随时调整会话归属。

## ADDED Requirements

### Requirement: Users can bind sessions from a subject task
The board SHALL provide a subject-task action that lists available conversation sessions and allows the user to bind a selected session to that subject task.

#### Scenario: Bind a session from another project
- **WHEN** the user opens a subject task's actions and chooses an available conversation
- **THEN** the conversation becomes a child of that subject task and appears in its session list

### Requirement: Users can unbind a session
The board SHALL provide a session action to remove the session from its current subject task without deleting the session.

#### Scenario: Move a session out of a custom group
- **WHEN** the user chooses “移出主体任务” for a grouped session
- **THEN** the session remains in the board as a standalone conversation and is no longer shown in the old group
