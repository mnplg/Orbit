# Spec Delta

## Purpose

让主体任务摘要中的会话数量与当前显示的任务状态保持一致，使用户可以直接知道该状态下有多少个会话需要关注。

## ADDED Requirements

### Requirement: Summary count matches the displayed state
The subject-task summary SHALL count only visible child sessions whose state equals the summary's displayed state.

#### Scenario: Ready summary counts ready sessions only
- **WHEN** a subject task displays “待我处理” and has one ready session plus another completed or waiting session
- **THEN** the summary shows one session

#### Scenario: Working summary counts working sessions only
- **WHEN** a subject task displays “进行中” and has multiple child sessions in different states
- **THEN** the summary shows the number of working sessions only
