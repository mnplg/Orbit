# Design

## Context

See proposal.md. The app persists `BoardTask` values as JSON and polls Qoder transcripts/hooks plus existing Cursor transcripts. Qoder 0.4.1 on this machine supports links for collaboration discussions but has no verified local-session deep link. Its app URL parser rejects unknown local routes. The existing card expands all children by default and sorts ready sessions ahead of recent ones.

## Goals / Non-Goals

**Goals:** Preserve saved task IDs and content; distinguish conversation activity from UI state changes; keep old records recoverable; provide a truthful navigation result.

**Non-Goals:** Reverse engineer or patch Qoder/Cursor internals; launch a fresh chat when a target cannot be selected.

## Decisions

1. Add `lastActivityAt` and per-session `isPinned` to the persisted model with decoder fallbacks. Transcript modification times and hook events update activity. UI state edits do not extend session lifetime. Existing records fall back to state and creation dates.
2. Derive `visibleChildren` and `visibleGroups` at render time from saved data. Hidden sessions are retained. Parent groups created from project keys expire after seven days of no child activity; manually created groups are retained. A pinned child exempts its group from expiry so its pin remains accessible. Sort pinned first, then activity descending, then stable ID.
3. The collapsed card shows its chosen child. Expansion reveals the remaining visible children. Group click selects pinned child or newest visible child. Controls for expansion, status, pin, and editing have separate click targets.
4. Store an optional direct URL in the existing `link` field. Open only verified URL schemes (HTTP(S) plus known app schemes when a direct link was explicitly supplied). If no exact route is available, activate the source app and display a notice. Do not synthesize Qoder or Cursor URLs from transcript IDs; those APIs are not supported by the installed versions.
5. Remove only the Cursor import button and sheet. Keep Cursor polling for previously saved sessions, matching the user's clarification.

## Risks / Trade-offs

- [No local-session deep link in installed Qoder] → Show a clear notice and provide a direct URL field. This part needs a future vendor route for automatic exact navigation.
- [Legacy timestamps may not reflect last actual message] → Use the most recent available saved date as fallback; new polling writes transcript activity accurately.
- [Clock or file modification anomalies] → Clamp future activity to now when calculating visibility and avoid deleting data.

## Migration Plan

Back up `tasks.json`, build the new app, and restart it. Codable defaults read old records. Reverting the executable leaves added JSON keys ignored by the old decoder.
