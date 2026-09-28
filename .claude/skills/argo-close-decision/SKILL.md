---
name: argo-close-decision
description: Close a decision that has reached status=pending_human. Runs argo-reference-validator as a gate; transitions the decision via argo-state close-decision. Only the human invokes this skill — agents never close decisions.
argument-hint: "<decision-id>"
---

# Argo Close Decision

## Flow

1. Read `.argo/state.yaml` via `argo-state get decisions[id=<id>]`.
   - If status is not `pending_human`, refuse and print the current
     status with a suggested remedy.
   - If `revalidation_required_by` is set, refuse and suggest running
     `/argo-impact <change-record-id>` first.
2. Verify the ADR file at `decisions[id=<id>].artifact_path` exists and
   contains a filled-in "Decision" section (a heuristic: the section is
   not empty and contains more than a placeholder sentence). If it is
   still empty, refuse — the human writes that section.
3. Dispatch `argo-reference-validator` via the Task tool with
   `{target: <artifact_path>}`. If any `error` severity finding appears,
   refuse and print the findings.
4. Run:
   ```
   $ARGO_HOME/scripts/argo-state close-decision <id>
   ```
   The script performs the final gate checks (standards_consulted
   non-empty, artifact_path exists, no open change_record) and
   transitions to `closed`.
5. Report to the human:
   ```
   Decisão <id> fechada.
   - Arquivo: <path>
   - Data: <today>
   - Referências validadas: <n confirmed>
   - Próximas decisões afetadas (se houver): <ids>
   ```

## Rules

- Refuse on any unmet gate — the script prints the exact reason.
- Do not rewrite the decision body to "fix" validation issues; the
  validator surfaces them, the human fixes them.
- If the validator finds minor severity issues, let the close proceed
  but report them so the human can decide whether to remediate.

## Missing arguments

If invoked without `<decision-id>`, do not fail. In pt-BR: list all decisions with `status: pending_human` from `state.yaml`, one per line (`<id> — <slug> — <summary>`). Ask which one the human wants to close. Do not default-pick.

## Next-step suggestion

After the decision closes, close with:

```
Próximos passos sugeridos:
- /argo-write-artifact <artifact-id>   (se agora toda seção decision_needed do DRD tem decisão fechada)
- /argo-open-decision <next-slug>      (se a próxima seção do DRD ainda está aberta)
- /argo-next                           (deixa Argo escolher)
```

Base the suggestions on whether other decisions for the same artifact are still open, and whether this closure unblocks writing.

## /clear discipline

Pode dar `/clear`. A decisão está registrada com `status: closed` em `state.yaml` e o arquivo em `docs/ecss/.../decisions/` está imutável como registro histórico.
