# repo-scout

The agent file from the video — a read-only reconnaissance scout for exactly one
repository. You spawn several in parallel, one per repo, and each reports back a condensed
brief with every claim citing a file path. They inspect; they never modify.

**This one is an agent, not a skill** — it's a role Claude Code can delegate to, and it
installs to a different folder than skills do.

## Requirements

- Claude Code with subagents available.
- Read access to the repository being surveyed.
- No additional packages.

## Install

Hand it to your agent. Paste this:

```text
Install this for me: https://github.com/marctalkstomachines/workbench/tree/main/repo-scout

Read the README there, then set it up on this machine: put the agent file where
my agent will find it, for all my projects rather than just this one.

Then spawn one against a repository here and show me the brief it comes back with.

When you're done, tell me what you changed and what you left alone.
```

That's the install. Everything below is what your agent reads to do it — and what
you'd follow to do it yourself.

### By hand

1. Download this repo: green **Code** button → **Download ZIP** → unzip.
2. Copy `repo-scout.md` into your agents folder:
   - everywhere: `C:\Users\<you>\.claude\agents\` (Windows) or `~/.claude/agents/` (Mac/Linux)
   - or just one project: `<project>\.claude\agents\`

That's the whole install. Rename it, rewrite it — it's yours.

## Use

Ask for it by name when the job splits into pieces that don't need to see each other:

```
Survey these five repos. Spawn one repo-scout per repo, in parallel,
and give me the five briefs.
```

**When it helps:** many repos (roughly 4+, or one unusually dense one), and the question
breaks into independent per-repo pieces — a census, an inventory, a freshness audit.

**When NOT to fan out:** when the question is about how the repos *relate* — what's
redundant, what supersedes what, what's secretly the same project. Each scout sees only its
own repo, so cross-repo conclusions were invisible to every scout. The file's own
orchestrator contract covers this: scout briefs are testimony, not proof — verify any
cross-repo claim against primary evidence before acting on it.

## If Claude cannot find it

Check that the file ends in `.md`, lives directly inside the global or project-level
`.claude/agents/` folder, and retains the YAML frontmatter at the top. Start a new Claude Code
session after installing it. The agent reads repositories but does not write files or state.

## Uninstall

Delete `repo-scout.md` from the global or project-level `.claude/agents/` folder where you
installed it. It creates no state and changes no repository files.
