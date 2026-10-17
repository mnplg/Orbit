# Spec Delta

## Purpose

定义桌面看板主体任务卡片的上下两层视觉结构，让用户先看见任务摘要，再在清晰的内嵌区域查看当前会话，并保持已有操作随手可用。

## ADDED Requirements

### Requirement: Compact group summary
The board SHALL render a group header with the subject name on the left, status, elapsed time, and visible session count together in the middle, and source plus separate session star and group pin controls on the right. The summary SHALL remain readable at the board's minimum window width.

#### Scenario: Group with a Qoder session
- **WHEN** a group has a visible Qoder session
- **THEN** its header shows the subject name, status, time, session count, Qoder source, session star, and group pin without putting the summary on separate card rows

### Requirement: Bordered conversation section
The board SHALL put a divider beneath the group header and SHALL place the preview session's full title and status/time in one bordered inner section. When more than one session is visible, that section SHALL include the expand/collapse control and the expanded session rows.

#### Scenario: Multiple sessions
- **WHEN** a group with multiple visible sessions is collapsed
- **THEN** the inner section shows the preview and an expand control; expanding reveals the remaining visible sessions inside the same section

### Requirement: Existing card actions
The new layout SHALL keep group navigation, session navigation, status changes, editing, group pinning, and per-session pinning accessible without confusing their click targets.

#### Scenario: Clicking group summary
- **WHEN** the subject name or summary is clicked
- **THEN** the board applies the existing group navigation behavior, while pin and menu controls perform their own actions
