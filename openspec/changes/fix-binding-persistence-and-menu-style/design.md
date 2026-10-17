# Design

## Context

The legacy model stores one `parentID` per conversation. The prior manual binding feature appended no relationship and therefore could not represent multiple groups. Existing automatic grouping depends on `parentID == nil` to decide whether a session needs a project group.

## Goals / Non-Goals

**Goals:**

- Add a backward-compatible list of additional subject-task IDs.
- Keep the legacy primary `parentID` working for automatically grouped sessions.
- Query children through a single membership helper and scope unbinding to the current card.
- Restore `...` as the menu label without adding a custom arrow.

**Non-Goals:**

- No change to session discovery or activity ordering.
- No automatic removal of duplicate historical records.

## Decisions

- Store extra manual memberships in `boundParentIDs`; decode missing values as an empty list. A session belongs to a task when either `parentID` matches or the list contains that task ID.
- Keep the primary `parentID` for legacy automatic grouping and promote an additional membership when removing that primary relationship.
- Pass the current parent ID into `SessionRow` so “移出主体任务” removes only that membership.
- Use the ellipsis SF Symbol as the Menu label and leave the system menu indicator as the only arrow affordance.

## Risks / Trade-offs

- The JSON model gains a new optional field, but old files remain readable. A session with many manual groups has a larger record and appears in more cards by design.

## Migration Plan

No migration is required. Existing `parentID` values remain valid and new `boundParentIDs` values default to empty.
