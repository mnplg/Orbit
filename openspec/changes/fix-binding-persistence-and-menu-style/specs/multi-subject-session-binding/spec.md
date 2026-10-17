# Spec Delta

## Purpose

让同一个 Qoder 或 Cursor 会话可以被多个主体任务复用，并且用户可以只解除其中一个主体任务的绑定。

## ADDED Requirements

### Requirement: A session can belong to multiple subject tasks
The board SHALL allow one conversation session to be bound to multiple subject tasks, and SHALL show that session in each bound task's session list.

#### Scenario: Bind one session to two tasks
- **WHEN** the user binds the same session to a second subject task
- **THEN** the session remains visible in the first task and also appears in the second task

### Requirement: Unbinding is scoped to one subject task
The board SHALL remove only the selected subject-task relationship when the user chooses to unbind a session from a group.

#### Scenario: Remove one of two bindings
- **WHEN** a session belongs to two subject tasks and the user removes it from one
- **THEN** it remains visible in the other subject task

### Requirement: Menu uses ellipsis without duplicate arrows
The board SHALL use an ellipsis menu label and SHALL NOT add a second custom dropdown arrow beside the native menu affordance.

#### Scenario: Compact task menu
- **WHEN** the task card is rendered at minimum width
- **THEN** the menu presents the ellipsis action without two custom arrows
