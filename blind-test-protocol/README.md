# blind-test-protocol

Two small PowerShell scripts for finding out whether an AI can actually read your data —
instead of taking a benchmark's word for it.

It answers a specific question: **when text is packed densely into an image, at what point
does the model start getting characters wrong, and does it tell you when it does?** The
method underneath generalizes well past images — see [PROTOCOL.md](PROTOCOL.md).

## Why you'd bother

Because the dangerous failure isn't the one that errors. It's the one that comes back
confident and slightly wrong — a hex ID with one character swapped, a checksum a character
short — in the same tone as every value it got right. A benchmark score can't show you that.
A blind test can.

## The files

| File | What it does |
|---|---|
| `render-dense.ps1` | Draws a page of realistic-looking text to two PNGs at two densities. The 15 exact values are **randomized at render time** and written only to a truth file. |
| `compare-truth.ps1` | Diffs what the model read against what was actually drawn. Exact, case-sensitive, exit code = number of misses. |
| `PROTOCOL.md` | The method, the steps, and how to read the result. **Read this one.** |

## Run it

Hand it to your agent. Paste this:

```text
Run this for me on my own material: https://github.com/marctalkstomachines/workbench/tree/main/blind-test-protocol

Read PROTOCOL.md there, then set it up on this machine and run it: render the
pages, hand the images to the tool I'm evaluating, and diff what it reads back
against the truth file. Don't show it the truth file, and don't show me the
values before the diff.

Then show me the misses, and tell me which ones the tool warned me about and
which ones it got wrong silently.
```

That's the run. Everything below is what your agent reads to do it — and what you'd
follow to do it yourself.

### By hand

```powershell
.\render-dense.ps1
```

Output lands in a new timestamped folder under `runs\`:

```
runs\2026-08-19-2231\
  dense-A-12px.png    ← comfortable density
  dense-B-8px.png     ← packed
  truth-A.txt         ← do not open until after the test
  truth-B.txt
```

It also prints the measurements for each image — characters drawn, image tokens, and the
resulting density versus plain text — so you can see what you're actually trading.

Hand a PNG to the AI, ask for the exact values, save its answer as `KEY=VALUE` lines, then:

```powershell
.\compare-truth.ps1 -Truth runs\2026-08-19-2231\truth-A.txt -Read runs\2026-08-19-2231\transcription-A.txt
```

```
15/15 exact. Clean read.
```

or

```
Field    Truth            Read             Status
-----    -----            ----             ------
CHECKSUM 061a803f820860e0 061a803f820860e  WRONG
ID-02    46747de2c118     46747de2c110     WRONG

13/15 exact. 2 wrong or missing.
```

Add `-All` to print every field, not just the misses.

## Requirements

- **Windows.** `render-dense.ps1` draws via `System.Drawing`, which is a Windows GDI+ binding.
  It is not portable, and there is no cross-platform fallback in this bundle.
- Run it with `powershell.exe` (Windows PowerShell 5.1), which is what's already on the
  machine. **Not tested under PowerShell 7**, where `System.Drawing.Common` behaves
  differently.
- `compare-truth.ps1` has no such dependency and will run anywhere PowerShell does.

There are no additional packages to install on supported Windows systems.

## Things worth knowing

- **Every run is different.** The values are re-randomized, so you can run it as many times
  as you like and it stays a genuine blind test. Convenient if you're recording.
- **Nothing is overwritten.** Each run gets its own timestamped folder, so earlier evidence
  survives.
- **One image per conversation.** If you paste both into the same chat, the second read can
  lean on the first and you've lost the isolation.
- **The filler text is cosmetic.** It's generated nonsense shaped like work logs. Swap the
  project names at the top of the render script for your own if you want the page to look
  like your material — it changes nothing about the test.
- **The comparison is exact and case-sensitive.** One character off is wrong. That's
  deliberate: the whole failure mode being hunted is the near-miss that looks fine.

## What this tests, and what it doesn't

It reproduces a **mechanism and its failure mode** on your machine, with your run, at
densities you choose.

It says nothing about any particular vendor's implementation — their proxy code, their
caching, their published benchmarks. Those need auditing separately, and if you haven't
audited them, quote them as claims rather than repeating them as findings.

## Remove it

Delete the downloaded `blind-test-protocol` folder when you no longer need it. Test evidence is
stored only in its `runs/` subfolder, so copy out any runs you want to retain first.
