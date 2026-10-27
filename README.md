# askloop

An agent skill for Claude Code and other AI coding agents that paces its questions. You pick how many questions or decisions may be open at once (usually 3 to 5); the agent asks the most important ones first, keeps working while you answer, and refills the window as answers come in, until nothing is left to decide.

## Features

- **A window of N open questions**, default 3. It's a cap, not a quota.
- **Prioritised:** questions that unblock work, decide which other questions matter, or are expensive to get wrong are asked first.
- **Keeps working:** questions are plain text, so the agent carries on with work that doesn't depend on them. Reply whenever you like.
- **Short replies:** "7b 9 yes 10 your call".
- **Nothing skipped:** unanswered questions are asked again, first, in the next batch.
- **Backlog and decisions log** in one file per task, `.askloop/<name>.md` (git-ignored), which you can read or edit at any time.
- **Resumable:** `/askloop resume auth-refactor`.

## Install

The skill is the `skills/askloop` directory, in the [Agent Skills](https://agentskills.io) format.

**Claude Code (plugin):** this repo is also a plugin marketplace:

```
/plugin marketplace add dylanbr/askloop-agent-skill
/plugin install askloop@askloop
```

**Claude Code (manual):** copy or symlink the skill into your personal or project skills directory:

```sh
ln -s "$PWD/skills/askloop" ~/.claude/skills/askloop        # all projects
ln -s "$PWD/skills/askloop" .claude/skills/askloop          # one project
```

**Other agents:** put `skills/askloop` wherever your agent loads Agent Skills from.

## Usage

```
/askloop 4 move session handling out of the auth module   # new set, 4 open at a time
/askloop move session handling out of the auth module     # new set, 3 at a time
/askloop 5                                                # change N, or switch the current conversation to askloop mode
/askloop resume auth-refactor                             # continue an unfinished set
```

You can also just say "ask me 4 at a time" or "batch your questions".

## License

MIT
