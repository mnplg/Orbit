# Spec Delta

## Purpose

让没有参与开发的使用者可以从发布压缩包安装任务板、连接本机 AI 编程工具，并理解本地数据与权限边界。

## ADDED Requirements

### Requirement: The project provides a repeatable macOS package
The project SHALL provide a script that rebuilds the app and packages the app bundle, Qoder connector, and HTML guide into one distributable archive.

#### Scenario: Create a release archive
- **WHEN** the maintainer runs the release packaging script
- **THEN** a zip archive containing the app and user-facing guide is produced in the project directory

### Requirement: The project provides an HTML user guide
The project SHALL include a Chinese HTML guide covering installation, first launch, Qoder connection, skin switching, data location, and troubleshooting.

#### Scenario: A new user opens the guide
- **WHEN** a user opens the HTML guide from the release folder
- **THEN** the user can follow it without reading source code or terminal output
