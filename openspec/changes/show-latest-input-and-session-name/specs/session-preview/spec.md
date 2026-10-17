# Spec Delta

## ADDED Requirements

### Requirement: Latest human input preview
Each conversation row SHALL show the latest human-written text input, limited to 30 characters with an ellipsis when longer. Tool output SHALL NOT replace the preview.

#### Scenario: User sends another message
- **WHEN** a tracked conversation receives a new user text message
- **THEN** the first row line updates to that message's short preview

### Requirement: Separate session name
Each conversation row SHALL show its editable session name on the right side of the status and time line.

#### Scenario: User edits the session name
- **WHEN** the user renames a conversation from its menu
- **THEN** the right-side name updates without changing the latest-input preview

### Requirement: Upgrade existing task data
Saved conversation data without a preview field SHALL load and acquire a preview from its local transcript during the next scan.

#### Scenario: Existing conversation record
- **WHEN** the board opens task data saved before the preview field existed
- **THEN** it loads successfully and preserves the existing session name
