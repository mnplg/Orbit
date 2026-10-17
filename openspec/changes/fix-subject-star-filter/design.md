# Design

- `BoardView.filtered` checks only `BoardTask.isPinned` on top-level task cards; session pinning and task focus no longer influence this filter.
- The subject star button is always rendered. The source label remains conditional on a preview session.
- Existing session pin data remains intact for conversation visibility and navigation.
