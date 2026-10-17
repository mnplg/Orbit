# Spec Delta

## Purpose

让任务板的操作菜单在窄窗口中保持清晰、单一的下拉入口，避免自定义图标和系统指示器重叠。

## ADDED Requirements

### Requirement: Menus show one non-overlapping indicator
The board SHALL render one clear dropdown indicator for each subject-task and session action menu, without an additional ellipsis icon occupying the same control.

#### Scenario: Subject task menu in a narrow card
- **WHEN** a subject task card is rendered at the board's minimum width
- **THEN** its action menu shows one non-overlapping dropdown indicator

#### Scenario: Session menu in an expanded group
- **WHEN** an expanded session row is rendered
- **THEN** its action menu shows one non-overlapping dropdown indicator
