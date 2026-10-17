# Design

- Use the latest visible child conversation timestamp as a subject group's activity time; use the task timestamp for groups without visible conversations.
- Sort all active task groups by newest activity first, regardless of state.
- Keep creation time as a deterministic tie-breaker.
