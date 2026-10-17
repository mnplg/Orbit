# Design

- Choose an initial content height up to 840 points, bounded by the current screen's visible height and the existing minimum window size.
- Keep the current card layout, floating behavior, and scroll view.
- Use AppKit's named window-frame autosave for subsequent size and position changes. Restore saved frames and constrain them to a visible display when monitors change.
