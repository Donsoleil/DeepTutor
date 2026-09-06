#!/usr/bin/env bash
# Install the status board into every AI coding harness ON THIS MACHINE.
#
# `install-response-footer.sh` next to this file does Claude Code, properly and
# with a self-test. This one does Claude Code (by calling that script) and then
# every OTHER harness it can find.
#
# It never invents a config location. For each harness it PROBES for a directory
# that harness itself creates on install; if that directory is not on this
# machine, the harness is reported `not found` and nothing is written. So the
# script cannot scatter files into paths that nothing reads.
#
# What the probe does and does not prove:
#   proves      the harness is installed here
#   does NOT    prove the target FILENAME is the one that harness reads today
#
# Those filenames move between releases and this script cannot check them from
# your machine. Every write is wrapped in a marked block and `--uninstall`
# removes exactly those blocks, so a wrong guess costs one command to undo.
# `--list` prints the table before it touches anything.
#
#   bash .claude/install-all-harnesses.sh --list       # the table, no writes
#   bash .claude/install-all-harnesses.sh --dry-run    # what it WOULD do
#   bash .claude/install-all-harnesses.sh              # do it
#   bash .claude/install-all-harnesses.sh --uninstall  # remove the blocks
#
# The board text is DERIVED from .claude/rules/response-footer.md at run time --
# everything above its "## Two layers" heading, which is the part that is not
# Claude-Code-specific. There is no second copy of the format to drift.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rule_src="$here/rules/response-footer.md"
skill_src="$here/simplysaid.md"   # payload, not an installed skill (see below)

# A literal tilde held in a variable, because the replacement half of
# ${var/#pat/rep} is tilde-expanded: a bare ~ turns back into $HOME, and the
# \~ that stops that on bash 5 is left as a literal backslash by the bash 3.2
# that ships with macOS. A variable needs no escape and is right on both.
TILDE='~'

BEGIN="<!-- BEGIN status-board (managed by install-all-harnesses.sh) -->"
END="<!-- END status-board -->"

mode="install"
case "${1:-}" in
  --list)      mode="list" ;;
  --dry-run)   mode="dry" ;;
  --uninstall) mode="uninstall" ;;
  "")          ;;
  *) echo "unknown option: $1" >&2; exit 2 ;;
esac

[ -f "$rule_src" ] || { echo "missing: $rule_src" >&2; exit 1; }

# label | probe (must already exist) | target file
targets=(
  "Cursor|$HOME/.cursor|$HOME/.cursor/rules/response-footer.mdc"
  "Codex CLI|$HOME/.codex|$HOME/.codex/AGENTS.md"
  "Gemini CLI|$HOME/.gemini|$HOME/.gemini/GEMINI.md"
  "Goose|$HOME/.config/goose|$HOME/.config/goose/.goosehints"
  "opencode|$HOME/.config/opencode|$HOME/.config/opencode/AGENTS.md"
  "Amp|$HOME/.config/amp|$HOME/.config/amp/AGENTS.md"
  "Windsurf|$HOME/.codeium/windsurf|$HOME/.codeium/windsurf/memories/global_rules.md"
  "GitHub Copilot|$HOME/.config/github-copilot|$HOME/.config/github-copilot/instructions.md"
)

if [ "$mode" = "list" ]; then
  printf '%-16s %-40s %s\n' "HARNESS" "PROBE (must exist)" "WOULD WRITE"
  printf '%-16s %-40s %s\n' "Claude Code" "$TILDE/.claude" "rule + hook + settings.json + skill"
  for t in "${targets[@]}"; do
    IFS='|' read -r label probe target <<<"$t"
    printf '%-16s %-40s %s\n' "$label" "${probe/#$HOME/$TILDE}" "${target/#$HOME/$TILDE}"
  done
  exit 0
fi

# The harness-neutral half of the rule: everything before "## Two layers".
payload() {
  printf '%s\n\n' "$BEGIN"
  printf '%s\n' "Every reply ends with the status board below. Added by install-all-harnesses.sh;"
  printf '%s\n\n' "remove with that script's --uninstall. Nothing else in this file was changed."
  sed -n '1,/^## Two layers/p' "$rule_src" | sed '$d'
  printf '\n%s\n' "$END"
}

