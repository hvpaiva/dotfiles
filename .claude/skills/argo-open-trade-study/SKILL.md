---
name: argo-open-trade-study
description: Open a trade study in state.yaml and dispatch argo-trade-study-facilitator. Use when a decision requires a structured multi-candidate comparison (e.g., camera/optics, comms band, GPS receiver, star tracker).
argument-hint: "<slug> --phase <p> --open-items <oi1,oi2,...> [--linked-decision <did>]"
---

# Argo Open Trade Study

## Flow

1. Validate arguments:
   - slug is kebab-case.
   - Each id in `--open-items` must exist in `state.yaml -> open_items`.
   - If `--linked-decision` is provided, it must exist and be in status
     `open` or `researching`.
2. Append a trade study entry to `state.yaml` (no dedicated subcommand
   yet — use `argo-state backup` then edit the YAML file directly, or
   fall back to a set-path helper). Use id `TS-<phase>-<NNN>` assigned
   sequentially.
3. Dispatch `argo-trade-study-facilitator` via the Task tool with the
   payload:
   ```yaml
   trade_study_id: <id>
   open_items: [...]
   linked_decision: <did or null>
   ```
4. Relay the facilitator's output **as text in your assistant response** — the
   Claude Code UI collapses Task tool result widgets by default, so the human
   will not see the facilitator's output unless you reprint it. The facilitator
   produces candidates, criteria, and prompts the human to sign off weights
   before scoring.

## Rules

- Do not fabricate candidates. The facilitator will ask for them or
  pull from datasheets/refs.
- If a data source is missing, let the facilitator dispatch
  `argo-ref-acquirer` — do not intervene.
- A trade study never selects its own winner; the human does that.

## Missing arguments

If invoked without `<slug>`, `--phase`, or `--open-items`, do not fail. In pt-BR:

1. If `<slug>` missing, list open items with `trade_study_needed: true` and no linked study; propose a slug from the item description.
2. Default `--phase` to `current_phase.id`; ask confirmation.
3. If `--open-items` missing, show the filtered list and ask which ones this study addresses (may be one or several).
4. `--linked-decision` is optional; ask only if the human hints at a pre-existing decision.

## Next-step suggestion

After the facilitator finishes the study (winner picked by human):

```
Próximos passos sugeridos:
- /argo-open-decision <new-slug> --phase <p>     (para formalizar a escolha do trade study como decisão)
- /argo-close-decision <linked-decision-id>       (se o trade study alimenta uma decisão já aberta)
```

## /clear discipline

Pode dar `/clear`. O trade study está em `.argo/trade-studies/<id>.md` e referenciado no state.
