# Design

## Context

The board currently renders a persistent add row and an in-board navigation notice. The group card layout is already compact, and session stars are persisted through `BoardTask.isPinned`.

## Goals / Non-Goals

**Goals:** Keep navigation silent, make starred work a one-click view, and reduce the add affordance to one title-area plus button.

**Non-Goals:** Change the meaning or persistence of stars, alter session expiry, or add a second navigation mechanism.

## Decisions

1. Remove the notice binding and banner entirely; `openConversation` returns no message and silently returns when no route is available.
2. Compute filtered active and completed arrays in `BoardView`. A group matches when its own task pin, its own conversation pin, or one of its visible child session pins is set. The filter icon remains in the header and changes from outline to filled star.
3. Replace the permanent add row with a `showNewTaskField` state. The single plus button beside the title toggles the field; successful submission closes it.

## Risks / Trade-offs

- [A user may not know why a click did not select a local conversation] → The requested quiet behavior takes precedence; the existing app activation remains available.
- [Star filter can hide all unstarred context] → The filled star icon and tooltip clearly show the active mode.

## Migration Plan

Build and restart the app. No migration is needed because only view state changes.
