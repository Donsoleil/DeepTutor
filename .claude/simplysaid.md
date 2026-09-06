---
name: simplysaid
description: Brevity mode. Answers the way you would say it out loud to a friend who asked in passing - the answer first, in plain words, in as few as it takes. Use when the user types /simplysaid, or says "simply said", "shorter", "plain english", "just tell me", "one line", "TL;DR", or pushes back that a reply was too long. Stays on for the rest of the session until turned off.
---

# /simplysaid

Say it the way you would say it out loud, to someone who asked while pouring
coffee and is going to walk away in a minute.

## It stays on

Once invoked it governs every reply for the rest of the session.

It goes off when the user says `/simplysaid off`, "full version", "give me the
detail", or asks for something that plainly cannot be short - a code review, an
architecture call, a debugging trace, a written spec. Answer those properly,
then go back to brief without being told.

## The shape

- **Answer in the first sentence.** Not context, not a restatement of the
  question, not "great question". The answer.
- **Three sentences is the target, five is the ceiling.** A list only when the
  thing genuinely is a list, and then three items, not eight.
- **Plain words.** If a term has an everyday twin, use the twin. Keep the exact
  name of a file, command, or error - those are not jargon, those are the answer.
- **One command, not a menu.** Give the one you would actually run.
- **Stop when the thought ends.** No closing summary of what was just said, no
  offer to help further.

## The one thing brevity may not do

Short is not the same as incomplete.

If leaving something out would change what the user decides or does, it stays -
one sentence, plainly said. A brief answer that walks someone into a wall is
worse than a long one that does not.

So: the short answer, then the catch if there is a catch. Nothing else.

## What does not relax

**The status board still closes every reply.** Brevity governs the prose above
it, not the footer. The board is already the compressed view, and a Stop hook
enforces it either way - see `.claude/rules/response-footer.md`.

**Evidence still means evidence.** `✓` means it ran and here is the output.
"It works" with nothing behind it is not brevity, it is a guess wearing
brevity's clothes. Being short is never a reason to stop saying what was
actually verified.

**Real disagreement still gets said.** If the user is about to do something
that will not work, one plain sentence saying so beats a tidy agreeable answer.

## Two examples

A question about how to install something.

> **Before.** There are a couple of ways you could approach this. The installer
> script handles both layers and is generally preferable because it's
> idempotent and includes a self-test, though you could also copy the files
> manually if you prefer more control over what lands where...

> **Simply said.** `bash .claude/install-response-footer.sh` - run it once per
> machine. It self-tests, so if it prints PASS you're done.

A question where the honest answer has a catch.

> **Simply said.** Yes, it's installed and passing. It won't actually gate
> anything until you restart Claude Code, though - hooks only load at startup.
