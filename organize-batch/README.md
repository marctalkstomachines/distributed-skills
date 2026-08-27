# organize-batch

The folder-organization skill from the video, as one repeatable job for Claude Code.
It surveys the folder, proposes every move and rename, **waits for your approval**, executes
only what you approved, and leaves a record you can check: every move listed, files in =
files out.

**Point it at a copy first.** Not your home folder, not the only copy you care about. Once
you've watched it behave, run it on the real thing.

## Requirements

- Claude Code, or Codex with GitHub skill installation available.
- Permission for the selected agent to read and move files inside the target folder.
- No additional packages.

## What's in this folder

| File | What it is | Where it goes |
|---|---|---|
| `SKILL.md` | the skill itself | stays in the skill folder |
| `brief.md` | the job's contract — the five sentences | **into the folder you're organizing** |
| `conventions.md` | rules the job earns from your corrections | **into the folder you're organizing** |

## Install

Hand it to your agent. Paste this:

```text
Install this for me: https://github.com/marctalkstomachines/workbench/tree/main/organize-batch

Read the README there, then set it up on this machine: put the skill where my
agent will find it, and copy the brief and the conventions file into the folder
I want organized. Ask me about that folder and fill the brief in from my answers.

Point it at a copy of the folder first, not the original. Run the survey and
show me the proposal before anything moves.

When you're done, tell me what you changed and what you left alone.
```

That's the install. Everything below is what your agent reads to do it — and what
you'd follow to do it yourself.

### By hand

1. You need Claude Code. Setup is one pasted line + one login:
   https://code.claude.com/docs/en/quickstart
2. Download this repo: green **Code** button → **Download ZIP** → unzip.
3. Copy the whole `organize-batch` folder into your skills folder:
   - Windows: `C:\Users\<you>\.claude\skills\`
   - Mac/Linux: `~/.claude/skills/`

**Using Codex instead?** Ask Codex:

```text
Install the skill from https://github.com/marctalkstomachines/workbench/tree/main/organize-batch
```

Codex installs it into `~/.codex/skills/organize-batch/`. Its invocation interface may differ
from Claude Code's slash command, but the skill contract and supporting files are portable.

## Set up a job (once per folder)

Copy `brief.md` and `conventions.md` **out of the skill folder and into the folder you want
organized.** They're the job's memory, and they live beside the work — that's what lets the
next run pick up where this one left off without you re-explaining anything.

Then open `brief.md` and make sentence two yours: the folder names, what "finished" means
for this particular mess. Leave `conventions.md` alone — it fills itself over time (it
explains how).

## Run

Open a terminal, start Claude Code, and type:

```
/organize-batch <path to the folder>
```

It reads the brief, the conventions, and the index. It proposes. **It waits.** You approve —
or reject a specific item, and it leaves that one alone. It executes, verifies, and appends
the run to `ORGANIZE_INDEX.md` in the folder.

## When it refuses

If `brief.md` or `conventions.md` is missing from the target folder, it stops and says so
instead of improvising. That's the design: no contract, no run.

If the command is not recognized, check that the installed path ends in
`skills/organize-batch/SKILL.md`, then start a new agent session. If it reports a missing brief
or conventions file, copy both starter files into the folder being organized—not beside it.

## Uninstall

Delete only the installed `organize-batch` skill folder. The `brief.md`, `conventions.md`, and
`ORGANIZE_INDEX.md` files inside folders you organized are job records; keep or delete those
separately according to your own retention needs.
