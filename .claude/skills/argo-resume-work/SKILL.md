---
name: argo-resume-work
description: Resume a paused work item. Reads the pause-delta file, restores the session's minimum context (just what the work item declared as inputs, not full state), and transitions the work item back to in_progress.
---

# Argo Resume Work

Use this skill to continue a work item that was previously paused via
`/argo-pause-work`. The skill loads exactly the inputs the work item declared
and the pause-delta — nothing else. You do **not** read the full state, the
full research index, or prior-phase history unless explicitly needed.

Loading less is a feature: the work item is the session contract; it defines
what this session needs to know.

## Preconditions

Refuse the request if any of these holds:

- No `work_item_id` argument was passed.
- The referenced work item has status != `paused`.
- Its `pause.pause_delta_path` is missing on disk.
- Another work item is already in status `in_progress` (exactly one
  `in_progress` allowed per state.yaml invariant).

Run:
- `$ARGO_HOME/scripts/argo-state get 'work_items[id=<id>]'`

Reprint.

## Steps

### 1. Read the pause-delta

Path is `work_items[id=<id>].pause.pause_delta_path`.

Read the full file. It conforms to
`.argo/schemas/argo-internal/work-item-pause.yaml`, so it has at most
~30 lines with five sections (front matter + what-was-being-done + what-remains
+ next-concrete-action + optional open-questions-for-human).

**Reprint the delta in your assistant response** so the human sees the
resume context.

### 2. Read declared inputs (on demand)

Look at `work_items[id=<id>].inputs`. For each input of `kind: file`, read
it (up to 500 lines — if bigger, read only the sections the delta named or
ask the human which part matters). For `kind: state-subset`, use
`argo-state get <path>`. For `kind: reference`, note it; only fetch if the
next-concrete-action requires it.

Do **not** pre-emptively read other dossiers, other artifacts, or other
work items. On-demand loading is the contract.

### 3. Resume via argo-state

Run via Bash:

```
$ARGO_HOME/scripts/argo-state resume-work-item <work-item-id> \
  --resumed-by "<human-or-session>"
```

This transitions `status: paused → in_progress`, clears the `pause` block,
appends a `resumed` entry to `session_refs`, and sets `active_work_item.id`
to this item.

### 4. Confirm state

Run:
- `$ARGO_HOME/scripts/argo-state validate`
- `$ARGO_HOME/scripts/argo-state get 'work_items[id=<id>].status'`

Reprint. Expected: `validate = OK`, `status = in_progress`.

### 5. Act on the next concrete action

Follow the `## Next concrete action` section of the pause-delta verbatim.
If it names a file, read it. If it names a command, run it. If it names a
question, ask the human.

If `## Open questions for human` has entries, surface them **before** doing
the next concrete action — the human must answer before the action is safe.

### 6. Closing message (only after the first substantive step)

After executing the next-concrete-action (or, if it was "ask human a
question", after receiving the answer), print:

```
Resumed <work-item-id>.
Status: in_progress. Next: <what you did / what's now pending>.

Para pausar de novo: /argo-pause-work
Para fechar: argo-state close-work-item <id>  (roda os checks e valida)
```

## Rules

- On-demand context loading. Do not warm up with dossiers the work item
  did not declare as inputs. If you think you need more, ask the human;
  never speculatively load.
- Do not invent what was being done. The pause-delta is the source; if it's
  unclear, ask the human rather than guessing.
- Language with the human: pt-BR. The pause-delta file content stays verbatim.
- Do not skip the validate step — a resume that leaves the state
  inconsistent is worse than an unresumed work item.
