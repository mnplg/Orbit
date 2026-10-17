# Spec Delta

## Purpose

定义主体任务下各会话的默认展示顺序、手动置顶和时间失效规则，让看板优先显示当前最可能需要继续处理的会话，同时保留可恢复的历史记录。

## ADDED Requirements

### Requirement: Latest session preview
The board SHALL show only the most recently updated visible session in a collapsed subject group by default and SHALL allow expanding the group to see every visible session in descending update order.

#### Scenario: Collapsed group
- **WHEN** a group has multiple visible sessions and is first shown
- **THEN** the latest updated session is shown and a control reveals the remaining visible sessions

### Requirement: Session pinning
The board SHALL allow pinning one session per group; a pinned session SHALL be the default session opened from the group, SHALL remain visible regardless of age, and SHALL be shown first. Unpinning SHALL restore latest updated ordering.

#### Scenario: Pinned older session
- **WHEN** an older session is pinned and more than one day passes without updates
- **THEN** it remains visible first and is selected when the group is clicked

### Requirement: Time based visibility
The board SHALL hide an unpinned session after 24 hours without conversation activity, including when the session is marked completed, without deleting it. An automatically created project group SHALL hide after seven days without any conversation activity, unless it contains a pinned session. A later update SHALL make the session and group visible again.

#### Scenario: Completed session ages out
- **WHEN** a completed, unpinned session reaches 24 hours since its last conversation update
- **THEN** it is not shown in the group

#### Scenario: Project group ages out
- **WHEN** all sessions in an automatic project group have had no conversation update for seven days and none is pinned
- **THEN** the group is hidden without deleting its persisted data

### Requirement: Existing data compatibility
Existing saved tasks SHALL load without losing groups or sessions, and missing activity timestamps SHALL use a conservative fallback from available task dates.

#### Scenario: Upgrade existing board
- **WHEN** an existing tasks.json is loaded after upgrade
- **THEN** its tasks remain readable and receive visibility behavior without resetting their content
