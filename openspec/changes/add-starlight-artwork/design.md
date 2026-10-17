# Design

## Context

The native app is compiled directly with `swiftc` and does not use an asset catalog. `BoardView` already selects between default dark and starlight themes.

## Goals / Non-Goals

**Goals:** Add local art while keeping the existing compact controls readable and leaving the default skin unchanged.

**Non-Goals:** No remote image loading or animated assets.

## Decisions

- Store two generated PNGs in `Assets/` and copy them to `Contents/Resources` during build. Load them from `Bundle.main` in SwiftUI.
- Render the mascot at the top right and the clouds at the bottom inside the board background. The artwork does not reserve space or change the existing header and task list positions.
- Keep artwork limited to the starlight skin.

## Risks / Trade-offs

- The art increases the application size; PNG resources remain small enough for the existing zip distribution.
