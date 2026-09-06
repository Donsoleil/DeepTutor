# Response footer — always on

Every reply ends with the status block below. Every reply: a one-line answer, a
long build, a question, an error report. It is the last thing in the message,
after any repo-required receipt, with one blank line above it.

It answers three questions in a fixed order: **where things stand**, **what
happens next**, **who is working on it** — plus the one that matters most,
**what needs a human**.

## The block

```
────────────────────────────────────────
MISSION
<one line — what this thread is trying to land>

STATE
████████████░░░░░░░░  9/15 verified

<Workstream>
✓ <done, verified>        <the evidence>
● <in progress>           <where>
○ <not started>
⊘ <blocked>               <what is blocking>
⚠ <written, unverified>   <what was not run>

────────────────────────

NEXT
<the single next action>

AGENTS
● <name>   <what it owns>       <elapsed>
✓ <name>   <what it returned>

NEEDS YOU
1  <title>
   <the fork, and why no written rule resolves it>
────────────────────────────────────────
```

Compact form — use it when the turn is a single answer with nothing in flight:

```
────────────────────────────────────────
STATE   <what just happened>
NEXT    <next action, or: nothing pending>
AGENTS  none · NEEDS YOU  none
────────────────────────────────────────
```

## Markers

| | meaning | bar |
|---|---|---|
| `✓` | done **and verified** | evidence named in the right column |
| `●` | in progress right now | |
| `○` | not started | |
| `⊘` | blocked | the blocker is named, not "waiting" |
| `⚠` | written but not verified | says what was never run |

## Rules — the block is state, not decoration

1. **Never invent a number.** Counts come from the real task list and the real
   agents this session spawned. `0 agents` is a normal, frequent answer. A field
   with no true value is omitted, never filled with a plausible one.
2. **`✓` requires evidence.** A test that ran, a command with output, a file that
   exists. Code that was written but never executed is `⚠`. This is the whole
   point of the block — a board of unverified `✓` marks is the exact defect these
   repos already track (`docs/RECURRING_DEFECTS.md`): a claim nothing checks.
3. **The bar is derived**, `verified / total tracked`, not a feeling. No tracked
   list means no bar — drop the STATE bar and say what happened in words.
4. **Live state, not a log.** Finished items leave the board once they are
   reported. It shows the current picture, not everything ever done.
5. **NEEDS YOU is expensive — keep it true.** An item belongs there only if it is
   (a) a real fork no written policy resolves, (b) irreversible or outward-facing,
   or (c) a fact only the human has. Anything answerable from the repo gets
   answered, not escalated. Empty is the normal state; when it is empty the
   section is omitted, and the compact line says `NEEDS YOU none`.
6. **AGENTS names them.** "14 agents" tells nobody anything. Each row is one
   agent, what it owns, and its state. None running → `AGENTS none`.
7. **The block never replaces the answer.** It is a footer. The substance goes
   above it, in prose.
8. **It never contradicts a repo receipt.** Where a repo requires its own receipt
   (Changed / Verified / Truth layers / Not claimed / Blockers / Next), the
   receipt is written first and the footer summarizes it. If they disagree, the
   receipt is right and the footer is wrong.

## Where this is installed

- **This repo** — `.claude/rules/response-footer.md`, loaded at the start of every
  session here, including cloud and CI sessions.
- **Every project on a machine** — copy it to `~/.claude/rules/response-footer.md`.
  Run `bash .claude/install-response-footer.sh` from the repo root; it is
  idempotent and re-run to update.

There is no account-wide setting that pushes this to every machine — Claude Code
memory and rules are per-machine and per-repo. The installer covers a machine;
committing this file covers a repo everywhere it is cloned. Run the installer
once on each machine you work from.
