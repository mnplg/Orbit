# Design

- Read recent, unarchived task IDs, display names, working directories, rollout paths, and update times from `~/.codex/state_5.sqlite` using SQLite in read-only mode.
- Scan each changed rollout backward for the most recent `task_started`, `task_complete`, or `turn_aborted` event. Cache the result by file size and modification time; perform scanning on a background queue.
- Persist the Codex thread ID in the existing `BoardTask` model and reuse project grouping, multi-subject binding, visibility, status counts, and sorting.
- Open `codex://threads/<id>` for a Codex conversation, with the registered Codex desktop app as the fallback.
- Preserve existing saved tasks by decoding the new thread ID as optional.

The Codex database and rollout formats are local app internals and may change in future Codex releases. A missing or incompatible database yields no new Codex sessions without affecting Cursor or Qoder tracking.
