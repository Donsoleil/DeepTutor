@AGENTS.md

## Every reply ends with the status footer

`.claude/rules/response-footer.md` — the ASCII status board that closes **every**
reply, rendered as a fenced plain-text code block: mission, system state, the
counter column, the task tree, and what needs a human. It is loaded automatically
at session start; read it for the exact layout.

A `✓` in that block means done **and verified** — a test that ran, a command with
output, a file that exists. Code written but never executed is `⚠`, never `✓`.
Counts and agent rows come from real session state; an unknown field is omitted,
never filled with a plausible number.

Run `bash .claude/install-response-footer.sh` once per machine to get the same
footer in every project, not just this one.

## Repo contract

The engineering contract for this repo lives in `AGENTS.md`, imported above, and is
shared with every other coding agent. Add Claude-specific instructions here, below
the import — not in `AGENTS.md`.
