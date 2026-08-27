# workbench

Tools I hand out in my videos — [Marc Talks to Machines](https://www.youtube.com/@marctalkstomachines).

Each folder contains one self-contained artifact: a skill, agent, hook, or runnable utility.
There is no package manager or universal installer because each artifact belongs in a different
place.

**Hand the folder to your agent and let it do the install.** Every artifact's README opens with
the exact text to paste — it points your agent at that folder, tells it to fit the thing to your
machine rather than to the paths in the README, and to report back what it changed. Doing it by
hand works too; the steps are in the same README.

## Pick one

| Artifact | Type | Works with | Where it goes |
|---|---|---|---|
| [`organize-batch`](organize-batch/) | Skill | Claude Code; Codex-compatible | `~/.claude/skills/` (Claude) or `~/.codex/skills/` (Codex) |
| [`repo-scout`](repo-scout/) | Agent | Claude Code | `~/.claude/agents/` |
| [`context-tax-reminder`](context-tax-reminder/) | Hook | Claude Code | `~/.claude/hooks/`, plus a merged entry in `settings.json` |
| [`blind-test-protocol`](blind-test-protocol/) | Windows utility | PowerShell 5.1 | anywhere — nothing is installed |

Windows uses `C:\Users\<you>\` wherever the table shows `~/`.

## If you’d rather do it by hand

- **Everything:** [Download the repository as a ZIP](https://github.com/marctalkstomachines/workbench/archive/refs/heads/main.zip), unzip it, then keep only the artifact you want.
- **One file:** open the artifact folder, select the file, and use GitHub's **Download raw file** button.

The individual READMEs contain exact destinations, setup steps, platform requirements, use
examples, safety limits, and troubleshooting. Some artifacts require Claude Code or PowerShell;
there are no additional package dependencies unless that artifact's README says otherwise.

## From the videos

| Artifact | Video |
|---|---|
| `organize-batch` | *3 Levels of Claude for People Who Don't Write Code* |
| `repo-scout` | *Everyone's Copying Fable's Agent Trick. Mine Just Lost a Race.* |
| `context-tax-reminder` | *You Just Installed 10 Claude Skills. I Wrote One Rule.* |
| `blind-test-protocol` | *You Just Installed 10 Claude Skills. I Wrote One Rule.* |

Want to add another artifact? Follow [the distribution guide](DISTRIBUTING.md). Everything in
this repository is available under the [MIT License](LICENSE).
