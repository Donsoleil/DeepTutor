#!/usr/bin/env bash
# Install the response footer as a personal rule, so it applies to EVERY
# project on this machine — not just this repo.
#
# Idempotent: re-run it any time the rule changes.
#
#   bash .claude/install-response-footer.sh
#
# Claude Code loads ~/.claude/rules/*.md at the start of every session, in
# every project. There is no account-wide push, so run this once per machine.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/rules/response-footer.md"
dest_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/rules"
dest="$dest_dir/response-footer.md"

[ -f "$src" ] || { echo "missing: $src" >&2; exit 1; }

mkdir -p "$dest_dir"
cp "$src" "$dest"

echo "installed  $dest"
echo "scope      every project on this machine"
echo "verify     start a session anywhere and run /context — look under Memory files"
