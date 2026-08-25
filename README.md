# distributed-skills

Tools I hand out in my videos — [Marc Talks to Machines](https://www.youtube.com/@marctalkstomachines).

Each folder is one self-contained thing — a skill, an agent, a hook, or a couple of scripts —
plus any starter files it needs to run. No installer, no dependencies. Open the folder's README
and follow it.

| Folder | From the video | What it is |
|---|---|---|
| [`organize-batch`](organize-batch/) | *3 Levels of Claude for People Who Don't Code* | Skill — the standing folder-organization job: proposes before touching anything, executes only on approval, leaves a verifiable record. |
| [`repo-scout`](repo-scout/) | *I Gave Fable ONE Job. It Hired 7 Agents Instead.* | Agent — a read-only scout for one repository; spawn several in parallel and each reports a brief where every claim cites a file path. |
| [`context-tax-reminder`](context-tax-reminder/) | *You Just Installed 10 Claude Skills. I Wrote One Rule.* | Hook — watches how heavy your session has gotten and tells the agent to recommend `/clear` when your prompt opens a new topic. |
| [`blind-test-protocol`](blind-test-protocol/) | *You Just Installed 10 Claude Skills. I Wrote One Rule.* | Scripts — run a hyped tool through a blind test on your own material before you adopt it: randomized ground truth, exact diff, no vibes. |

These live on your machine, not in a store. That's the point.
