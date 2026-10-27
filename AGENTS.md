# AGENTS.md

This file provides guidance to AI coding agents working with code in this repository.

An Agent Skill (and Claude Code plugin) that has the agent ask questions and decisions a few at a time while it keeps working. The skill is `skills/askloop/`; `SKILL.md` is the whole of it, with no scripts.

## Commands

```sh
tests/run.sh                                         # every case in tests/cases/: one real claude -p run each
tests/run.sh resume-handles-answers-and-feedback     # one case
tests/run.sh --check <run dir>                       # re-check a finished run, no model call
bash -n tests/run.sh tests/lib.sh                    # syntax check
```

Each run uses the user's Claude login (plan usage, or billed with an API key): **never run tests without asking the user first**, and don't add anything (hooks, CI) that runs them automatically. `--check` and the syntax check are free.

A case is `tests/cases/<name>/`: `prompt.md` (the user's message), `check.sh` (shell checks using the helpers in `tests/lib.sh`) and optionally `files/`, copied over the `tests/fixtures/todo-app` project. Multi-turn behaviour (answers, feedback, resuming) is tested by seeding a `.askloop/` file and putting the user's replies in the prompt; the case's own `files/.gitignore` ignores that file, so add it with `git add -f`. Checks are plain code on the files and the final response, never a model: anything that needs judgement (is a question self-contained, is the order sensible) is left to the user reading `final.md` in the run directory. The checks rely on each batch starting with an `Open questions: …` line, as `SKILL.md` requires. Runs load only this plugin (no user settings, plugins or MCP servers) to keep tokens down.

## Design rules

- At most N questions open at once; N is a cap, not a quota. Every question asked must be answered (briefly is fine) before the task is done.
- Questions are plain text between tool calls, so the agent keeps working; no blocking question tool is used. When nothing is left to do, the agent restates the open questions and ends its turn.
- The main agent does the work; subagents only when the user asks.
- While a question is open, the agent does independent groundwork; it may build on its recommendation only for small pieces that are cheap to throw away, never the core choice the question is about.
- One file per question set, `.askloop/<name>.md`, git-ignored; its Decided section is the decisions log.
- Behaviour is documented in `SKILL.md` (for the agent) and `README.md` (for users); keep them in sync. `SKILL.md` is loaded into the agent's context on every use, so keep it tight.

## Releases

Bump `version` in `.claude-plugin/plugin.json` once per push: commits that haven't been pushed yet share one version.