# Remove a previously written block, leaving everything else as it was.
# Blank lines are buffered and only emitted once a kept line follows, so the
# separator newline that write_one adds before the block is removed with it --
# without that, every re-run would leave one more blank line behind. Trailing
# blank lines at true EOF are re-emitted by the END rule.
strip_block() {
  local f="$1"
  [ -f "$f" ] || return 0
  grep -qF "$BEGIN" "$f" || return 0
  awk -v b="$BEGIN" -v e="$END" '
    index($0,b) { skip=1; nblank=0 }
    !skip {
      if ($0 == "") { nblank++ }
      else { while (nblank-- > 0) print ""; nblank=0; print }
    }
    index($0,e) { skip=0 }
    END { while (nblank-- > 0) print "" }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

# A file we created and that now holds nothing but frontmatter is our litter,
# not the user's config. Uninstall should leave no trace of a harness we only
# ever wrote a block into.
drop_if_empty() {
  local f="$1"
  [ -f "$f" ] || return 0
  # strip a leading --- ... --- frontmatter block, then look for any real line
  if awk 'NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; next} fm {next}
          NF {found=1} END {exit found?1:0}' "$f"; then
    rm -f "$f"
    return 1
  fi
  return 0
}

write_one() {
  local label="$1" target="$2" existed="$3"
  if [ "$mode" = "dry" ]; then
    printf '  %-16s would write  %s%s\n' "$label" "${target/#$HOME/$TILDE}" "$existed"
    return
  fi
  mkdir -p "$(dirname "$target")"
  strip_block "$target"                       # idempotent: replace, never stack
  if [ -s "$target" ]; then printf '\n' >> "$target"; fi
  # Cursor .mdc wants frontmatter to apply globally; only on a fresh file.
  if [ ! -s "$target" ] && [ "${target##*.}" = "mdc" ]; then
    printf -- '---\ndescription: Status board footer\nalwaysApply: true\n---\n\n' > "$target"
  fi
  payload >> "$target"
  printf '  %-16s %s%s\n' "$label" "${target/#$HOME/$TILDE}" "$existed"
}

echo "harnesses found on this machine:"
found=0

# ── Claude Code: the one that is verified, so it gets the real installer ──
if [ -d "$HOME/.claude" ] || [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
  found=$((found+1))
  case "$mode" in
    dry)       printf '  %-16s would run install-response-footer.sh (rule + hook + settings)\n' "Claude Code" ;;
    uninstall) printf '  %-16s left alone -- remove the hook by hand (see install-response-footer.sh header)\n' "Claude Code" ;;
    *)
      out=$(bash "$here/install-response-footer.sh" 2>&1) || { echo "$out" >&2; exit 1; }
      printf '  %-16s %s\n' "Claude Code" "$(echo "$out" | grep -c . ) lines, $(echo "$out" | grep -o 'selftest.*' || echo 'installed')"
      # /simplysaid ships as a payload file in the repo, never as a checked-in
      # skill: little-bellies ignores .claude/skills/ on purpose (its CLAUDE.md
      # keeps personal skills in ~/.agents/skills). Install it to Claude Code's
      # own skills dir, and to ~/.agents/skills too when that already exists --
      # probed, never created, same rule as every other harness here.
      if [ -f "$skill_src" ]; then
        for sd in "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills" "$HOME/.agents/skills"; do
          [ "$sd" = "$HOME/.agents/skills" ] && [ ! -d "$sd" ] && continue
          mkdir -p "$sd/simplysaid"
          cp "$skill_src" "$sd/simplysaid/SKILL.md"
          printf '  %-16s /simplysaid -> %s\n' "" "${sd/#$HOME/$TILDE}/simplysaid/SKILL.md"
        done
      fi
      ;;
  esac
else
  printf '  %-16s not found\n' "Claude Code"
fi

# ── every other harness: probe, then write a marked block ─────────────────
for t in "${targets[@]}"; do
  IFS='|' read -r label probe target <<<"$t"
  if [ ! -d "$probe" ]; then
    printf '  %-16s not found\n' "$label"
    continue
  fi
  found=$((found+1))
  if [ "$mode" = "uninstall" ]; then
    strip_block "$target"
    if drop_if_empty "$target"; then
      printf '  %-16s block removed from %s\n' "$label" "${target/#$HOME/$TILDE}"
    else
      printf '  %-16s removed %s (nothing else was in it)\n' "$label" "${target/#$HOME/$TILDE}"
    fi
    continue
  fi
  if [ -f "$target" ]; then existed="  (appended)"; else existed="  (created)"; fi
  write_one "$label" "$target" "$existed"
done

echo
echo "$found harness(es) found."
case "$mode" in
  dry)       echo "dry run -- nothing was written. Drop --dry-run to do it." ;;
  uninstall) echo "blocks removed. Claude Code's hook is separate; see install-response-footer.sh." ;;
  *)
    echo "Filenames above are best-effort per harness -- confirm each tool actually"
    echo "reads its file, and re-run with --uninstall if one is wrong."
    echo "Harnesses with no config file (ChatGPT, Claude.ai, Gemini web) take the"
    echo "paste-in prompt instead: .claude/ADD-STATUS-BOARD.md"
    ;;
esac
