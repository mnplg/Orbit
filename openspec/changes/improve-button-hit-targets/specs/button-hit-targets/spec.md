# Spec Delta

## ADDED Requirements

### Requirement: Reliable control targets
The board SHALL provide an explicit hit area around icon-only actions in the header, subject task cards, and session rows, and around the conversation expand row.

#### Scenario: Click beside an icon glyph
- **WHEN** the pointer clicks within the visible control's surrounding hit area
- **THEN** the associated action is triggered without requiring a click directly on the glyph

#### Scenario: Click a conversation expand row
- **WHEN** the pointer clicks within the available expand-row width
- **THEN** the conversation list toggles between expanded and collapsed
