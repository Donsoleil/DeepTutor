#!/usr/bin/env bash
# Install the status board on THIS MACHINE, for every project on it.
#
# Two layers, and they do different jobs:
#
#   1. the RULE  -> ~/.claude/rules/response-footer.md
#      Loaded at the start of every session, in every project. It ASKS for the
#      board. That is enough most of the time and costs ~1.4k tokens.
#
#   2. the HOOK  -> ~/.claude/hooks/stop-status-board.py, registered as `Stop`
#      A turn cannot END until the reply carries the board. This is the layer
#      that survives a long session: rules are context, not configuration, so a
#      4k rule competes with a 400k conversation and loses. A hook does not
#      care what the model decided.
#
# Idempotent. Re-run it any time either file changes.
#
#   bash .claude/install-response-footer.sh            # both layers
#   bash .claude/install-response-footer.sh --rule-only # skip the hook
#
# To remove the hook later: delete its block from ~/.claude/settings.json and
# delete ~/.claude/hooks/stop-status-board.py. A .bak of settings.json is
# written before this script touches it.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

rule_src="$here/rules/response-footer.md"
hook_src="$here/hooks/stop-status-board.py"

[ -f "$rule_src" ] || { echo "missing: $rule_src" >&2; exit 1; }

# ── 1. the rule ───────────────────────────────────────────────────────────
mkdir -p "$config/rules"
cp "$rule_src" "$config/rules/response-footer.md"
echo "rule       $config/rules/response-footer.md"

if [ "${1:-}" = "--rule-only" ]; then
  echo "hook       skipped (--rule-only)"
  echo "scope      every project on this machine"
  exit 0
fi

[ -f "$hook_src" ] || { echo "missing: $hook_src" >&2; exit 1; }

# ── 2. the hook ───────────────────────────────────────────────────────────
mkdir -p "$config/hooks"
cp "$hook_src" "$config/hooks/stop-status-board.py"
chmod +x "$config/hooks/stop-status-board.py"
echo "hook       $config/hooks/stop-status-board.py"

# Register it in settings.json WITHOUT disturbing anything already there.
# Python rather than sed: settings.json is the file that decides what runs on
# every turn, and a regex that half-edits it is a broken session on every
# project at once.
CONFIG_DIR="$config" python3 <<'PY'
import json, os, shutil, sys, time

config = os.environ["CONFIG_DIR"]
path = os.path.join(config, "settings.json")
command = os.path.join("~", os.path.relpath(config, os.path.expanduser("~")), "hooks", "stop-status-board.py") \
    if config.startswith(os.path.expanduser("~")) else os.path.join(config, "hooks", "stop-status-board.py")

data = {}
if os.path.exists(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        print("settings   NOT TOUCHED — %s is unreadable (%s)" % (path, e))
        print("           register the hook by hand, or fix the file and re-run.")
        sys.exit(0)
    if not isinstance(data, dict):
        print("settings   NOT TOUCHED — %s is not a JSON object" % path)
        sys.exit(0)

hooks = data.setdefault("hooks", {})
if not isinstance(hooks, dict):
    print("settings   NOT TOUCHED — `hooks` is not an object")
    sys.exit(0)
stop = hooks.setdefault("Stop", [])
if not isinstance(stop, list):
    print("settings   NOT TOUCHED — `hooks.Stop` is not a list")
    sys.exit(0)

# Already registered? Match on the script name so a moved config dir or a
# hand-edited path still counts as installed.
for group in stop:
    for h in (group or {}).get("hooks", []) if isinstance(group, dict) else []:
        if "stop-status-board" in str((h or {}).get("command", "")):
            print("settings   already registered, left alone")
            sys.exit(0)

# Back up only now, when a write is actually about to happen. Backing up on
# every run would leave a pile of identical .bak files from no-op re-runs.
if os.path.exists(path):
    backup = "%s.bak-%s" % (path, time.strftime("%Y%m%d-%H%M%S"))
    shutil.copy2(path, backup)
    print("backup     %s" % backup)

stop.append({"matcher": "", "hooks": [{"type": "command", "command": command}]})
os.makedirs(config, exist_ok=True)
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("settings   registered in %s (hooks.Stop, %d entr%s now)"
      % (path, len(stop), "y" if len(stop) == 1 else "ies"))
PY

# ── 3. prove it actually gates ────────────────────────────────────────────
# Installing something that silently does nothing is the defect this whole
# board exists to prevent, so the installer checks its own work.
probe_home="$(mktemp -d)"
probe="$probe_home/t.jsonl"
cat > "$probe" <<'JSONL'
{"type":"user","uuid":"probe","message":{"content":"hi"}}
{"type":"assistant","message":{"content":[{"type":"text","text":"no board here"}]}}
JSONL
out="$(printf '{"transcript_path":"%s"}' "$probe" | HOME="$probe_home" python3 "$config/hooks/stop-status-board.py" || true)"
rm -rf "$probe_home"
case "$out" in
  *'"decision"'*'"block"'*) echo "selftest   PASS — a reply with no board is blocked" ;;
  *)                        echo "selftest   FAIL — hook did not block (output: ${out:-<empty>})" ; exit 1 ;;
esac

echo "scope      every project on this machine"
echo "verify     start a session anywhere, run /context, look under Memory files"
