#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
ARCHIVE="$ROOT/Orbit-发布.zip"
STAGE="$(mktemp -d -t deskfocus-release)"
trap 'rm -rf "$STAGE"' EXIT

"$ROOT/build.command"
mkdir -p "$STAGE/Orbit"
cp -R "$ROOT/Orbit.app" "$STAGE/Orbit/"
cp "$ROOT/连接Qoder.command" "$ROOT/使用文档.html" "$STAGE/Orbit/"
cp "$ROOT/README.md" "$STAGE/Orbit/" 2>/dev/null || true
ditto -c -k --sequesterRsrc --keepParent "$STAGE/Orbit" "$ARCHIVE"
echo "已生成：$ARCHIVE"
