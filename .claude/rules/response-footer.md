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

Completed tasks        9
Blocked                1
Needs judgment         2

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
  all three rows, zeros included — a zero is a real value and the column has to
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
| `Completed tasks` | tracked items at `✓`, **cumulative for the session**. A `⚠` does not count. It does not shrink when a finished item leaves the tree (rule 4) — the counters are the running total, the tree is the current picture. |
| `Blocked` | tracked items at `⊘`. |
| `Needs judgment` | items listed under `NEEDS YOU`. The two must agree. |

Two counters were tried and cut, and the information they carried did not go
away — it moved somewhere it reads better:

- **Running agents** are named in the `Agents` group in the tree, one row each
  with what it owns. A bare count said nothing a name does not say better, and
  it was `0` almost every turn.
- **Irreversible or outward-facing work** — a production migration, a push to a
  protected branch, real money, real children's data, anything sent outside —
  belongs under `NEEDS YOU`, which is where a human actually looks. A counter
  that reads `0` on almost every turn trains the eye to skip it.

## Rules — the board is state, not decoration

1. **Never invent a number.** Counters come from the real task list, and agent
   rows from the agents this session actually spawned. A field with no true
   value is omitted, never filled with a plausible one. Zero is a true value and
   is shown.
2. **`✓` requires evidence.** A test that ran, a command with output, a file that
   exists. Code written but never executed is `⚠`. This is the whole point of the
   board — a wall of unverified `✓` marks is the exact defect these repos already
   track (`docs/RECURRING_DEFECTS.md`): a claim nothing checks.
3. **The percentage is derived**, `Completed tasks / total tracked` across the
   session, not a feeling. Nothing tracked means no bar and no percentage — drop
   those two lines and say what happened in words. The percentage never falls
   because items left the tree; it falls only when new work is found.
4. **The TREE is live state, not a log.** Finished items leave it once they have
   been reported, so it shows what is happening now rather than everything ever
   done. This governs the tree only — the counters above it keep the session
   total, which is why a short tree can sit under a high count.
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
8. **One board per reply — and no reply that only carries a board.** It appears
   exactly once, as the last thing in the message. Never twice in one message,
   and never a second copy of the same state in the message straight after. A
   scheduled check-in, a poll, or any wake-up that finds nothing changed should
   not produce a reply at all; where the harness forces one, it is a single line
   naming what did not change, plus the one board. Two boards in a row carrying
   identical counters is the exact failure this rule exists to stop — it teaches
   the reader to skip the block, which costs more than the block earns.

## Two layers: this file asks, the hook enforces

This file is **context**, not configuration. Claude Code's own docs are explicit
that CLAUDE.md and rules shape behaviour but are not an enforcement layer, and
the failure is measurable: in a session with 424k tokens of conversation, a 4k
rule is outvoted. The board stops appearing and nothing reports that it stopped.

So there are two layers, and they do different jobs.

| | what it is | what it does |
|---|---|---|
| `.claude/rules/response-footer.md` | this file, loaded every session | **asks** for the board, and is the full spec |
| `.claude/hooks/stop-status-board.py` | a `Stop` hook | **a turn cannot end** until the reply carries the board |

The hook re-prompts with the board skeleton inline, so it also works in a
session where this file never loaded. It fails open on every unexpected
condition — unparseable input, a missing transcript, an exhausted retry budget
— because a hook that traps a session is worse than no hook. It re-prompts at
most twice per turn.

## Where this is installed

- **This repo** — `.claude/rules/response-footer.md`, loaded at the start of
  every session here, including cloud and CI sessions.
- **Every project on a machine** — `bash .claude/install-response-footer.sh`
  from the repo root. It copies the rule to `~/.claude/rules/`, the hook to
  `~/.claude/hooks/`, registers the hook in `~/.claude/settings.json` under
  `hooks.Stop` without disturbing anything already there (it backs the file up
  first), and then proves the hook actually blocks a board-less reply before it
  reports success. Idempotent; re-run it to update. `--rule-only` skips the
  hook.

There is no account-wide setting that pushes this to every machine — Claude Code
memory, rules and hooks are per-machine and per-repo. The installer covers a
machine; committing these files covers a repo everywhere it is cloned. Run the
installer once on each machine you work from.

Behaviour tests for the hook: `python3 .claude/hooks/test_stop_status_board.py`.
Ten cases, including every fail-open path. No CI here runs them; the installer's
own self-test is the check that runs every time.
