# Spec Delta

## Purpose

让星夜电气皮肤包含可离线使用的原创插画与夜空装饰，在紧凑的桌面浮窗中形成更鲜明的角色和场景氛围。

## ADDED Requirements

### Requirement: Illustrated starlight skin
The board SHALL show a locally bundled original character illustration behind the top-right header area and a locally bundled night-cloud illustration behind the bottom area when the starlight skin is selected. The artwork SHALL NOT change the header or task list layout.

#### Scenario: Display starlight skin offline
- **WHEN** the user selects the starlight skin without network access
- **THEN** both illustrations display and the task controls remain readable and usable

### Requirement: Artwork is bundled for distribution
The build SHALL copy required artwork into the app bundle, and the release archive SHALL include the complete app bundle.

#### Scenario: Build a release archive
- **WHEN** the release packaging command runs
- **THEN** the archive contains the original illustration files in the app resources directory
