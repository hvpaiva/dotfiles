---
name: argo-pause-work
description: Pause the active work item safely. Produces the pause-delta file on disk (conforming to argo-internal/work-item-pause.yaml DRD) and transitions the work item to paused. Required before /clear when active_work_item is in_progress.
---

# Argo Pause Work

Use this skill when the session ends before the active work item can close,
and you want to preserve the minimum context for the next session to resume
without reading the full conversation.

**This skill is the antidote to the 2026-04-17 bug** — recommending `/clear`
without persisting session-level synthesis. The pause-delta file is the
session contract's off-ramp: small, structured, contains exactly what the
next session needs and no more.

## Preconditions

Reject the request (do not produce the delta) if any of these holds:

- `argo-state get active_work_item.id` returns null or empty — nothing to pause.
- The work item referenced by `active_work_item.id` has status != `in_progress`.

Run:
- `$ARGO_HOME/scripts/argo-state get active_work_item.id`
- `$ARGO_HOME/scripts/argo-state get work_items[id=<awi>]`

Reprint the results in your assistant response.

## Steps

### 1. Gather the delta (Socratic)

Ask the human these five questions, one at a time, in pt-BR. Do **not**
invent answers. The whole point is to force the human to say what the
session contains that is about to be lost.

- O que você estava fazendo nesse work item? (1 parágrafo, ≤ 5 frases)
- O que ainda falta? (lista flat, 1 linha cada)
- Qual é a próxima ação concreta do próximo agente? (1 frase)
- Tem alguma pergunta travando você pro humano responder? (opcional, 1 linha cada)

If the human says "preenche você" ou equivalente, **recuse**. The skill
needs the human's synthesis, not yours.

### 2. Write the delta file

Path: `.argo/work-items/<work-item-id>-pause.md`

Conform strictly to `.argo/schemas/argo-internal/work-item-pause.yaml`.
Required fields, in order:

```markdown
---
work_item_id: <id>
paused_at: <ISO-8601 now>
paused_by: <human name or session id>
schema: .argo/schemas/argo-internal/work-item-pause.yaml
---

# Pause delta — <work-item-id>

## What was being done

<one paragraph, ≤ 5 sentences, present tense>

## What remains

- <item 1>
- <item 2>
- ...

## Next concrete action

<one sentence — must name a file to read, a command to run, or a question to ask>

## Open questions for human

<optional list; omit section if empty>
- <question 1>
```

**Length budget**: ≤ 30 lines total. If it exceeds, the work item was too
large; flag that to the human, suggest cancelling and decomposing, and do
not proceed to step 3.

### 3. Call argo-state pause-work-item

Run via Bash:

```
$ARGO_HOME/scripts/argo-state pause-work-item <work-item-id> \
  --pause-delta .argo/work-items/<work-item-id>-pause.md \
  --hint "<one-line resume hint>" \
  --paused-by "<human-or-session>"
```

The script verifies the delta file exists on disk before mutating. If the
file is missing, it exits non-zero — fix and retry.

### 4. Confirm state

Run:
- `$ARGO_HOME/scripts/argo-state validate`
- `$ARGO_HOME/scripts/argo-state get active_work_item`
- `$ARGO_HOME/scripts/argo-state get 'work_items[id=<awi>].status'`

Reprint. Expected: `validate = OK`, `active_work_item.id` still set (the
pointer remains until resume or cancel), `status = paused`.

### 5. Closing message

```
Work item <id> pausado.
Delta persistido em .argo/work-items/<id>-pause.md (<N> linhas).
/clear agora é seguro — o Stop hook aceita, e na próxima sessão
/argo-resume-work <id> retoma daqui.
```

## Rules

- Do not paraphrase the human's answers when writing the delta. Copy their
  words; you're a transcriber, not an editor.
- Do not write the delta if the human refuses any of the three required
  fields (was/remaining/next-action). That is a signal the work item isn't
  pausable — either it should close, or the human needs a break, not the
  framework.
- Never auto-fill "what was being done" from conversation memory. The
  conversation memory is exactly what's about to be destroyed; trusting it
  reintroduces the bug.
- Language with the human: pt-BR. The pause-delta file itself: English
  (consistent with all docs/ and .argo/ content per CLAUDE.md).
