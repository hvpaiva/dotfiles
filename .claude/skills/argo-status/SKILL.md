---
name: argo-status
description: Three-level orientation for Atlas under Argo v2 — current phase, active sub-flow, active work item, active change records, pending decisions (filtered by phase), validation, and one deterministic next-action suggestion. Read-only.
---

# Argo Status (v2)

Print the three-level orientation drawn from `.argo/state.yaml` — phase ×
sub-flow × work item — and end with one concrete next-action suggestion
derived from the deterministic engine in `argo-state next-action`.

Read-only: this skill never mutates state.

## Steps

1. Run via Bash, in this exact order:
   - `$ARGO_HOME/scripts/argo-state view`
   - `$ARGO_HOME/scripts/argo-state next-action`
   - `$ARGO_HOME/scripts/argo-state validate`

   **Reprint the outputs in your assistant response** — Bash widgets collapse
   in the Claude Code UI by default. The human does not see them otherwise.

2. If `validate` did not print `OK`, report the errors and stop. Do not
   attempt to repair.

3. Compose a summary in pt-BR, this exact shape:

```
## Onde estamos

**Fase**: <current_phase.id — current_phase.name (current_phase.state)>
**Sub-flow ativo**: <phase_plans.<cp>.active_sub_flow or "—">
**Work item ativo**: <active_work_item.id or "—"> (<type>, <status>)

## Change records ativos
<list of change_records where status in {pending_evaluation, in_application}>

## Artefatos em andamento
<artifacts where status in {in_progress, under_revision, suspended, drafted}>

## Decisões pendentes (fase atual)
<decisions where status in {pending_human, suspended_pending_revalidation} AND phase == current_phase.id>

## Validação do state
OK

## Próxima ação proposta pelo motor
<raw next-action YAML from step 1>

**Resumo em uma linha**: <human-readable one-liner derived from kind + skill + args>

## /clear discipline
Se o motor propôs `human-decision`, decida antes de /clear.
Se há work item ativo, /argo-pause-work ou /argo-close-work-item primeiro.
Caso contrário, /clear é seguro; o SessionStart hook reinjeta contexto.
```

Keep the total to ~50-60 lines. Do not duplicate what `argo-state view`
already rendered; summarise.

## What the three levels look like

```
Level        What you print                      Source in state.yaml
---          ---                                 ---
macro        current_phase.id + state            current_phase
meso         phase_plans.<cp>.active_sub_flow    phase_plans.<cp>.active_sub_flow
micro        active_work_item.id (+ type/status) active_work_item + work_items[id=awi]
```

When all three are populated the human should see: "we are in phase X,
sub-flow Y is active, work item Z is the session contract."

When the work item is null but the sub-flow is set, the engine will propose
opening one (kind=open-work-item).

When sub-flow is null the engine will propose advancing one (kind=advance-sub-flow).

When the phase itself has no phase_plan the engine proposes enter-phase.

## Rules

- Never mutate state.yaml or write to `docs/`.
- Never dispatch a skill from within status. The human dispatches.
- If `argo-state` itself fails, report the error and stop.
- Language of the summary: pt-BR. Data fields stay verbatim (English).
- The raw `next-action` YAML stays untranslated — reproduce it as-is so the
  human sees exactly what the engine decided.
- If `next-action` returns `kind: human-decision`, do not invent a next
  action; surface the rationale and point the human at `/argo-state view`
  for deeper inspection.

## /clear discipline

After producing the status, end with the /clear guidance block shown above.
The block varies based on whether there's an active work item:

- No active work item → `/clear` is safe.
- Active work item in_progress → `/argo-pause-work` or `/argo-close-work-item` first.
- Active work item paused with delta file missing → tell the human the pause
  is malformed and needs the delta written.
