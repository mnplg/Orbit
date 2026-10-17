# Spec Delta

## Purpose

让用户以主体任务为单位管理星标，减少会话行中的视觉和操作干扰，同时保留看板按星标筛选任务的能力。

## ADDED Requirements

### Requirement: Subject tasks own the visible star action
The task board SHALL expose the star action on the subject task card and SHALL NOT expose a star action inside individual session rows.

#### Scenario: Session rows contain no star control
- **WHEN** a task group displays its preview or expanded sessions
- **THEN** each session row shows its session actions without a star button

### Requirement: Star filter uses subject task stars
The starred-only filter SHALL include subject tasks starred from the task card, while remaining compatible with existing starred session records.

#### Scenario: Starred subject task appears in starred-only mode
- **WHEN** a subject task is starred and the starred-only filter is enabled
- **THEN** that subject task remains visible
