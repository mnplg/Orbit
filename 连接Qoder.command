#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
HOOK="$ROOT/Orbit.app/Contents/MacOS/QoderHook"
if [[ ! -x "$HOOK" ]]; then
  echo "请先运行 build.command 构建 Orbit.app"
  exit 1
fi

python3 - "$HOOK" <<'PY'
import json
import os
import shlex
import shutil
import sys
from pathlib import Path

source = Path(sys.argv[1])
support = Path.home() / "Library/Application Support/DeskFocusBoard"
support.mkdir(parents=True, exist_ok=True)
target = support / "QoderHook"
shutil.copy2(source, target)
target.chmod(0o755)

settings = Path.home() / ".qoder/settings.json"
settings.parent.mkdir(parents=True, exist_ok=True)
if settings.exists():
    try:
        data = json.loads(settings.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Qoder 设置文件不是标准 JSON，未修改：{settings}\n{exc}")
    backup = settings.with_name("settings.json.deskfocus-backup")
    shutil.copy2(settings, backup)
else:
    data = {}

command = shlex.quote(str(target))
hooks = data.setdefault("hooks", {})
for event in ("UserPromptSubmit", "Stop"):
    entries = hooks.setdefault(event, [])
    found = any(
        hook.get("command") == command
        for entry in entries if isinstance(entry, dict)
        for hook in entry.get("hooks", []) if isinstance(hook, dict)
    )
    if not found:
        entries.append({"hooks": [{"type": "command", "command": command}]})

temporary = settings.with_suffix(".json.tmp")
temporary.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
os.replace(temporary, settings)
print("已连接 Qoder。请重启 Qoder，然后发送一条消息验证。")
print(f"设置文件：{settings}")
print(f"事件程序：{target}")
PY
