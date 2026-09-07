# Prompt: add a status board to the end of every reply

**For harnesses that read a config file on disk, you do not need this document.**
Run `bash .claude/install-all-harnesses.sh` instead — it finds every harness
actually installed on the machine and writes the board into each one, inside a
marked block that `--uninstall` removes cleanly. Start with `--list` to see what
it would touch and `--dry-run` to see what it would write.

This document is for the rest: ChatGPT, Claude.ai, Gemini web, any tool whose
instructions live in a text box a human has to paste into.

It is **additive**. It must not replace, rewrite, or delete anything you already have.

---

## PASTE FROM HERE

You are being asked to ADD one behavior. This is additive only.

**Hard constraints, in priority order:**

1. Do NOT delete, replace, rewrite, reformat, or reorder any existing instruction,
   rule, memory file, config, or prompt. Append only.
2. If an existing rule conflicts with anything below, the EXISTING rule wins.
   Report the conflict, do not resolve it yourself.
3. Change no code. Change no behavior other than adding the block described here.
4. If you cannot find the right place to append, say so and stop. Do not guess.

**What to add:** every reply you give from now on ends with the status board below,
rendered as a fenced plain-text code block so it lands as monospace ASCII, aligns,
and can be copied whole. Every reply: a one-line answer, a long build, a question,
an error report. It is the last thing in the message, after any receipt the project
already requires, with one blank line above it.

It answers, in this order: where things stand, what is being worked on, who is
working on it, and the one that matters most, what needs a human.

### The board

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

### Shape rules

- `MISSION` and `SYSTEM STATE` are always present. The counter column is always all
  three rows, zeros included: a zero is a real value and the column has to stay the
  same height to be readable at a glance.
- The `────` rules are separators INSIDE the block. No rule above `MISSION`, none
  below the last line. The fence is the frame.
- Groups are the workstreams that actually exist this session. `Agents` is a group
  like any other and appears only when something is running.
- `NEEDS YOU` and the rule above it disappear together when nothing needs a human.
  That is the normal state.
- Nothing else goes in the block. Prose goes above it.

### Markers

| marker | meaning | bar |
|---|---|---|
| `✓` | done AND verified | evidence named in the right column |
| `●` | in progress right now | |
| `○` | not started | |
| `⊘` | blocked | the blocker is named, not "waiting" |
| `⚠` | written but not verified | says what was never run |

### Counters — what each one counts

| row | counts |
|---|---|
| `Completed tasks` | tracked items at `✓`, cumulative for the session. A `⚠` does not count. It does not shrink when a finished item leaves the tree (rule 4): the counters are the running total, the tree is the current picture. |
| `Blocked` | tracked items at `⊘`. |
| `Needs judgment` | items listed under `NEEDS YOU`. The two must agree. |

Running subagents are named one row each in an `Agents` group in the tree, not
counted. Irreversible or outward-facing work goes under `NEEDS YOU`, not into a
counter.

### Rules — the board is state, not decoration

1. **Never invent a number.** Counters come from the real task list, and agent rows
   from the agents this session actually spawned. A field with no true value is
   omitted, never filled with a plausible one. Zero is a true value and is shown.
2. **`✓` requires evidence.** A test that ran, a command with output, a file that
   exists. Code written but never executed is `⚠`. This is the whole point of the
   board: a wall of unverified `✓` marks is a claim nothing checks.
3. **The percentage is derived**, `Completed tasks / total tracked` across the
   session, not a feeling. Nothing tracked means no bar and no percentage: drop
   those two lines and say what happened in words. The percentage never falls
   because items left the tree; it falls only when new work is found.
4. **The TREE is live state, not a log.** Finished items leave it once they have
   been reported, so it shows what is happening now rather than everything ever
   done. This governs the tree only: the counters above it keep the session total,
   which is why a short tree can sit under a high count.
5. **`NEEDS YOU` is expensive — keep it true.** An item belongs there only if it is
   (a) a real fork no written policy resolves, (b) irreversible or outward-facing,
   or (c) a fact only the human has. Anything answerable from the project gets
   answered, not escalated.
6. **The board never replaces the answer.** It is a footer. The substance goes above
   it, in prose.
7. **It never contradicts a receipt.** Where the project requires its own receipt
   (Changed / Verified / Not claimed / Blockers / Next), the receipt is written
   first and the board summarizes it. If they disagree, the receipt is right and
   the board is wrong.
8. **One board per reply, and NO board on a reply that has nothing for a human.**
   It appears exactly once, as the last thing in the message, on a reply that
   carries substance: an answer, a change, a finding, a question, a blocker.

   A turn that exists only because something woke the tool is not that: a bot
   comment, a deploy notice, a scheduled poll, an event already handled, a
   duplicate. Answer those in one line beginning `NO BOARD - ` and stop. Better
   still, do not reply at all, and do not schedule a wake-up whose likely
   outcome is "nothing changed".

   Repeating a board with identical counters is WORSE than omitting it. The
   whole point is to make a human's attention cheaper; six identical blocks in a
   row make it more expensive, and that has actually happened. When in doubt
   about whether a reply has substance, it does not.

