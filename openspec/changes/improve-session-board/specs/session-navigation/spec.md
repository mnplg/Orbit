# Spec Delta

## Purpose

定义从看板气泡回到原会话的操作及不可导航时的反馈，避免点击后误开不相关或全新的对话，让用户知道当前会话的准确入口。

## ADDED Requirements

### Requirement: Session click destination
Clicking a session bubble SHALL use its saved direct conversation URL when available. Clicking a subject group bubble SHALL target its pinned session, or its latest updated visible session when none is pinned. The board SHALL NOT create a new AI conversation as a substitute for opening the target.

#### Scenario: Session with direct URL
- **WHEN** a session bubble with a valid direct URL is clicked
- **THEN** the system opens that URL

#### Scenario: Group with pinned session
- **WHEN** a group bubble with a pinned session is clicked
- **THEN** it uses that session as the navigation target

### Requirement: Unavailable native route feedback
When no verified native route or saved URL identifies the exact conversation, clicking SHALL activate the source app if installed and SHALL show a clear message that exact navigation is unavailable and that a direct URL may be saved for the session.

#### Scenario: Qoder local session without URL
- **WHEN** a Qoder local session without a direct URL is clicked on a version without session deep linking
- **THEN** Qoder is activated and the board explains why it could not select that conversation
