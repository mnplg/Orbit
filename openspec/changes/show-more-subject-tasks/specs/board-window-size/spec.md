# Spec Delta

## ADDED Requirements

### Requirement: More visible subject tasks
On first launch, the board SHALL use available screen height to display more subject-task cards than the previous fixed 610-point window, without compressing the cards.

#### Scenario: First launch on a tall display
- **WHEN** the board has no saved frame and the display has enough visible space
- **THEN** it opens at up to 840 points tall and the task list remains scrollable

### Requirement: Remember window geometry
The board SHALL restore the user's resized and moved window frame on later launches, keeping the window within a visible display.

#### Scenario: User resizes the board
- **WHEN** the user changes the board size and restarts the app
- **THEN** the board reopens at the saved size and position
