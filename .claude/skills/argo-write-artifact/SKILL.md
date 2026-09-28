---
name: argo-write-artifact
description: Dispatch argo-artifact-writer to produce the ECSS artifact's markdown file under docs/ecss/<phase>/. Verifies every gate before dispatching. Use after all required decisions for the artifact are closed or explicitly deferred.
argument-hint: "<artifact-id>"
---

# Argo Write Artifact

## Flow

1. Read `.argo/state.yaml` and locate the artifact entry.
2. Pre-flight gates (do not delegate — fail loud here if any miss):
   - `artifact.status` must be `in_progress` or `under_revision`.
   - `artifact.drd_extraction.done` must be true. If false, propose
     `/argo-open-artifact` or direct dispatch of `argo-drd-extractor`.
   - Every section in `drd_structure.<type>` with `decision_needed =
     true` must link to a decision whose `status` is `closed` or
     `reaffirmed`, unless marked `deferred` with a reason.
   - No `change_record` whose `impacted_artifacts` contains this artifact
     is in `pending_evaluation`.
3. If any gate fails, print a short remediation recipe (pt-BR) showing
   which skills to run in what order. Do not dispatch the writer.
4. If all gates pass, dispatch `argo-artifact-writer` via Task with
   `{artifact_id: <id>}`.
5. Relay the writer's output and next-step suggestion (typically
   `/argo-review <type>`) **as text in your assistant response** — the Claude
   Code UI collapses Task tool result widgets by default, so the human will
   not see the writer's output unless you reprint it.

## Rules

- Do not bypass a gate "just this once".
- Do not edit `docs/` in this skill. The writer does the edit, atomically.
- If the writer reports reference-validator errors, surface them verbatim
  **as text in your assistant response** (the harness collapses Task results
  by default — if you do not reprint, the human will not see the errors); do
  not attempt to auto-fix.

## Missing arguments

If invoked without `<artifact-id>`, do not fail. In pt-BR: list every artifact in `state.yaml` whose status is `in_progress` or `under_revision`, with their pending decisions count. Ask which one the human wants to write. If none are gate-ready, say so and propose `/argo-next`.

## Next-step suggestion

After the writer finishes and status is `drafted`:

```
Próximos passos sugeridos:
- /argo-audit <artifact-id>    (validar citações antes de marcar pronto pra review)
- /argo-review <gate-review>   (dispara o review conductor para a fase correspondente)
- /argo-next
```

## /clear discipline

Pode dar `/clear`. O artefato está em `docs/ecss/<phase>/` com status `drafted` no state. Na próxima sessão, `/argo-next` propõe o review.
