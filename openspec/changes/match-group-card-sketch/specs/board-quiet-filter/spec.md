# Spec Delta

## Purpose

让任务看板在桌面上保持低干扰，同时提供快速聚焦星标事项和明确的单一新增任务入口，减少重复控件和无助于工作的提示。

## ADDED Requirements

### Requirement: Quiet conversation navigation
Clicking a task or conversation SHALL open the available destination without showing a board message about application activation or unavailable native deep links.

#### Scenario: Native route unavailable
- **WHEN** a conversation has no verified direct URL
- **THEN** the board attempts the existing application activation silently and leaves the board layout unchanged

### Requirement: Starred-only filter
The board SHALL provide a header filter that toggles between all visible items and only starred items. Starred results SHALL include a starred subject task, a starred standalone conversation, or a group containing a starred visible session.

#### Scenario: Filter starred sessions
- **WHEN** the user enables the star filter
- **THEN** only groups or conversations matching one of the starred conditions remain visible

### Requirement: Single add entry
The board SHALL show one plus button beside the board title. The title input SHALL remain hidden until that button is clicked, and no second always-visible add row SHALL be rendered.

#### Scenario: Add subject task
- **WHEN** the user clicks the title plus button, enters a title, and submits
- **THEN** one new subject task is created and the input closes
