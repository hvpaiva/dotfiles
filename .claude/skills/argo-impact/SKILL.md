---
name: argo-impact
description: Dispatch argo-impact-analyzer on a change_record. Walks the artifact / decision / requirement / open-item graph and produces a revalidation checklist. Updates state.yaml status transitions where warranted.
argument-hint: "<change-record-id>"
---

# Argo Impact

## Flow

1. Read `state.yaml -> change_records` and locate the entry with `id =
   <argument>`. If missing, list all change_records with their statuses
   and stop.
2. If the record's status is `applied` or `abandoned`, warn the human —
   walking the graph is still allowed but has no effect. Ask before
   dispatching.
3. Dispatch `argo-impact-analyzer` via Task with
   `{change_record_id: <id>}`. The analyzer:
   - confirms the hypothesis against actual artifact content,
   - walks closed + open decisions and transitions status where warranted,
   - walks artifacts and marks suspensions / revisions,
   - walks open items, proposing supersessions and new `NI-*` items,
   - flags affected requirements,
   - writes the report to `.argo/impact/<change_record_id>.md`,
   - updates `state.yaml` atomically.
4. Relay the analyzer's summary and the path to the full report **as text in
   your assistant response** — the Claude Code UI collapses Task tool result
   widgets by default, so the human will not see the analyzer's output unless
   you reprint it.
5. Print the `Suggested next actions` section in the same response so the
   human can pick the next skill to run (`/argo-open-decision`,
   `/argo-write-artifact`, etc.).

## Rules

- The analyzer is the only place decisions transition to
  `suspended_pending_revalidation` automatically — do not replicate that
  logic here.
- If validation fails after the analyzer's state write, ask the analyzer
  to revert (it keeps a backup); do not manually patch state.yaml here.

## Missing arguments

If invoked without `<change-record-id>`, do not fail. In pt-BR: list every change_record in `state.yaml`, with status, disposition, and scope one-liner. Ask which to analyse. If only one is in `pending_evaluation` or `in_application`, default-propose that one but still confirm.

## Next-step suggestion

After the analyzer writes `.argo/impact/<id>.md`:

```
Próximos passos sugeridos:
- Revisar .argo/impact/<id>.md linha a linha.
- Para cada decisão suspended_pending_revalidation: /argo-state reaffirm-decision <id>  (ou abrir nova decisão superseder)
- Para cada NI-* proposta: confirmar ou remover antes de /argo-open-decision / /argo-open-trade-study correspondente.
- /argo-next   (deixa Argo escolher o primeiro item da lista)
```

## /clear discipline

Pode dar `/clear`. O relatório completo do impact está em `.argo/impact/<id>.md` (não volátil) e o state já foi transicionado com os `suspended_pending_revalidation`.
