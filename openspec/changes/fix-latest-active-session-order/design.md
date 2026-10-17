# Design

## Context

The model already persists `lastActivityAt` and `isPinned` for conversation sessions. The view derives group children from `BoardModel.visibleChildren`, while group navigation uses the first visible child. The current comparator applies `isPinned` before activity, which is the source of the stale preview.

## Goals / Non-Goals

**Goals:**

- Make activity time the primary ordering key for both preview and expanded rows.
- Keep existing star persistence, expiry exemption, and starred-only filtering intact.
- Keep ordering deterministic for equal timestamps.

**Non-Goals:**

- No data migration or change to the meaning of a star.
- No change to session discovery, project grouping, or direct-link launching.

## Decisions

- Compare `lastActivityAt` before `isPinned`; use the pin flag only as a tie-breaker. This centralizes ordering so previews, navigation, and expanded rows agree. An alternative separate view-only sort was rejected because it could leave group clicks opening a different session from the one shown.
- Derive the group summary time from the newest visible child's `lastActivityAt`. This avoids showing an older state transition time when a newer child is active.
- Add a regression assertion to the lifecycle self-test with an older starred session and a newer unstarred session.

## Risks / Trade-offs

- A starred older session may move below a newer session in the expanded list. This is intentional: the star remains available for filtering and expiry protection, while recency communicates current work.

## Migration Plan

No persisted data migration is needed. Rebuild and relaunch the app; existing timestamps and stars are read as-is.
