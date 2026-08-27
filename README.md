# distributed-skills

Tools I hand out in my videos — [Marc Talks to Machines](https://www.youtube.com/@marctalkstomachines).

Each folder contains one self-contained artifact: a skill, agent, hook, or runnable utility.
There is no package manager or universal installer because each artifact belongs in a different
place. Choose one item below and follow its short README.

## Pick one

| Artifact | Type | Works with | Fastest installation |
|---|---|---|---|
| [`organize-batch`](organize-batch/) | Skill | Claude Code; Codex-compatible | Claude: copy the folder to `~/.claude/skills/`. Codex: ask Codex to install the linked GitHub folder. |
| [`repo-scout`](repo-scout/) | Agent | Claude Code | Download `repo-scout.md` into `~/.claude/agents/`. |
| [`context-tax-reminder`](context-tax-reminder/) | Hook | Claude Code | Download the script, then merge the supplied hook entry into `settings.json`. |
| [`blind-test-protocol`](blind-test-protocol/) | Windows utility | PowerShell 5.1 | Download the folder and run `render-dense.ps1`; nothing is installed. |

Windows uses `C:\Users\<you>\` wherever the table shows `~/`.

## Download

- **Everything:** [Download the repository as a ZIP](https://github.com/marctalkstomachines/distributed-skills/archive/refs/heads/main.zip), unzip it, then keep only the artifact you want.
- **One file:** open the artifact folder, select the file, and use GitHub's **Download raw file** button.
- **Codex skill:** paste this into Codex: `Install the skill from https://github.com/marctalkstomachines/distributed-skills/tree/main/organize-batch`

The individual READMEs contain exact destinations, setup steps, platform requirements, use
examples, safety limits, and troubleshooting. Some artifacts require Claude Code or PowerShell;
there are no additional package dependencies unless that artifact's README says otherwise.

## From the videos

| Artifact | Video |
|---|---|
| `organize-batch` | *3 Levels of Claude for People Who Don't Code* |
| `repo-scout` | *I Gave Fable ONE Job. It Hired 7 Agents Instead.* |
| `context-tax-reminder` | *You Just Installed 10 Claude Skills. I Wrote One Rule.* |
| `blind-test-protocol` | *You Just Installed 10 Claude Skills. I Wrote One Rule.* |

Want to add another artifact? Follow [the distribution guide](DISTRIBUTING.md). Everything in
this repository is available under the [MIT License](LICENSE).
