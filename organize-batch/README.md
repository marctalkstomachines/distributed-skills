# organize-batch

The folder-organization skill from the video, as one repeatable job for Claude Code.
It surveys the folder, proposes every move and rename, **waits for your approval**, executes
only what you approved, and leaves a record you can check: every move listed, files in =
files out.

**Point it at a copy first.** Not your home folder, not the only copy you care about. Once
you've watched it behave, run it on the real thing.

## What's in this folder

| File | What it is | Where it goes |
|---|---|---|
| `SKILL.md` | the skill itself | stays in the skill folder |
| `brief.md` | the job's contract — the five sentences | **into the folder you're organizing** |
| `conventions.md` | rules the job earns from your corrections | **into the folder you're organizing** |

## Install (once)

1. You need Claude Code. Setup is one pasted line + one login:
   https://code.claude.com/docs/en/quickstart
2. Download this repo: green **Code** button → **Download ZIP** → unzip.
3. Copy the whole `organize-batch` folder into your skills folder:
   - Windows: `C:\Users\<you>\.claude\skills\`
   - Mac/Linux: `~/.claude/skills/`

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
