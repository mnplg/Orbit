# Design

## Context

`BoardModel.assignParent` already validates and persists parent changes, but the subject-task menu only exposes parent choices when the current item is a conversation. `TaskCard` derives its summary from `childSessions.count`, which includes all visible states.

## Goals / Non-Goals

**Goals:**

- Reuse `assignParent` for binding and unbinding.
- Make available sessions selectable from an inline panel opened by the subject-task menu.
- Keep automatic project grouping as the default.
- Count sessions using the same state that drives the summary label.

**Non-Goals:**

- No change to session discovery, expiry, sorting, or task state precedence.
- No deletion or duplication of session records when moving them.

## Decisions

- The binding panel lists all conversation records not already under the selected task, including sessions from other projects. This supports intentional custom cross-project groups.
- The session menu calls `assignParent(..., nil)` for unbinding; the existing model behavior preserves the session as a root conversation.
- The summary count filters `childSessions` by `displayState`, while standalone conversations continue to count as one when their own state matches.

## Risks / Trade-offs

- A manually cross-project-bound session will no longer be recovered by automatic project grouping if later unbound, unless the next polling cycle re-associates it. Existing grouping logic remains the source of truth for unbound sessions.

## Migration Plan

No data migration is needed; `parentID` already stores the relationship.
