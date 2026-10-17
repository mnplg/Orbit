# Design

- Add the persisted state `需人工` to both subject tasks and conversations, with a distinct icon and tint.
- Classify explicit human requests in the latest completed assistant reply from Qoder, Cursor, and Codex. Keep the matching rules conservative; ambiguous replies remain `待我处理`.
- Allow manual correction from existing state menus. Preserve corrections until a new conversation event arrives.
- Give `需人工` groups priority in the active list and count only conversations with the same state in the group summary.
