# Spec Delta

## Purpose

提供一个具有深蓝夜空、蓝色玻璃卡片和荧光黄闪电强调的萌系皮肤，让桌面任务板更接近参考图的轻盈、发光和圆润视觉气质。

## ADDED Requirements

### Requirement: The skin menu offers the new visual style
The board SHALL offer the default dark skin and a “星夜电气” skin, and SHALL no longer offer the former “电气萌黄” skin.

#### Scenario: Choose the starlight skin
- **WHEN** the user opens the palette menu and chooses “星夜电气”
- **THEN** the board applies the navy background, blue panels, yellow accent, and rounded glowing visual treatment

#### Scenario: The old skin is unavailable
- **WHEN** the user opens the palette menu after upgrading
- **THEN** “电气萌黄” is not listed

### Requirement: Existing saved selections remain safe
The board SHALL fall back to the default dark skin when a previously saved skin identifier is no longer supported.

#### Scenario: Legacy skin value is loaded
- **WHEN** the stored skin value is the removed legacy identifier
- **THEN** the board uses the default dark skin without failing to launch
