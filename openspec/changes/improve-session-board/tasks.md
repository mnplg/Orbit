# Tasks

## 1. Data and visibility

- [x] 1.1 Add backward-compatible session activity and pin fields; verify a legacy tasks.json loads in the self-test.
- [x] 1.2 Record real Qoder/Cursor conversation activity during polling; verify later activity updates the saved timestamp.
- [x] 1.3 Implement 24-hour session and 7-day automatic group visibility, pin priority, and latest ordering; verify threshold, completion, and revival cases in the self-test.

## 2. Board interaction

- [x] 2.1 Make groups collapsed by default with newest session preview and expandable remaining sessions; verify UI renders both states.
- [x] 2.2 Add per-session pin control, compact right-aligned group heading, aligned session content, and remove the Cursor import sheet; verify UI and existing Cursor polling.
- [x] 2.3 Add group/session bubble click targets with saved direct URL and truthful fallback notice; verify destination selection and URL handling.

## 3. Delivery

- [x] 3.1 Update README, validate OpenSpec, run self-tests, build the app, and restart it; verify the running executable and persisted data.
