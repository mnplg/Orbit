# Design

## Context

The group header currently renders a star button that calls the session-only `setPinned` method, and expanded `SessionRow` views can render another star button. The persisted `isPinned` field is shared by legacy session records and task records.

## Goals / Non-Goals

**Goals:**

- Bind the header star to the subject task record.
- Remove all star controls from session rows.
- Preserve old data and existing starred-only filtering behavior.

**Non-Goals:**

- Do not delete persisted session star flags.
- Do not change session ordering or expiry behavior.

## Decisions

- Add a general task-star toggle for the header and keep `setPinned` for legacy session pinning and expiry compatibility. This avoids a data migration while separating the new UI meaning from the old session operation.
- Keep the filter's legacy child-session check so users do not lose groups that were previously starred; new interactions create subject-task stars.

## Risks / Trade-offs

- Old session star flags can still affect filtering and expiry, but users can no longer create new ones through the UI. This preserves backward compatibility.

## Migration Plan

No migration is needed. Rebuild and relaunch the app; all existing task data remains readable.
