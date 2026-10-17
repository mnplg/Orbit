# Tasks

## 1. Ordering behavior

- [x] 1.1 Make session activity the primary sort key, retain stable tie-breaking, and derive group summary time from the newest visible session; verify with the lifecycle self-test.
- [x] 1.2 Add a regression assertion covering an older starred session and a newer unstarred session; verify the group preview and navigation target select the newer session.

## 2. Documentation and validation

- [x] 2.1 Update README behavior notes to describe activity-first ordering and verify the wording matches the UI.
- [x] 2.2 Build, run grouping/lifecycle self-tests, validate this OpenSpec change strictly, and relaunch the app for visual verification.
