---
name: organize-batch
description: Run the standing folder-organization job on a new batch. Reads the brief, conventions, and index that live beside the folder, proposes before touching anything, executes only on approval, leaves a verifiable record. Invoke as /organize-batch <folder>.
---

# organize-batch

Run the standing organization job on the folder given as the argument. The job's memory
lives beside the work — read it before doing anything:

1. `brief.md` in the target folder — the five-decision brief. It is the contract.
2. `conventions.md` in the target folder — rules this job has earned from past corrections.
   They override your own classification instincts.
3. `ORGANIZE_INDEX.md` in the target folder — the record of prior runs. Append to it; never
   rewrite it.

## The five decisions (from brief.md — restated here as the operating floor)

1. **Bound the input:** use only the target folder. Nothing outside it is readable context
   for this job; nothing inside it leaves.
2. **Define finished:** every loose file and folder is filed into the standing category
   folders per conventions.md. Keep filenames that already make sense; rename only
   meaningless ones (`download(3).pdf` → `YYYY-MM-DD_short-description.ext`, date from the
   file's own timestamp).
3. **Protect the boundary:** delete nothing, overwrite nothing, guess at nothing. Anything
   ambiguous goes to `Unsorted`. Exact duplicates are kept side by side, never pruned.
4. **Review before action:** show the full proposed move/rename list and WAIT for explicit
   approval. No file moves before the approval message.
5. **Leave a record:** after execution, append a dated run section to `ORGANIZE_INDEX.md` —
   every move, every rename, every file left untouched — and reconcile the count:
   **files in = files out** (plus any record files this run created). State the
   reconciliation explicitly in the final report.

## Hard rules

- If `brief.md` or `conventions.md` is missing, stop and say so. Do not improvise the
  contract.
- If a security hook blocks an action, stop immediately, name the rule, and end the turn.
- Pre-existing folders are part of the job (conventions.md carries the earned rule).
- One proposal, one approval, one execution. If the operator rejects a specific item,
  leave that item alone and apply the rest.
