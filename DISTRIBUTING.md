# Distribution guide

Use this guide whenever an agent creates something intended for this repository. The goal is
not merely to publish files. A new user must be able to identify the artifact, install only what
they need, run it successfully, understand its limits, and remove it again.

## 1. Classify the artifact first

Record exactly one primary type before creating files:

| Type | Required payload | Typical destination | Installation model |
|---|---|---|---|
| Skill | A folder containing `SKILL.md` and every required support file | Claude: `~/.claude/skills/<name>/`; Codex: `~/.codex/skills/<name>/` | Install the complete folder. |
| Agent | One Markdown file with valid agent frontmatter | Claude: `~/.claude/agents/<name>.md` or `<project>/.claude/agents/` | Install the file. |
| Hook | Executable script plus a merge-safe settings snippet | Usually `~/.claude/hooks/` plus `~/.claude/settings.json` | Copy the script; merge settings without replacing existing configuration. |
| Utility | Runnable scripts and supporting documents | Any user-chosen folder | Download and run; do not call this an installed skill. |

If an artifact mixes types, split it into separately installable folders unless the pieces cannot
work independently. Never label a hook or utility as a skill; the type table above is the authority.

## 2. Package one complete folder

Create a lowercase, hyphenated top-level folder. It must contain:

- `README.md`, written for someone who has never seen the video.
- The complete runnable or installable payload.
- Starter files required for the first successful run.
- No credentials, personal paths, transcripts, generated output, logs, caches, or private data.

A skill must keep `SKILL.md` at the artifact-folder root. An agent's filename should match its
frontmatter `name`. A hook must include a settings example that tells users to merge rather than
overwrite. A utility must state whether it writes files and where they appear.

## 3. Write the artifact README

Keep the first successful path near the top. Use these sections, in this order:

1. **What it is** — one sentence and the problem it solves.
2. **Requirements** — client, operating system, shell, runtime, and actual dependencies.
3. **Install** — numbered steps with exact source and destination paths.
4. **Use** — one copy-ready example and the expected result.
5. **What it changes** — files read, written, moved, or settings modified.
6. **Safety and limits** — destructive boundaries, unsupported platforms, and untested claims.
7. **Troubleshooting** — the first three checks when nothing happens.
8. **Uninstall** — exact files or settings entries to remove.

Do not say "no dependencies" when the artifact depends on Claude Code, Codex, PowerShell, an
operating system API, or another runtime. Prefer: "No additional packages; requirements are …"

## 4. Provide the shortest honest install route

- Link the whole-repository ZIP:
  `https://github.com/marctalkstomachines/workbench/archive/refs/heads/main.zip`.
- For a single-file artifact, link its GitHub page so the user can choose **Download raw file**.
- For a Codex-compatible skill, include a paste-ready request using the exact GitHub tree URL.
- For Claude Code, state the exact manual destination. Do not promise a one-click installer that
  the repository does not provide.
- If installation requires editing shared settings, say **merge** and show the smallest object;
  never tell users to replace their complete settings file.

## 5. Make claims testable

Every distributed artifact needs a repeatable check:

- Skills and agents: validate required frontmatter and required companion files.
- Hooks: feed a fixture payload through the real script and validate its structured output.
- Utilities: run the real entry point in a temporary directory and assert expected artifacts and
  exit codes.
- Documentation: verify every root-table link and every named local file exists.

Add the check to `scripts/validate-distribution.ps1`. The GitHub workflow must run it on every
push and pull request. Platform-specific code must run on the platform it claims to support.

Report evidence as commands and results. "Looks correct" is not verification. If a platform was
not exercised, label it untested in the artifact README.

## 6. Update the repository entry point

Add one row to both root tables in `README.md`:

- Artifact name and relative link.
- Honest type.
- Supported client/platform.
- Shortest installation route.
- Source video title.

The root page must let a visitor choose and install an artifact without reading unrelated folders.

## 7. Pre-publication checklist

- [ ] Artifact type is correct and not marketing shorthand.
- [ ] Folder is self-contained and named consistently.
- [ ] README contains requirements, install, use, effects, limits, troubleshooting, and uninstall.
- [ ] Installation was exercised from a clean downloaded copy, not the author's working folder.
- [ ] All commands and paths are copy-ready and use placeholders rather than personal paths.
- [ ] No secrets, logs, generated output, absolute local paths, or private material are present.
- [ ] Unsupported and untested platforms are labeled.
- [ ] Root README tables and download routes are updated.
- [ ] `pwsh -NoProfile -File scripts/validate-distribution.ps1` passes locally.
- [ ] Pull-request CI is green before merge.
- [ ] The MIT License is compatible with every included file; third-party material is attributed.

## 8. Handoff contract for the next agent

When handing a proposed distribution to another agent, include:

```text
Artifact: <name>
Type: <skill | agent | hook | utility>
Audience/client: <who runs it and where>
Supported platforms: <tested platforms>
Install source -> destination: <exact mapping>
Files read/written: <explicit list or pattern>
Clean-install test: <command and observed result>
Known limits: <unsupported or unverified behavior>
Root README updated: <yes/no>
Validation script updated: <yes/no>
License/provenance checked: <yes/no>
```

Missing evidence is a reason to pause publication, not a field to infer.
