# Response footer — always on

Every reply ends with the status board below, rendered as a **fenced plain-text
code block** so it lands as monospace ASCII, aligns, and can be copied whole.
Every reply: a one-line answer, a long build, a question, an error report. It is
the last thing in the message, after any repo-required receipt, with one blank
line above it.

It answers, in this order: **where things stand**, **what is being worked on**,
**who is working on it**, and the one that matters most, **what needs a human**.

## The board

````
```
MISSION
<one line — what this thread is trying to land>

SYSTEM STATE
███████████████░░░░░  75%

Active agents          0
Completed tasks        9
Blocked                1
Needs judgment         2
High-risk actions      0

────────────────────────

<Group>
✓ <done, verified>       <the evidence>
● <in progress>          <where>
○ <not started>
⊘ <blocked>              <what is blocking>
⚠ <written, unverified>  <what was not run>

Agents
● <name>                 <what it owns>

────────────────────────

NEEDS YOU

1. <title>
   <the fork, in one line>
   <why no written rule resolves it>
```
````

Shape rules:

- `MISSION` and `SYSTEM STATE` are always present. The counter column is always
  all five rows, zeros included — a zero is a real value and the column has to
  stay the same height to be readable at a glance.
- The `────` rules are separators **inside** the block. No rule above `MISSION`,
  none below the last line. The fence is the frame.
- Groups are the workstreams that actually exist this session. `Agents` is a
  group like any other and appears only when something is running.
- `NEEDS YOU` and the rule above it disappear together when nothing needs a
  human. That is the normal state.
- Nothing else goes in the block. Prose goes above it.

## Markers

| | meaning | bar |
|---|---|---|
| `✓` | done **and verified** | evidence named in the right column |
| `●` | in progress right now | |
| `○` | not started | |
| `⊘` | blocked | the blocker is named, not "waiting" |
| `⚠` | written but not verified | says what was never run |

## Counters — what each one counts

| row | counts |
|---|---|
| `Active agents` | subagents or background tasks running **right now**. Usually 0. |
| `Completed tasks` | tracked items at `✓`. A `⚠` does not count. |
| `Blocked` | tracked items at `⊘`. |
| `Needs judgment` | items listed under `NEEDS YOU`. The two must agree. |
| `High-risk actions` | pending actions that are irreversible or outward-facing: a production migration, a push to a protected branch, real money, real children's data, anything sent outside. |

## Rules — the board is state, not decoration

1. **Never invent a number.** Counters come from the real task list and the real
   agents this session spawned. A field with no true value is omitted, never
   filled with a plausible one. Zero is a true value and is shown.
2. **`✓` requires evidence.** A test that ran, a command with output, a file that
   exists. Code written but never executed is `⚠`. This is the whole point of the
   board — a wall of unverified `✓` marks is the exact defect these repos already
   track (`docs/RECURRING_DEFECTS.md`): a claim nothing checks.
3. **The percentage is derived**, `Completed tasks / total tracked`, not a
   feeling. Nothing tracked means no bar and no percentage — drop those two lines
   and say what happened in words.
4. **Live state, not a log.** Finished items leave the board once they are
   reported. It shows the current picture, not everything ever done.
5. **`NEEDS YOU` is expensive — keep it true.** An item belongs there only if it
   is (a) a real fork no written policy resolves, (b) irreversible or
   outward-facing, or (c) a fact only the human has. Anything answerable from the
   repo gets answered, not escalated.
6. **The board never replaces the answer.** It is a footer. The substance goes
   above it, in prose.
7. **It never contradicts a repo receipt.** Where a repo requires its own receipt
   (Changed / Verified / Truth layers / Not claimed / Blockers / Next), the
   receipt is written first and the board summarizes it. If they disagree, the
   receipt is right and the board is wrong.

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
