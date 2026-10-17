#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
APP="${ORBIT_BUILD_OUTPUT:-$ROOT/Orbit.app}"
orbit_swift_args=()
if [[ -n "${ORBIT_MODULE_CACHE:-}" ]]; then
  orbit_swift_args=(-module-cache-path "$ORBIT_MODULE_CACHE")
fi
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Orbit</string>
  <key>CFBundleDisplayName</key><string>Orbit</string>
  <key>CFBundleIconFile</key><string>orbit-icon.png</string>
  <key>CFBundleIdentifier</key><string>local.neilbee.deskfocusboard</string>
  <key>CFBundleExecutable</key><string>DeskFocusBoard</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST

swiftc "${orbit_swift_args[@]}" -framework AppKit -framework SwiftUI "$ROOT/Sources/main.swift" "$ROOT/Sources/QoderDesktopNavigator.swift" "$ROOT/Sources/RecoveryViews.swift" -o "$APP/Contents/MacOS/DeskFocusBoard"
swiftc "${orbit_swift_args[@]}" -O "$ROOT/Sources/qoder-hook.swift" -o "$APP/Contents/MacOS/QoderHook"
cp "$ROOT/Assets/starlight-mascot.png" "$APP/Contents/Resources/starlight-mascot.png"
cp "$ROOT/Assets/starlight-clouds.png" "$APP/Contents/Resources/starlight-clouds.png"
cp "$ROOT/Assets/orbit-icon.png" "$APP/Contents/Resources/orbit-icon.png"
echo "已构建：$APP"
