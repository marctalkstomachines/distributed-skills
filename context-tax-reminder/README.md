# context-tax-reminder

A Claude Code hook that watches how heavy your session has gotten and tells the agent to
recommend `/clear` when your prompt opens a new topic.

The problem: a long session quietly gets expensive. Every turn re-sends the whole
conversation, so past a certain depth each exchange costs many fresh sessions' worth of
tokens just to carry the old context. And the moment your topic changes, all of that old
context is tax with no value — you're paying to haul around a conversation that no longer
helps.

Nobody remembers to clear at the right moment. So hand the rule to the machine.

## What it actually does

Two separate outputs, and the split is the part worth stealing:

| Channel | Goes to | When |
|---|---|---|
| `systemMessage` | **your terminal** | every prompt — the token count and the band |
| `additionalContext` | **the model's context** | only at 100k+, so a rule about frugality doesn't itself cost tokens every turn |

Claude Code already ships a footer hint that suggests `/clear` with a token figure. That
one talks to **you**. This one talks to the **agent** — so the agent can look at the prompt
you just typed, notice it opens a subject the conversation above doesn't serve, and say so.
A tool can see the number. Only the model can see the topic change.

## The bands

```
under 100k    normal working depth. Leave it alone — clearing here costs more than it saves.
100k – 200k   clear at the next natural stopping point.
over 200k     the model leans on its own summaries instead of your actual files.
              Finish the thought you're in, then clear.
```

**These are one person's working numbers on a 1-million-token window. No published spec
backs them.** They're the two constants at the top of the script — retune them for how you
actually work. They're absolute token counts, not fractions, so they hold whatever your
window is.

## Install

**1.** Put `context-tax-reminder.ps1` anywhere. `~/.claude/hooks/` is the tidy choice.

**2.** Register it as a `UserPromptSubmit` hook in `~/.claude/settings.json`. If you have no
`hooks` block yet, paste the whole of `settings-snippet.json`. If you already have one, add
just the inner object to your existing `UserPromptSubmit` array. Fix the path to match
where you put the file.

**3.** Set `"model"` in the same `settings.json`, at the top level:

```json
"model": "claude-opus-5[1m]"
```

Skip this and the hook still works — it just shows a raw token count with no percentage,
because it refuses to guess your window size. Set it and you get `142.0k / 1.0M (14%)`.

**4.** Start a new session. From your second prompt on, you'll see this **directly under the
prompt you just typed** — not at the top of the reply:

```
>> Context: 160.8k / 1.0M (16%) - clear at the next natural stopping point
```

It renders dim and scrolls past quickly, which is why it leads with a marker. **That marker is
deliberately ASCII.** A unicode flag was tried first and arrived in the transcript as a literal
`?` — Claude Code runs the hook through `powershell.exe`, whose stdout encoding falls back to
the console codepage. If you swap it for something prettier, verify it in your own transcript
rather than in a terminal; those are two different encodings.

(The first prompt after a `/clear` is silent — there's no usage record to read yet. That's by
design, not a failure.)

## Requirements

- **Windows:** works as-is, `powershell.exe` is already there.
- **macOS / Linux:** you need PowerShell 7 installed, and the command becomes `pwsh` instead
  of `powershell.exe`. The script itself handles the path difference.
  **This has not been tested on macOS or Linux** — the non-Windows code path was exercised
  on Windows by unsetting `USERPROFILE`, which is not the same thing as a real run.

## How it gets the number

The newest assistant record's `usage` block in the session transcript —
`input + cache_creation + cache_read + output`, which is what was actually resident on the
last API call. If it can't read that, it stays silent rather than estimating.

The window size is resolved the same way: from your configured model, never inferred from
the size of the number. If the live model and the configured one disagree, it drops the
percentage and tells you why instead of showing you a made-up denominator. If you switch
models mid-session it says so once, at the switch.

Token counts round **down**, always. 99,999 must not render as `100.0k` — that would read
as the next band.

## Things worth knowing

- **It never clears anything.** It has no such power. It puts a number in front of you and
  a suggestion in front of the agent. You type `/clear`.
- **Mid-burst it should stay quiet.** The instruction sent to the model says so explicitly:
  a topic change means recommend it now, a finished task means recommend it at the
  boundary, mid-thought means say nothing. Clearing mid-thought is the most expensive
  moment there is.
- **It writes one small state file per session** (next to the script, in `state/`) to detect
  model changes. Files older than 14 days clean themselves up.
- **5-second timeout.** It reads only the last 1MB of the transcript, because real
  transcripts run to tens of megabytes and a full parse would blow the budget.

The hook reads the current session transcript, reads your configured model name, writes a small
per-session marker under its adjacent `state/` folder, and returns structured hook output. It
does not modify the transcript, change models, or clear the session.

## If nothing appears

Check, in order: the path in `settings.json` points at the real file · you started a **new**
session after editing settings · you're past your first prompt. Then run it by hand:

```powershell
'{"transcript_path":"<path to a .jsonl transcript>","session_id":"test"}' |
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File context-tax-reminder.ps1
```

It should print one line of JSON. If it prints nothing, it couldn't find a `usage` block in
that transcript — which is the designed behavior, not a crash.

## Uninstall

Remove the matching `UserPromptSubmit` hook object from `~/.claude/settings.json`, then delete
`context-tax-reminder.ps1` and its adjacent `state/` folder. Do not delete your entire hooks
array or settings file; other tools may share them.
