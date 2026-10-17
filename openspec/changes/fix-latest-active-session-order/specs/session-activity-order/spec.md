# Spec Delta

## Purpose

让任务组始终把最近活跃的会话呈现在用户最容易看到的位置，并让展开列表反映真实的工作时间线，避免旧会话遮挡当前上下文。

## ADDED Requirements

### Requirement: Task groups prioritize latest activity
The task board SHALL choose the visible child session with the greatest `lastActivityAt` as the task group's preview session, regardless of whether another child session is starred.

#### Scenario: A newer unstarred session replaces an older starred preview
- **WHEN** a task group contains an older starred session and a newer unstarred session
- **THEN** the newer session is shown in the group preview and is used as the group click target

### Requirement: Expanded sessions are chronological
The task board SHALL show visible child sessions in descending `lastActivityAt` order when a task group is expanded, using a stable tie-breaker when timestamps match.

#### Scenario: Expanded list places the most recently active session first
- **WHEN** a task group is expanded with multiple visible sessions
- **THEN** sessions appear from newest activity to oldest activity

### Requirement: Starred sessions remain filterable without changing activity order
The task board SHALL preserve starred state and starred-only filtering while keeping starred state independent from preview and expanded activity ordering.

#### Scenario: Starred-only filtering keeps the group visible
- **WHEN** an older session is starred and the starred-only filter is enabled
- **THEN** the group remains visible, while any displayed session list still follows activity order
