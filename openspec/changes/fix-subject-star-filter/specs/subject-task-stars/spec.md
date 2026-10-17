# Spec Delta

## MODIFIED Requirements

### Requirement: Star filter uses subject task stars
The starred-only filter SHALL include a subject task if and only if that subject task is starred. A pinned subject task or pinned conversation SHALL NOT make an unstarred subject task appear in starred-only mode.

#### Scenario: Pinned conversation inside an unstarred subject task
- **WHEN** a subject task is unstarred and one of its conversations is pinned
- **THEN** the subject task is hidden in starred-only mode

#### Scenario: Star an empty subject task
- **WHEN** a subject task has no conversations
- **THEN** its star button remains available, and starring it makes it visible in starred-only mode
