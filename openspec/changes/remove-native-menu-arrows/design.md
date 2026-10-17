# Design

## Context

SwiftUI's borderless `Menu` supplies a native dropdown indicator on macOS. There is no supported modifier in the current deployment SDK to hide only that indicator while keeping a custom image label.

## Goals / Non-Goals

**Goals:** Replace only the two affected action menus with a button-triggered popover and keep actions, state changes, binding, editing, and deletion intact.

**Non-Goals:** Do not change the palette menu or task behavior.

## Decisions

- Use `Button` with an ellipsis SF Symbol and `.popover` with a compact themed VStack. This removes the native menu indicator entirely and gives the action list a consistent width.

## Risks / Trade-offs

Popover positioning is controlled by macOS and may point to a different edge depending on available space, but the content remains accessible.
