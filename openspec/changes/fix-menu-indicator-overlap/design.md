# Design

## Context

Both menu labels use an `ellipsis` SF Symbol while SwiftUI's borderless `Menu` also renders a native dropdown indicator. The overlap is visible in the compact floating panel.

## Goals / Non-Goals

**Goals:** Replace the duplicated visual affordance with a single chevron while preserving menu actions.

**Non-Goals:** Do not change menu contents, spacing, or task behavior.

## Decisions

Use `chevron.down` as the explicit menu label. It communicates the same action as the native indicator and remains legible at the minimum window width.

## Risks / Trade-offs

The menu loses the familiar ellipsis metaphor, but the single chevron removes ambiguity and matches the system menu affordance.
