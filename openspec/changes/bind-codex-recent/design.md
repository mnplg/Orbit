# Design

- On opening the binding panel, read Codex's unarchived Recent task metadata from its local SQLite database on a background queue. Do not read all old rollout transcripts.
- Combine those metadata candidates with already imported Qoder, Cursor, and Codex conversations. Add a search field and keep the results in a bounded scroll area.
- Import an older Codex task only when selected for binding. Read only that selected task's rollout in the background to recover its current state and latest input. Automatically retain a selected task whose last activity was over one day ago, so the existing expiry rule does not immediately hide it.
- Continue allowing one conversation to be bound to multiple subject tasks and persist the binding.
