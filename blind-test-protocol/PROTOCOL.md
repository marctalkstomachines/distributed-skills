# The blind test

A hyped tool arrives with a claim. The claim is usually true *somewhere*. The only question
that matters is whether it's true **on your material, in your setup, at the settings you'd
actually use** — and no benchmark answers that, because no benchmark ran on your files.

Fifteen minutes of protocol beats a week of vibes. Here's the protocol.

---

## The one rule that makes it a test

**Generate ground truth that nobody has seen — not you, not the model — and check against
it afterward.**

That's the whole discipline. Everything else is bookkeeping.

If you know the answers before you ask, you'll read the model's output charitably. If the
model has seen the answers, it isn't reading, it's recalling. Randomizing the values at
generation time and writing them to a file you don't open until after removes both problems
at once. What comes back either matches or it doesn't, and no amount of interpretation moves
the number.

**This generalizes past images.** Anywhere you want to know whether an AI can genuinely
recover information from a representation — a compressed transcript, a summarized document,
a vector search, an OCR pass, a "lossless" export — the same shape applies: generate
randomized facts, hide them in the representation, ask for them back, diff. The tool in this
folder happens to test image-rendered text, because that was the claim in front of me.

---

## The steps

**1. Render the test material.**

```powershell
.\render-dense.ps1
```

Two PNGs land in a new timestamped folder under `runs\`, along with `truth-A.txt` and
`truth-B.txt`. Both images carry the same canvas size and the same 15 exact values in kind —
a snapshot ID, a date, a count, a dollar figure, a 16-character checksum, and ten 12-character
hex IDs. **A is drawn at a comfortable density. B is drawn small enough to be interesting.**

**Do not open the truth files.** That is not a formality — the entire result depends on it.

**2. Hand the image to the AI and ask for the values back.**

One image per conversation, so the second read can't lean on the first. Ask for exact
transcription of the exact-value block plus the header and footer fields. Ask it to flag
anything it isn't confident about — you will want that later, and it's the most informative
thing in the whole test.

**3. Save what it gave you**, as plain `KEY=VALUE` lines, one per line, in the same folder:

```
SNAPSHOT-ID=7794707b9443
DATE=2026-09-14
...
ID-10=91cbe38efbdd
```

**4. Now diff.**

```powershell
.\compare-truth.ps1 -Truth runs\<stamp>\truth-A.txt -Read runs\<stamp>\transcription-A.txt
```

**5. Repeat for B**, at the higher density.

---

## Reading the result — the part people get wrong

**The score is not the finding.** A number like 11/15 tells you the tool has a failure rate.
That's the boring half.

**The finding is whether the failures announced themselves.** Go back to step 2 and check
which misses the model warned you about. A wrong value it flagged as low-confidence is a
*limitation* — you can build around a limitation, route past it, add a verification step. A
wrong value it handed you plainly, in the same tone as the fourteen correct ones, is a
**trap**, and the only defense is not trusting the surface for that job at all.

`compare-truth.ps1` prints this reminder every time it finds a miss, because it's the
question that decides what you do next and it's the one that gets skipped.

**Then map it onto how you actually pay.** A tool that trades accuracy for token cost is a
different proposition depending on your billing: per-token, the savings are real and a bad
read is a rounding error. On a subscription, the savings mostly stretch plan limits — and a
single silently-wrong value that propagates through an agent run can cost you more than the
tokens ever saved. Same tool, opposite verdict, and nothing about the benchmark told you
which one you were.

---

## What a result does and doesn't license

- It licenses a claim about **the thing you tested, at the density you tested, on the kind of
  material you rendered.**
- It does not license a claim about the tool's source code, its caching behavior, its
  benchmark numbers, or how it performs on anything you didn't run.

If you want to say something about those, audit those. Otherwise quote the vendor and say
you're quoting them.

**And a tool you decide against is still a result.** Understanding what something is for is
worth the fifteen minutes even when the answer is "not for this." The point was never to find
a winner — it's to know what you're holding before you let it into your system.
