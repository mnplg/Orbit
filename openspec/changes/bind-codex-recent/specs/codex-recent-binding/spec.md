# Codex Recent binding

## Requirements

### Discover older Recent tasks

The binding panel SHALL list unarchived Codex Recent tasks even if their last update is older than the seven-day automatic import window. It SHALL allow searching by task name or project directory.

#### Scenario: older Codex task

- **WHEN** a user opens a subject task's binding panel and searches for a Codex task last updated nine days ago
- **THEN** the task appears as a candidate without reading its rollout transcript

### Bind and retain

Selecting an older candidate SHALL create a persisted conversation binding. If the candidate is over one day old, it SHALL remain visible under the subject task through the existing pinned-conversation exception.

#### Scenario: bind one task to two groups

- **WHEN** an older Codex task is bound to two subject tasks
- **THEN** it appears in both groups after application restart
