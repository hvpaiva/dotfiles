---
name: argo-open-artifact
description: Open an ECSS artifact entry in state.yaml and dispatch argo-drd-extractor to read the DRD and record its structure. Use when starting work on any artifact in any phase.
argument-hint: "<id> --type <type> --phase <p> [--drd <ref>] [--drd-source <path>]"
---

# Argo Open Artifact

## Flow

1. Validate argument — the `--type` must be a known `artifact.type`
   (see `.argo/schemas/artifact.yaml`). The `--phase` must match the
   `current_phase.id` or a later unlocked phase, unless the human is
   explicitly preparing ahead — in that case confirm.
2. Run:
   ```
   $ARGO_HOME/scripts/argo-state open-artifact <id> --type <type> --phase <p> [--drd <ref>] [--drd-source <path>]
   ```
   The script validates and appends the artifact entry.
3. If `--drd-source` was provided and the file exists under `ref/`,
   dispatch `argo-drd-extractor` via the Task tool with payload
   `{artifact_id: <id>}`. Relay the agent's report back to the human **as text
   in your assistant response** — the Claude Code UI collapses Task tool result
   widgets by default, so the human will not see the extractor's output unless
   you reprint it.
4. If `--drd-source` was omitted or the file does not exist, print a
   prompt:
   ```
   DRD source file not in ref/. Options:
   - Provide an existing ref/ path: /argo-state set artifacts[id=<id>].drd_source_file <path>
   - Acquire it via argo-ref-acquirer (dispatch? y/n)
   ```
   If the human confirms, dispatch `argo-ref-acquirer` with the ECSS
   portal URL candidates.

## Rules

- Do not write to `docs/` yourself. The artifact file is drafted later by
  `argo-artifact-writer` once all gates pass.
- Do not invent a `drd` value — pass through whatever the human provided,
  or `tbd`.
- If `argo-state validate` fails after the append, abort — the script
  already printed the errors.

## Missing arguments

If the human invokes `/argo-open-artifact` without a complete argument list (id, `--type`, `--phase`), do not fail. In pt-BR:

1. List the typical artifacts for `current_phase.id` from `state.yaml -> phases_catalog`, and suggest an id following the convention `ATLAS-<Type>` (e.g., `ATLAS-SEP`, `ATLAS-FunctionTree`).
2. Ask for the missing `--type` (from the enum in `.argo/schemas/artifact.yaml`).
3. Default `--phase` to `current_phase.id` and ask confirmation.
4. If `--drd-source` missing, ask whether the DRD is already in `ref/` (offer to scan for matches) or needs acquisition via `argo-ref-acquirer`.

Only run after every required arg is resolved.

## Next-step suggestion

After the artifact opens and the DRD is extracted, close with:

```
Próximos passos sugeridos:
- /argo-open-decision <slug> --phase <p> [--sep-section <s>]   (para cada seção decision_needed do DRD)
- /argo-next                                                    (deixa Argo escolher a próxima decisão a abrir)
```

## /clear discipline

Pode dar `/clear` agora. O artefato está registrado em `.argo/state.yaml` e a estrutura do DRD em `drd_structure.<type>`. Na próxima sessão, `/argo-next` propõe a primeira decisão a abrir.
