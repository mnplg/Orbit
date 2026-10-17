# Design

## Context

`BoardSkin` is stored with `@AppStorage`, and `BoardTheme` is injected through SwiftUI's environment. The current cute skin is named `pikachu` and uses a warm yellow/brown palette.

## Goals / Non-Goals

**Goals:** Replace the legacy palette with a navy/yellow/blue theme that works without image assets and remains readable in the narrow floating panel.

**Non-Goals:** Do not add remote assets, network calls, or alter task behavior.

## Decisions

- Rename the skin identifier to `starlight` and use `BoardSkin(rawValue:) ?? .midnight` as the migration fallback. Existing stored `pikachu` values therefore safely return to default dark.
- Use native SwiftUI colors, SF Symbols, rounded cards, and increased border contrast to evoke the reference style without bundling images.

## Risks / Trade-offs

The theme cannot reproduce decorative character illustrations without external assets, but it remains lightweight and consistent on every Mac.

## Migration Plan

Rebuild and relaunch. Users with the removed skin identifier automatically see the default dark theme and can choose “星夜电气”.
