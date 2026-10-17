# Task group ordering

## Requirements

### Newest activity first

Active task groups SHALL be ordered by their latest visible conversation activity, newest first, regardless of status. A group without visible conversations SHALL use its own activity timestamp.

#### Scenario: different statuses, different activity time

- **WHEN** two active task groups have different statuses and one conversation was active more recently
- **THEN** the more recently active group appears first
