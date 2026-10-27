---
name: askloop
description: Ask the user questions and decisions a few at a time (at most N open at once, default 3) while you keep working, instead of interrupting with every question or dumping a long list. Questions go into a prioritised backlog file; the ones that unblock work, carry the most weight, or decide which other questions matter are asked first, and the window is refilled as answers arrive. Use when the user invokes /askloop, says things like "ask me 4 at a time", "don't overwhelm me with questions", "keep working while I answer", "batch your questions", or asks to resume a question set.
argument-hint: "[N] <task> | N | resume [name]"
---

# askloop

The user's attention is the scarce resource. Keep at most **N** questions open at any time, ask the most valuable ones first, and keep working while they answer. Every question you ask gets answered before the task is done: the user may answer briefly ("yes", "default", "your call"), but nothing is silently skipped.

Arguments: `$ARGUMENTS`

- `N <task>`: start a new question set for the task with a window of N.
- `<task>`: the same, with N = 3.
- `N` alone: set or change the window for the current conversation. If there's no set yet, start one for the work already under way, collecting any questions already pending in the conversation.
- `resume [name]`: continue an unfinished set from `.askloop/`. Without a name, resume the only unfinished set, or list them and ask which.

If the skill was triggered by the user's wording rather than a command, take N from what they said, else 3.

## The question set file

Keep each set in `.askloop/<name>.md` in the project root, where `<name>` is a short slug of the task (e.g. `auth-refactor`). Add `.askloop/` to `.gitignore` if it isn't there. This file is the source of truth: update it whenever a question is added, asked, answered, or dropped, and re-read it after resuming or after the conversation has been summarised.

```markdown
# auth-refactor
Task: Move session handling out of the auth module.
Window: 3

## Open
- 7. Redis or Postgres for sessions? (asked; blocks: session store)
  Recommendation: Postgres, already in the stack.
- 9. Should UserAuth be renamed to Identity? (asked)

## Queued
- 10. Keep the /legacy-login route? (after 7)

## Decided
- 1. Keep JWT? Yes. (user)
- 3. Test framework: vitest. (user accepted recommendation)
- 4. Logger: the existing one. (agent, conventional default)

## Dropped
- 5. Migrate legacy tokens? Moot after 1.
- 6. How should sessions be stored? Split into 7, 10.

## Assumptions in use
- Session schema drafted assuming 7 = Postgres; redo if not.
```

Number questions with plain numbers (1, 2, 3, …, no prefix) in order of discovery, keep incrementing across batches, and never reuse a number, so the user's replies stay unambiguous.

## Finding and prioritising questions

Start with enough exploration to know what you don't know, then write every question you'd want answered into Queued. Keep adding to it as work raises new ones; don't ask them on the spot.

Before queueing, check you actually need the user. If the code, docs, or a quick experiment can answer it, find out yourself. If it's a low-stakes choice with a clear conventional default, decide it and record it under Decided as "(agent, …)" so the user can see it in the log.

Order the queue by:

1. **Unblocks work**: the answer is needed before you (or anything else) can proceed, especially when it blocks a lot.
2. **Shapes other questions**: the answer decides which later questions exist or matter. Ask these before the questions that depend on them.
3. **Cost of being wrong**: hard-to-reverse or high-impact decisions before cosmetic ones that are easy to change later.

## Asking

Ask in plain text in your normal output, between tool calls, and then **keep working in the same turn**. Don't use a blocking question tool (like `AskUserQuestion`): it stops all work until the user replies, which defeats the point. The user can type replies while you work, and they arrive between your steps.

Each batch looks like this:

```
Open questions: 7, 9 (1 more queued)

7. Redis or Postgres for sessions? This blocks the session store.
    a) Redis  b) Postgres (recommended: already in the stack)

9. Should UserAuth be renamed to Identity? (recommended: yes)

Reply with something like "7b 9 yes". I'm continuing with the token parser meanwhile.
```

- Start every batch with the `Open questions: …` line, listing the numbers asked in this batch, so the user sees at a glance what's waiting on them.
- Write each question in whatever form fits it: options, yes/no, or an open request for information. Give one line of context when the reason isn't obvious, and a recommendation when you have one. No tables.
- Make every question self-contained, including when it's asked again: give all the information needed to answer it and nothing more. Never point back to an earlier message ("see the list above"), and avoid walls of text.
- N is a cap, not a quota. If only two questions matter right now, ask two.
- Questions still unanswered from the previous batch come **first** in the next batch, marked "(still open)" (only these: a question you're asking for the first time isn't still open, even when you restate the batch before ending your turn). They keep their original numbers and count toward N; new questions take the next unused numbers. If you asked 1, 2 and 3 and only 2 and 3 were answered, the next batch is 1, 4 and 5.
- An answered question is closed and never comes up again.

## Handling answers

Check for new user messages after every step. When a reply arrives:

- Map it to question numbers. Accept shorthand ("7b", "9 yes", "10 your call", "default"). "Your call" and "default" mean the recommendation; record them that way. Read an obvious typo as what was meant and say how you read it in your acknowledgement, rather than asking again.
- Check carefully whether each question was actually answered. Feedback isn't an answer: "I don't like b or c", "what does b involve?", or an unclear reply leaves the question open. Then either:
  - **update** it: change the wording, options or context to address the feedback (e.g. drop the rejected options and add new ones), and ask it again under the same number in the next batch; or
  - **split** it, when the feedback shows it's really several decisions: move it to Dropped as "split into 12, 13" and queue the new questions with new numbers.
- Move the answers to Decided, then go through Queued: drop questions the answers made moot (say so briefly), add any new ones they raised, and re-order.
- Acknowledge in one line what you recorded, then refill the window to N with the top of the queue and post the new batch.
- If a reply changes an earlier decision, update Decided and redo the work built on it.

## Working while questions are open

Do the work yourself in the main conversation; one agent is usually faster and avoids conflicting edits. Use subagents only when the user asks for them. Subagents can't ask the user directly, so tell them to return their questions to you instead of guessing; then queue those questions like any other.

Prefer work that doesn't depend on any open question. You may build on a recommendation for an open question only when that work is cheap to undo. Add it under "Assumptions in use", and redo it if the answer differs.

When nothing is left that you can do without answers, end your turn with the open questions (still at most N) as the last thing in your reply, so the user doesn't have to scroll back for them.

## Changing N

On `/askloop N` or "ask me 5 at a time" mid-task, update `Window:` in the file. If N went up, top up the window now. If it went down, leave the questions already asked open, and don't ask more until the open count is below the new N.

## Finishing

The task isn't done while any question is Open or Queued. Once the work is done and the queue is empty, tidy the file into a summary: the task, what was done, Decided (the decisions log), Dropped with reasons, and any assumptions that remain. Then tell the user its path.
