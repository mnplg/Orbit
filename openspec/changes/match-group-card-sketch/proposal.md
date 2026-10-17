# Proposal

## Why

任务组卡片需要更贴近用户提供的草图，同时减少不必要的反馈和入口，让桌面看板保持安静、直接。

## What Changes

- 移除点击会话后关于唤起 Qoder 或无法直达的文字提示。
- 在标题区增加“只看星标”筛选按钮，筛选主体任务和会话星标。
- 删除内容区的大号新增任务输入框，只在“桌面任务板”标题旁保留一个加号；点击后才显示输入框。

## Capabilities

### New Capabilities

- `board-quiet-filter`: 安静的会话导航、星标筛选和单一新增入口。

### Modified Capabilities

无。

## Impact

`Sources/main.swift` 的 `BoardView`、导航反馈和过滤逻辑，及 README 使用说明。任务数据格式保持不变。
