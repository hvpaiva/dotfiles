---
name: argo-advance-sub-flow
description: Human-confirmed transition of the active sub-flow pointer inside a phase plan. Validates the current sub-flow's exit predicate before moving on, and optionally verifies the target's entry predicate. Never advances automatically.
---

# Argo Advance Sub-flow

Transitions `phase_plans.<phase-id>.active_sub_flow` from its current value
to a new target. Confirms with the human that the current sub-flow's exit
predicate is met before making the jump.

This skill is called by `/argo-next` when the motor proposes
`kind: advance-sub-flow`. You may also invoke it directly if you know the
next sub-flow.

## Preconditions

- Phase plan instantiated (`phase_plans.<phase-id>` exists).
- No active work item (if one exists, close or pause it first — a sub-flow
  transition while a work item is in_progress is structurally suspect).
- Target sub-flow id exists in `phase_plans.<phase-id>.sub_flows`.

Run:
- `$ARGO_HOME/scripts/argo-state get active_work_item`
- `$ARGO_HOME/scripts/argo-state get 'phase_plans.<phase>.active_sub_flow'`
- `$ARGO_HOME/scripts/argo-state get 'phase_plans.<phase>.sub_flows'`

Reprint.

## Steps

### 1. Identify the current and target sub-flows

Arguments: `<phase-id>` and `<target-sub-flow-id>`.

Look up:
- `current` = `phase_plans.<phase-id>.active_sub_flow`
- `target` = the target sub-flow object in `sub_flows`

### 2. Check the current sub-flow's exit predicate

The predicate is a string in `sub_flows[id=<current>].exit_predicate`.
These are human-readable, not machine-evaluable for now (the evaluator is
not yet implemented — tracked as a TODO in U3 close-criteria notes). So:

- Print the predicate to the human in pt-BR.
- Ask: "Esse predicado está verdadeiro agora? Quais evidências?"
- Require a yes + evidence. A plain "sim" without evidence is not enough —
  the whole point of the gate is to force an explicit articulation.

If the human says "no" or "não tenho certeza", stop. Do not advance. Suggest
opening work items under the current sub-flow to close the predicate.

If the human cites evidence (a file, a state field, a closed decision),
note it in the session log before proceeding.

### 3. Check the target sub-flow's entry predicate

Similarly, print `sub_flows[id=<target>].entry_predicate` and ask the human
to confirm it holds. Same evidence rule.

### 4. Run argo-state advance-sub-flow

```
$ARGO_HOME/scripts/argo-state advance-sub-flow <phase-id> <target-sub-flow-id>
```

This:
- Transitions `current` → `done` (or `revisited` if it was already `done`).
- Transitions `target` → `active`.
- Sets `active_sub_flow = target`.

### 5. Verify

Run:
- `$ARGO_HOME/scripts/argo-state validate`
- `$ARGO_HOME/scripts/argo-state next-action`

Reprint the next-action proposal.

## Closing message

```
Sub-flow advanced:
  Phase <phase-id>: <current-sub-flow> → <target-sub-flow>

Próxima proposta do motor: <next-action>

Evidência citada no advance (para log):
  Exit(<current>): <quote from human>
  Entry(<target>): <quote from human>
```

## Rules

- Never advance without the human's explicit evidence for both predicates.
  The evidence is the whole reason the gate exists — if you skip it, the
  sub-flow machinery is no better than free-text `next_step.headline`.
- Revisiting a done sub-flow (iteration, e.g., research → decide → research)
  is legitimate. The script handles `done → revisited` automatically.
- Do not advance if there's an in_progress work item. Ask the human to
  close or pause it first. Exception: if the in_progress work item is a
  trivial retroactive registration (no session synthesis), close it.
- Language with the human: pt-BR. The state mutations are run in English.

## Special case — re-baseline

If the target is `sf.<phase>.re-baseline` and an active change record with
`disposition: reopen_phase_<phase>` exists, the motor may recommend this
transition automatically. The human still confirms — the change record
itself does not grant authority to mutate sub-flow state.
