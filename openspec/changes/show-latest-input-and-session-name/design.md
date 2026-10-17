# Design

- Add an optional, locally persisted `lastUserPreview` to each conversation. Save at most 30 Unicode characters plus an ellipsis and collapse whitespace.
- Read the latest text input from Qoder user events, Cursor user events, and Codex user response items. Ignore tool results and Codex environment context records. For Codex messages with generated file metadata, use the text after `## My request:`.
- Backfill existing conversations during normal polling while retaining their editable `title` values.
- In `SessionRow`, put the input preview on the first line and the session title at the right of the status/time line. Keep the menu position and row navigation.
- Use a mapped rollout file and backward searches for Codex so reading a long conversation stays responsive.