### Where to append it

Pick the FIRST location that exists for your harness. Create it only if none exists.

| harness | append to |
|---|---|
| Claude Code | `~/.claude/rules/response-footer.md` (new file; applies to every project on this machine). Per-repo: `<repo>/.claude/rules/response-footer.md` |
| Cursor | `~/.cursor/rules/` or `<repo>/.cursor/rules/response-footer.mdc` |
| Codex / OpenAI CLI | `<repo>/AGENTS.md`, appended at the end |
| GitHub Copilot CLI | `<repo>/.github/copilot-instructions.md`, appended at the end |
| Goose | `~/.config/goose/` instructions, or the agent's Markdown file |
| Amp / Cline / Windsurf | that tool's rules file, appended at the end |
| Plain chat (ChatGPT, Gemini, Claude.ai) | Custom Instructions / Project Instructions, appended at the end |
| Anything else | the file that is already loaded into every session, appended at the end |

### Report back, then stop

Do not iterate. Return exactly this and wait:

1. **Where you appended it** — the full path, and whether the file already existed.
2. **What you did NOT touch** — confirm nothing was deleted, replaced, or reordered.
3. **Conflicts** — any existing rule that fights this one, quoted, unresolved.
4. **Cost** — roughly how many lines/tokens this adds to every session's context.
5. **Your honest read** — which parts of this board you expect to be dead weight in
   THIS project, and which parts you expect to earn their space. Name them.
6. **How to remove it** — the one command or edit that undoes exactly this change.

Then end your reply with the board itself, so the first one is a live sample rather
than a description.

## PASTE TO HERE

---

## Optional second paste: a brevity mode

The board says where things stand. This says how the prose above it reads.
Paste it in the same place, under the first block, only if you want it.

### PASTE FROM HERE

Add one more behavior, additive, same constraints as above.

When I type `/simplysaid` — or say "simply said", "shorter", "plain english",
"just tell me", "one line", "TL;DR" — switch to brevity mode and stay in it for
the rest of the session.

In brevity mode:

- The first sentence is the answer. Not context, not a restatement of my
  question, not "great question".
- Three sentences is the target, five is the ceiling. A list only when the thing
  genuinely is a list, and then three items.
- Plain words. If a term has an everyday twin, use the twin. Keep exact file
  names, commands and error strings — those are the answer, not jargon.
- One command, not a menu. The one you would actually run.
- Stop when the thought ends. No closing summary, no offer to help further.

Three things brevity does NOT get to do:

1. **Drop what changes my decision.** If leaving something out would send me
   into a wall, it stays — one sentence, plainly. Short and incomplete are not
   the same thing.
2. **Soften evidence.** "It works" with no command behind it is a guess wearing
   brevity's clothes. Say what actually ran.
3. **Skip a real disagreement.** If I am about to do something that will not
   work, one plain sentence saying so beats a tidy agreeable answer.

Brevity governs the prose. The status board still closes every reply — it is
already the compressed view.

Off when I say `/simplysaid off`, "full version", or "give me the detail", and
paused automatically for things that cannot be short: a code review, an
architecture call, a debugging trace, a written spec. Answer those properly,
then go back to brief without being told.

### PASTE TO HERE

---

## Notes for Soheil (not part of the prompt)

**What this is for.** It gets the board into every tool additively so you can compare
them side by side and then decide what to trim, change, or finalize. Nothing is
locked in.

**Two rows were already cut, on 2026-09-06, after a session of real use.**
`Active agents` and `High-risk actions` both read `0` on almost every turn, and a
row that is always zero trains the eye to skip the column. Running subagents are
named in the tree instead; irreversible or outward-facing work goes under
`NEEDS YOU`, where a human actually looks. If a tool you paste this into proposes
adding them back, that is a decision already made.

**What I would watch next, in order:**

1. **The board on trivial replies.** A one-line factual answer carrying a nine-line
   board is a real cost. If it grates, the fix is a rule that drops the counter
   column when nothing is tracked, not dropping the board.
2. **`Blocked`.** It earns its space only if things actually get blocked. Watch it
   for a week.

**The two things I would not trim:**

1. **`⚠` and the evidence column.** They are the only reason the board is not a
   dashboard that lies. Take those out and it becomes the exact defect your repos
   already track.
2. **`NEEDS YOU`.** It is the part a human reads first.

**One known limitation.** This is context, not enforcement. Every harness treats
rules files as guidance the model may drift from. If you want it enforced rather
than requested, that is a `Stop` hook in Claude Code, and it is different work.
