#!/usr/bin/env python3
"""Stop hook: a turn does not end until the reply carries the status board.

`.claude/rules/response-footer.md` ASKS for the board. This ENFORCES it.
The difference matters: Claude Code memory and rules are context, not
configuration, so a rule worth 4k tokens competes with a conversation worth
400k and loses. A hook runs as a shell command at a fixed lifecycle point
regardless of what the model decided.

It also carries the board skeleton in its re-prompt, so it works even in a
session where the rule file never loaded at all.

Contract (Claude Code Stop hook):
  stdin   JSON payload with `transcript_path` and `stop_hook_active`
  exit 0, no stdout          -> allow the turn to end
  {"decision":"block",...}   -> re-prompt the model with `reason`

FAILS OPEN, always. Every unexpected condition allows the stop. A hook that
traps a session is worse than no hook, so unparseable input, a missing
transcript, an unreadable counter and an exhausted retry budget all exit 0.

Registered as `Stop`, never `SubagentStop`, so it scopes to the main loop;
sidechain (subagent) entries are skipped for the same reason.
"""

import json
import os
import re
import sys
import tempfile

# Both must appear inside one fenced block for the board to count. Prose that
# happens to say "mission" does not satisfy the gate.
MARKERS = ("MISSION", "SYSTEM STATE")

# Re-prompts per turn. Deliberately below the CLI's global 8-block ceiling so a
# model that will not comply still gets to stop.
CAP = 2

FENCE = re.compile(r"```[^\n]*\n(.*?)```", re.DOTALL)

REPROMPT = """Your reply did not end with the status board, and every reply has to.

Re-send your reply. Keep the prose exactly as it was, then add ONE blank line
and the board below as a fenced plain-text code block, as the last thing in the
message. Nothing after it.

```
MISSION
<one line: what this thread is trying to land>

SYSTEM STATE
███████████████░░░░░  75%

Active agents          0
Completed tasks        0
Blocked                0
Needs judgment         0
High-risk actions      0

────────────────────────

<Group>
✓ <done, verified>       <the evidence>
● <in progress>          <where>
○ <not started>
⊘ <blocked>              <what is blocking>
⚠ <written, unverified>  <what was not run>

────────────────────────

NEEDS YOU

1. <title>
   <the fork, in one line>
   <why no written rule resolves it>
```

Rules that decide what goes in it:
- Never invent a number. Counters come from real session state. Zero is a true
  value and is shown; all five counter rows always appear.
- `✓` means done AND verified, with the evidence named. Code written but never
  run is `⚠`, never `✓`.
- The percentage is derived, completed / total tracked. Nothing tracked means
  no bar and no percentage: drop those two lines.
- The counters are the session's running total; the tree is the current
  picture, so finished items leave the tree once reported.
- Drop NEEDS YOU and the rule above it entirely when nothing needs a human.
  That is the normal state.
- Use the `────` separators shown, only between sections, never at the top or
  bottom. The fence is the frame.

The full spec, if this repo has it, is `.claude/rules/response-footer.md`."""


def allow():
    """Exit 0 with no stdout: the turn is allowed to end."""
    sys.exit(0)


def block(reason):
    json.dump({"decision": "block", "reason": reason}, sys.stdout)
    sys.exit(0)


def read_transcript(path):
    entries = []
    try:
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entries.append(json.loads(line))
                except json.JSONDecodeError:
                    continue  # tolerate a partially-written tail line
    except OSError:
        return []
    return entries


def counter_path():
    """Keyed on $HOME, never the project dir: a counter file inside a git
    working tree shows up as untracked noise in every `git status`."""
    home = os.path.expanduser("~")
    if not home or home == "~" or not os.access(home, os.W_OK):
        home = tempfile.gettempdir()
    directory = os.path.join(home, ".claude", "status-board-hook")
    return directory, os.path.join(directory, "turn-counter.json")


def bump(turn_key):
    """Count re-prompts within one turn, resetting when the turn changes."""
    directory, path = counter_path()
    state = {}
    try:
        with open(path, encoding="utf-8") as f:
            state = json.load(f)
    except (OSError, json.JSONDecodeError, ValueError):
        state = {}
    if not isinstance(state, dict):
        state = {}  # valid-but-non-dict JSON would break .get()
    count = state.get("count", 0) if state.get("turn_key") == turn_key else 0
    count += 1
    try:
        os.makedirs(directory, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump({"turn_key": turn_key, "count": count}, f)
    except OSError:
        pass  # best-effort; the CLI's global cap still bounds the loop
    return count


def boundary_index(entries):
    """Newest real user message. Everything after it is this turn.

    Not meta, not a tool result, not sidechain: a subagent's prompt lands as a
    user-type entry with isSidechain set, and anchoring on one would make the
    gate judge a subagent's output instead of the reply to the human.
    """
    for i in range(len(entries) - 1, -1, -1):
        e = entries[i]
        if (
            e.get("type") == "user"
            and not e.get("isMeta")
            and not e.get("toolUseResult")
            and not e.get("isSidechain")
        ):
            return i
    return -1


def has_board(entries, start):
    """True when a main-loop assistant text block this turn contains a fenced
    block carrying both markers."""
    for e in entries[start + 1 :]:
        if e.get("type") != "assistant" or e.get("isSidechain"):
            continue
        content = (e.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        for blk in content:
            if not isinstance(blk, dict) or blk.get("type") != "text":
                continue
            for fenced in FENCE.findall(blk.get("text") or ""):
                if all(m in fenced for m in MARKERS):
                    return True
    return False


def main():
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        allow()  # unparseable input must never trap the session
    if not isinstance(payload, dict):
        allow()

    entries = read_transcript(payload.get("transcript_path") or "")
    if not entries:
        allow()

    start = boundary_index(entries)
    if has_board(entries, start):
        allow()

    key = "no-boundary"
    if start >= 0:
        e = entries[start]
        key = e.get("uuid") or e.get("timestamp") or "unkeyed"

    if bump(key) > CAP:
        allow()  # said it twice; let the turn end rather than loop

    block(REPROMPT)


if __name__ == "__main__":
    main()
