# Spec Delta

## Purpose

让桌面任务板在保持默认深色外观的同时提供可切换、可记忆的萌系主题，帮助不同使用者选择更适合自己的桌面视觉风格。

## ADDED Requirements

### Requirement: Users can switch and persist skins
The board SHALL provide a visible skin menu with the default dark skin and an original electric-yellow cute skin, and SHALL persist the selected skin locally across relaunches.

#### Scenario: Switch to the cute skin
- **WHEN** the user chooses the electric-yellow skin from the palette menu
- **THEN** the board immediately updates its background, panels, accents, and header icon

#### Scenario: Relaunch preserves the selected skin
- **WHEN** the user relaunches the board after selecting a skin
- **THEN** the previously selected skin remains active
