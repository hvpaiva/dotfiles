---
name: argo-audit
description: Dispatch argo-reference-validator on a single file or on every file listed as an artifact. Returns a classified findings report (error / minor / informational) and updates state.yaml reference entries. Use ad-hoc when you suspect citation drift, and automatically before any review.
argument-hint: "[file path | artifact id | 'all']"
---

# Argo Audit

## Flow

1. Parse the argument:
   - No argument or `all` → every `drafted`/`released`/`released_pending_revision`/`under_revision` artifact in `state.yaml -> artifacts[].path`.
   - Artifact id (e.g., `ATLAS-MDD-001`) → the file at `artifact.path`.
   - Arbitrary path → that file.
2. For each target, dispatch `argo-reference-validator` via Task with
   `{target: <path>}`. Parallelise when there is more than one target
   (send them in a single message with multiple Task calls).
3. Aggregate the reports:
   ```
   Audit — <date>
   Targets: <n>
   Findings totals: error=<n>, minor=<n>, informational=<n>
   
   By target:
   - <path>: <error/minor/informational counts>
   ```
4. Write the aggregated report to `.argo/audits/<YYYY-MM-DD-HHMM>.md`.
   Add an entry under `state.yaml -> audits` with the new id, status
   `draft`, remediation_status `pending_human_disposition`, and the
   findings counts.

## Rules

- Do not modify the audited files.
- If any finding is `error` severity on an artifact that will feed into
  a review, remind the human that the review will be blocked until
  remediation.
- Relay the individual per-target reports so the human can drill in **as text
  in your assistant response** (a fenced code block per target works well).
  The Claude Code UI collapses Task tool result widgets by default, so the
  human will not see the validator output unless you reprint it.

## Missing arguments

If invoked without arguments, do not fail and do not silently default to `all`. In pt-BR: offer the three modes (single file, single artifact id, or `all` for every drafted/released artifact), show the current artifacts in `state.yaml` with their statuses, and ask which to audit.

## Next-step suggestion

After the audit report is written:

```
Próximos passos sugeridos:
- (para cada finding error severity) editar o artefato citado e corrigir
- /argo-audit <path>                 (re-audit após correção)
- /argo-review <type>                 (uma vez que todos os errors resolvam — o review bloqueia se houver error aberto)
```

## /clear discipline

Pode dar `/clear`. O audit report está em `.argo/audits/<date>.md` e registrado em `state.yaml -> audits`.
