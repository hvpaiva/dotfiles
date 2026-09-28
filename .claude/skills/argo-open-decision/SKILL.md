---
name: argo-open-decision
description: Open an Atlas engineering decision in state.yaml and dispatch argo-decision-facilitator to start structuring evidence. Use when a new section of a DRD requires a decision, or when a human wants to formalise an ad-hoc choice.
argument-hint: "<slug> --phase <p> [--sep-section <s>] [--summary <s>]"
---

# Argo Open Decision

## Flow

1. Parse the argument. Slug must be kebab-case.
2. Run:
   ```
   $ARGO_HOME/scripts/argo-state open-decision <slug> --phase <p> [--sep-section <s>] [--summary <s>]
   ```
   The script appends the entry and prints the new `decision.id`.
3. Dispatch `argo-decision-facilitator` via the Task tool with
   `{decision_id: <id>}`. The facilitator will:
   - gather evidence,
   - structure alternatives,
   - validate every citation through `argo-reference-validator`,
   - draft the ADR file under `docs/ecss/phase-<x>/decisions/`,
   - transition the decision to `pending_human`.
4. Relay the facilitator's closing message to the human **as text in your
   assistant response** — the Claude Code UI collapses Task tool result widgets
   by default, so the human will not see the facilitator's output unless you
   reprint it.

## Rules

- If there is an active change_record whose `impacted_decisions` might
  include this topic, ask the human whether to open the decision anyway
  or wait for the change_record disposition.
- Do not write the file yourself — the facilitator does.
- pt-BR for any conversation with the human; English in the decision
  artifact file.

## Missing arguments

If invoked without `<slug>` or without `--phase`, do not fail. In pt-BR:

1. If `<slug>` missing, show sections in `drd_structure.<type>` with `decision_needed: true` and no linked decision, and ask which section this decision serves. Propose a kebab-case slug from the section title.
2. Default `--phase` to `current_phase.id`; ask confirmation.
3. If `--sep-section` applies (artifact is SEP), ask which section id.
4. `--summary` is optional; if absent, ask for a one-line prompt for the decision.

Only run after every arg is resolved.

## Next-step suggestion

After `argo-decision-facilitator` returns and the decision is in `pending_human`:

```
Próximos passos sugeridos:
- Abrir o draft em docs/ecss/phase-<x>/decisions/<id>-<slug>.md e escrever a seção "Decision".
- /argo-close-decision <id>                                     (quando a seção Decision estiver preenchida)
- /argo-open-trade-study <slug> --phase <p> --open-items ...    (se este topic pede comparativo antes)
```

## /clear discipline

Pode dar `/clear`. O draft da decisão está em disco, o state foi atualizado. Na próxima sessão, abra o draft, preencha, e rode `/argo-close-decision <id>`.
