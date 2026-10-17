# Spec Delta

## ADDED Requirements

### Requirement: Collect local Codex sessions
The board SHALL collect recent local Codex sessions without modifying Codex data and SHALL group them by working directory using the existing subject-task behavior.

#### Scenario: New Codex conversation
- **WHEN** a recent unarchived Codex task appears in the local database
- **THEN** the board creates one conversation and attaches it to the matching project group

### Requirement: Track Codex response state
The board SHALL show a Codex conversation as waiting while its latest turn is running and ready when the latest turn completes.

#### Scenario: Codex finishes a reply
- **WHEN** a `task_complete` event follows `task_started` in the rollout
- **THEN** the conversation becomes “待我处理” and its activity time is updated

### Requirement: Open the Codex task
Clicking a Codex conversation or its subject task SHALL open the corresponding task in the Codex desktop app when the local app supports the registered task URL.

#### Scenario: Click a Codex conversation
- **WHEN** the user clicks a Codex conversation in the board
- **THEN** the app opens `codex://threads/<thread-id>` for that conversation

### Requirement: Preserve existing integrations
Existing Cursor and Qoder tasks SHALL continue to decode, sync, and display after Codex support is added.

#### Scenario: Upgrade existing task data
- **WHEN** saved task data has no Codex thread ID field
- **THEN** it loads without data loss
