#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${ORBIT_TEST_WORK:-$(mktemp -d /tmp/orbit-synthetic.XXXXXX)}"
mkdir -p "$WORK"
if [[ -z "${ORBIT_TEST_WORK:-}" ]]; then trap 'rm -rf "$WORK"' EXIT; fi
mkdir -p "$WORK/tmp" "$WORK/home" "$WORK/module-cache"
export TMPDIR="$WORK/tmp/"
export HOME="$WORK/home"
export CFFIXED_USER_HOME="$WORK/home"
export ORBIT_SYNTHETIC_ROOT="$WORK"
ulimit -c 0
swiftc -module-cache-path "${ORBIT_MODULE_CACHE:-$WORK/module-cache}" -framework AppKit -framework SwiftUI "$ROOT/Sources/main.swift" "$ROOT/Sources/QoderDesktopNavigator.swift" -o "$WORK/Orbit"
swiftc -module-cache-path "${ORBIT_MODULE_CACHE:-$WORK/module-cache}" -O "$ROOT/Sources/qoder-hook.swift" -o "$WORK/QoderHook"
swiftc -module-cache-path "${ORBIT_MODULE_CACHE:-$WORK/module-cache}" -framework AppKit "$ROOT/Sources/QoderDesktopNavigator.swift" "$ROOT/Tests/QoderDesktopNavigation/main.swift" -o "$WORK/navigation-tests"
for name in codex-internal termination-protection storage-transaction display-clock codex-recent auto-group-repair qoder-resume human-state codex grouping lifecycle persistence cache-concurrency grouping-intent completion-override latest-navigation codex-format poll-snapshot; do
    "$WORK/Orbit" "--$name-self-test"
done
"$WORK/navigation-tests"
# The gate must propagate an actual failing executable; a passing command is an error here.
set +e
"$WORK/Orbit" --intentional-failure-self-test
status=$?
set -e
[[ "$status" -eq 42 ]] || { echo "Failure propagation check failed"; exit 1; }
OUTSIDE="$(mktemp -d /tmp/orbit-synthetic-outside.XXXXXX)"
printf '{}\n' > "$OUTSIDE/sentinel.jsonl"
if ORBIT_READER_ESCAPE="$OUTSIDE" "$WORK/Orbit" --reader-escape-self-test >"$WORK/escape.log" 2>&1; then
    rm -rf "$OUTSIDE"
    echo "Reader boundary spy did not reject external fixture root"; exit 1
fi
/usr/bin/grep -q 'Synthetic reader escaped fixture root' "$WORK/escape.log"
ln -s "$OUTSIDE/sentinel.jsonl" "$WORK/symlink-escape.jsonl"
if ORBIT_SYMLINK_ESCAPE="$WORK/symlink-escape.jsonl" "$WORK/Orbit" --reader-symlink-self-test >"$WORK/symlink.log" 2>&1; then
    rm -rf "$OUTSIDE"
    echo "Reader boundary spy did not reject symlink escape"; exit 1
fi
/usr/bin/grep -q 'Synthetic reader escaped fixture root' "$WORK/symlink.log"
rm -rf "$OUTSIDE"
if [[ "${1:-}" == "--intentional-failure" ]]; then exit "$status"; fi
echo "All synthetic tests passed (normal app never started)."
