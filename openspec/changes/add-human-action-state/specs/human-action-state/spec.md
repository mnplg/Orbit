# Human action state

## Requirements

### Detect explicit requests for human action

The board SHALL assign `需人工` when the latest completed AI reply explicitly asks the user to clarify a question or take a manual action. It SHALL continue to show `等待 AI` while the reply is in progress.

#### Scenario: AI asks for confirmation

- **WHEN** a Qoder, Cursor, or Codex reply completes with an explicit request for confirmation
- **THEN** its conversation state becomes `需人工`

### Manual correction and persistence

The task and conversation state menus SHALL offer `需人工`, and a manual correction SHALL persist through application restart until new conversation activity changes the state.

### Group presentation

When a visible child conversation is `需人工`, the parent group SHALL show `需人工` ahead of other active states. Its summary count SHALL include only visible `需人工` conversations.
