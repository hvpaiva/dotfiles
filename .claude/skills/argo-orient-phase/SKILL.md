---
name: argo-orient-phase
description: Produce the orientation.md and program.md argo-internal deliverables for a phase. Runs the phase-orient and phase-program work items — the mandatory first sub-flow after entering or re-entering a phase. Gatekeeper for sf.<phase>.ensure-refs and everything downstream.
---

# Argo Orient Phase

This skill produces the two argo-internal deliverables that tell every
future session what the phase is doing:

- `.argo/phases/<phase-id>/orientation.md` — what this phase is inheriting,
  what was invalidated, what gaps must be closed, what the goals are.
- `.argo/phases/<phase-id>/program.md` — ordered sub-flow progression for
  this phase, with estimates and expected iterations.

Both files conform to schemas under `.argo/schemas/argo-internal/`.

Without these two files, no downstream work item (research, decide,
draft-<artifact>) has a declared context to load on demand. This is the
**first** thing you do when a phase starts or re-starts.

## Preconditions

- `$ARGO_HOME/scripts/argo-state get current_phase.id` returns a non-null phase.
- `$ARGO_HOME/scripts/argo-state get 'phase_plans.<phase-id>.active_sub_flow'`
  returns `sf.<phase-id>.orient` (the orient sub-flow must be the active
  sub-flow). If it is not, instruct the human to run
  `/argo-advance-sub-flow <phase-id> sf.<phase-id>.orient` first.
- No other work item is `in_progress`.

## Steps

### 1. Open the phase-orient work item

```
$ARGO_HOME/scripts/argo-state open-work-item \
  wi.phase-<phase>.orient \
  --type phase-orient \
  --sub-flow sf.phase-<phase>.orient \
  --target-kind phase-orient \
  --target-ref <phase-id> \
  --opened-by <session>
```

Populate `closes_when`, `inputs`, `outputs` with a small Python snippet
(similar pattern to U4 retroactive impact registration — see
`.argo/work-items/wi.phase-0.impact.mission-redefinition-2026-04-17.md`
for reference).

Minimum `closes_when`:
- `file_exists` → `.argo/phases/<phase-id>/orientation.md`

### 2. Gather context

Read:
- `$ARGO_HOME/scripts/argo-state view` — the derived view.
- Prior phase's orientation.md if this is not Phase 0 (e.g., for Phase A
  read `.argo/phases/0/orientation.md`).
- Any active change records (status in pending_evaluation / in_application).
- The gate review catalogue: `argo-state load-catalogue reviews`.

Do not read all dossiers or all requirements. The orient work item's job
is to enumerate, not to summarise content.

### 3. Draft orientation.md (Socratic with the human)

Ask the human, in pt-BR, in this order:

1. "Essa é a entrada inicial de Phase <id> ou uma re-entrada por change record?"
   (determines whether there are inherited baselines)
2. Se re-entrada: "Listo os artefatos e decisões que foram invalidados pelo
   change record <id>. Cada um — `valid`, `invalidated`, ou `revalidation_pending`?"
3. "Quais open_items estão sendo carregados de fases anteriores?"
4. "Quais são os gaps que precisam fechar antes do <gate review>? Pra cada um:
   blocking ou não, e que tipo de work item provavelmente fecha ele?"
5. "Quais são os goals concretos desta entrada de fase?" (produced artifacts,
   closed decisions, etc.)

Do not invent answers. The human's synthesis is what becomes the orientation.

Write the file at `.argo/phases/<phase-id>/orientation.md` conforming to
`.argo/schemas/argo-internal/orientation.yaml`. Use YAML frontmatter for
machine-parseable fields plus markdown sections for narrative.

### 4. Close phase-orient; open phase-program

```
$ARGO_HOME/scripts/argo-state close-work-item wi.phase-<phase>.orient
```

Then open the program work item:

```
$ARGO_HOME/scripts/argo-state open-work-item \
  wi.phase-<phase>.program \
  --type phase-program \
  --sub-flow sf.phase-<phase>.orient \
  --target-kind phase-program \
  --target-ref <phase-id>
```

### 5. Draft program.md (Socratic with the human)

Start from the catalogue at `.argo/phase-plans/<phase-id>.yaml`. Expand via
`$ARGO_HOME/scripts/argo-phase-plan <phase-id> --dry-run` to see the
instance sub-flow list. Present that to the human and ask:

1. "Mantenho a ordem padrão do template, ou algum sub-flow precisa ser
   reordenado / pulado?" (honoring any `*_skip` flags already in the catalogue)
2. "Para cada sub-flow, quantos work items você estima? (estimativa grosseira,
   só pra dimensionar)"
3. "Alguma iteração esperada entre sub-flows (ex: research ↔ decide mais de
   uma vez)?"
4. "Dependências cross-sub-flow não óbvias?"

Write `.argo/phases/<phase-id>/program.md` conforming to
`.argo/schemas/argo-internal/program.yaml`.

### 6. Close phase-program

```
$ARGO_HOME/scripts/argo-state close-work-item wi.phase-<phase>.program
```

### 7. Verify and hand off

Run:
- `$ARGO_HOME/scripts/argo-state validate`
- `$ARGO_HOME/scripts/argo-state next-action`

The engine should now propose advancing to `sf.<phase>.ensure-refs` (or the
next sub-flow per the program). Relay that proposal to the human.

## Closing message

```
Phase <id> oriented.

Orientation: .argo/phases/<phase-id>/orientation.md
Program:     .argo/phases/<phase-id>/program.md

Próximo passo sugerido pelo motor: <next-action>

Sessões seguintes não precisam reler tudo — elas leem o orientation e o
program, e o work item ativo aponta pros inputs específicos que precisa.
```

## Rules

- Both files are mandatory. Closing phase-orient without writing
  orientation.md fails the `file_exists` close-criterion. Same for
  phase-program / program.md.
- The human answers, you transcribe. Do not auto-fill.
- Keep each file short — orientation ≤ 2 pages, program ≤ 1 page. Long
  narratives belong elsewhere.
- Language in .argo/ files: English. With human: pt-BR.
