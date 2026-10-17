# Design

## Context

The app is a local SwiftUI/AppKit bundle built by `build.command`. It reads Cursor and Qoder data from the current user's home directory and stores tasks under Application Support. There is no signing or installer dependency.

## Goals / Non-Goals

**Goals:**

- Keep the existing dark skin unchanged.
- Add an original yellow/brown/red-cheek cute skin using native SwiftUI colors and symbols.
- Make distribution one command and explain Gatekeeper, permissions, and Qoder setup.

**Non-Goals:**

- No App Store signing, notarization, or auto-update service.
- No external image assets or network service.

## Decisions

- Store the selected skin with `@AppStorage` so it is local, small, and independent from task data.
- Put the palette menu in the board header and propagate a theme value through SwiftUI's environment, keeping component styling consistent.
- Package the `.app`, `连接Qoder.command`, and `使用文档.html` with `ditto` so resource forks and bundle metadata are preserved.

## Risks / Trade-offs

- Unsigned apps may trigger macOS Gatekeeper. The guide explains opening via Control-click → Open; notarization can be added later for a public release.

## Migration Plan

Existing task data and the default skin remain unchanged. Rebuild and relaunch to receive the new menu.
