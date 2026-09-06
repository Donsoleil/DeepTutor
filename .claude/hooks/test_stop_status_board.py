#!/usr/bin/env python3
"""Behaviour tests for stop-status-board.py. Runs the hook as a subprocess,
exactly as Claude Code does: JSON on stdin, verdict on stdout."""

import json
import os
import shutil
import subprocess
import sys
import tempfile

HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "stop-status-board.py")

BOARD = """Here is the answer in prose.

```
MISSION
Ship the thing

SYSTEM STATE
███████████████░░░░░  75%

Completed tasks        9
Blocked                0
Needs judgment         0
```"""

NO_BOARD = "Here is the answer in prose, and nothing else."

PROSE_ONLY = (
    "The MISSION here is unclear and the SYSTEM STATE is unknown, "
    "but I am not drawing a board."
)

HALF = """Prose.

```
MISSION
Ship the thing
```"""


def user(uuid="u1"):
    return {"type": "user", "uuid": uuid, "message": {"content": "do the thing"}}


def assistant(text, sidechain=False):
    return {
        "type": "assistant",
        "isSidechain": sidechain,
        "message": {"content": [{"type": "text", "text": text}]},
    }


def run(entries, home, transcript_path=None, raw_stdin=None):
    """Returns (exit_code, stdout)."""
    tmp = transcript_path
    if tmp is None:
        fd, tmp = tempfile.mkstemp(suffix=".jsonl", dir=home)
        with os.fdopen(fd, "w") as f:
            for e in entries:
                f.write(json.dumps(e) + "\n")
    payload = json.dumps({"transcript_path": tmp}) if raw_stdin is None else raw_stdin
    env = dict(os.environ, HOME=home)
    p = subprocess.run(
        [sys.executable, HOOK], input=payload, capture_output=True, text=True, env=env
    )
    return p.returncode, p.stdout.strip()


def verdict(out):
    if not out:
        return "allow"
    try:
        return json.loads(out).get("decision", "?")
    except json.JSONDecodeError:
        return "unparseable:" + out[:40]


def main():
    results = []

    def check(name, got, want):
        ok = got == want
        results.append((ok, name, got, want))

    # Each case gets a clean HOME so the per-turn counter starts fresh.
    def fresh():
        return tempfile.mkdtemp()

    h = fresh()
    check("board present -> allow", verdict(run([user(), assistant(BOARD)], h)[1]), "allow")

    h = fresh()
    check("no board -> block", verdict(run([user(), assistant(NO_BOARD)], h)[1]), "block")

    h = fresh()
    check(
        "markers in prose, not fenced -> block",
        verdict(run([user(), assistant(PROSE_ONLY)], h)[1]),
        "block",
    )

    h = fresh()
    check(
        "fenced but only one marker -> block",
        verdict(run([user(), assistant(HALF)], h)[1]),
        "block",
    )

    h = fresh()
    check(
        "board only in a subagent message -> block",
        verdict(run([user(), assistant(BOARD, sidechain=True)], h)[1]),
        "block",
    )

    # Cap: same turn three times. Third must allow rather than loop forever.
    h = fresh()
    entries = [user(), assistant(NO_BOARD)]
    fd, path = tempfile.mkstemp(suffix=".jsonl", dir=h)
    with os.fdopen(fd, "w") as f:
        for e in entries:
            f.write(json.dumps(e) + "\n")
    v = [verdict(run(entries, h, transcript_path=path)[1]) for _ in range(3)]
    check("retry cap: block, block, allow", v, ["block", "block", "allow"])

    h = fresh()
    check(
        "malformed stdin -> allow",
        verdict(run([], h, transcript_path="/nonexistent", raw_stdin="{not json")[1]),
        "allow",
    )

    h = fresh()
    check(
        "missing transcript -> allow",
        verdict(run([], h, transcript_path=os.path.join(h, "nope.jsonl"))[1]),
        "allow",
    )

    h = fresh()
    check("empty stdin -> allow", verdict(run([], h, transcript_path="/x", raw_stdin="")[1]), "allow")

    # Exit code must always be 0; a nonzero exit is a hook error, not a verdict.
    h = fresh()
    code, _ = run([user(), assistant(NO_BOARD)], h)
    check("exit code is 0 even when blocking", code, 0)

    failed = 0
    for ok, name, got, want in results:
        print(("PASS  " if ok else "FAIL  ") + name)
        if not ok:
            print("        got:  %r" % (got,))
            print("        want: %r" % (want,))
            failed += 1
    print("\n%d passed, %d failed, %d total" % (len(results) - failed, failed, len(results)))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
