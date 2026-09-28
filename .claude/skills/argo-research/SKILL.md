---
name: argo-research
description: Open an Argo research dossier and dispatch argo-researcher. Two modes — Mode A (research a new question that serves a decision / open item / change record / artifact) and Mode B (triage, and optionally translate, the 25 legacy COMPASS dossiers under .compass/RESEARCH/ against an active change record). Produces cited dossiers at .argo/research/<slug>.md. Never autofills citations; unanchored claims are declared explicit.
argument-hint: "<slug> --serves <kind>:<id> [--question \"<q>\"] | triage [--change-record <id>] [--translate <threshold>]"
---

# Argo Research

Research lives in `.argo/research/`. Legacy COMPASS research lives in
`.compass/RESEARCH/` and is read-only to Argo.

Two dispatch shapes:

- **Mode A (new research)**: `argo-research <slug> --serves <kind>:<id>`
- **Mode B (triage legacy)**: `argo-research triage [--change-record <id>] [--translate <threshold>]`

## Mode A flow

1. Parse arguments.
   - `slug` is kebab-case and must not collide with an existing
     `research_dossiers.argo_dossiers[*].slug`.
   - `--serves <kind>:<id>` where kind ∈
     `{decision, open_item, change_record, artifact, freestanding}`.
     If kind is not `freestanding`, the id must exist in `state.yaml`.
   - `--question` is optional. If absent, ask the human for a literal
     one-sentence question before dispatching.
   - `--stale-trigger` is optional. Default: `"change_record: <current
     in_application record id or 'none'>"`.
   - `--source-candidates` is optional. Accepts a comma- or
     semicolon-separated list of URL hints, standard ids, or ref entry
     numbers. The researcher can also discover candidates during Step 2.

2. If `argo-state` grows an `open-research` subcommand later, use it.
   Until then, append the entry to `state.yaml -> research_dossiers.argo_dossiers`
   manually: backup via `$ARGO_HOME/scripts/argo-backup .argo/state.yaml`,
   add an entry with `status: draft` and a freshly assigned `id:
   RD-<NNN>` (next integer after the highest existing), then
   `$ARGO_HOME/scripts/argo-state validate`. If validation fails, revert
   from backup and stop.

3. Dispatch `argo-researcher` via the Task tool with the payload:

   ```yaml
   research_request:
     slug: <slug>
     question: <question>
     serves:
       kind: <kind>
       id: <id or null>
     context: <human-provided or derived from serves target>
     source_candidates: [<list>]
     stale_trigger: <rule>
   ```

4. Relay the researcher's closing summary **as text in your assistant
   response** — the Claude Code UI collapses Task tool result widgets by
   default, so the human will not see the researcher's output unless you
   reprint it. Include: dossier path, status (complete/draft), citation
   count, acquisitions triggered, open sub-questions, any contradictions
   flagged, and suggested follow-up skills.

## Mode B flow (triage)

1. Parse arguments.
   - `--change-record <id>` — defaults to the most recent
     `change_records[*]` whose status is `pending_evaluation` or
     `in_application`. If none exists and the human did not pass
     `--change-record`, ask before proceeding.
   - `--translate <threshold>` — optional. Accepted values:
     `useful_verbatim` (translate only topic-agnostic dossiers) or
     `useful_with_update` (translate both verbatim-useful and
     partially-useful). If omitted, runs triage only.

2. Verify `.compass/RESEARCH/` exists and contains the dossiers that
   `state.yaml -> research_dossiers.compass_legacy` claims it does. If
   the count mismatches, surface to the human.

3. Dispatch `argo-researcher` with:

   ```yaml
   triage_request:
     legacy_paths: [<all discovered dossier paths>]
     change_record: <id>
     action: triage_only | triage_and_translate
     translate_threshold: <threshold or null>
   ```

4. Relay the triage summary. Include: the triage file path
   (`.argo/research/triage-<YYYY-MM-DD>.md`), per-classification
   counts (`useful_verbatim: N, useful_with_update: N, superseded: N,
   not_applicable: N`), any translations produced with their new RD
   ids, and any citation-provenance anomalies uncovered.

## Rules

- The researcher is the only place dossier files are written. This skill
  registers the dossier entry; the researcher writes the content.
- No citation ships without passing through `argo-reference-validator`.
  The researcher dispatches the validator; this skill does not duplicate
  that step.
- If a source gap is detected, the researcher dispatches
  `argo-ref-acquirer` — do not intervene.
- Do not instruct the researcher to "fill in reasonable values" when
  sources are missing. Argo refuses to confabulate; reaffirm that
  invariant if the human asks for a "quick draft."
- pt-BR for questions to the human; English for dossier content.

## Missing arguments

If invoked without enough to dispatch, do not fail. In pt-BR:

- **Mode A, `<slug>` missing**: list open items / decisions / change
  records that are candidates (those marked `research_needed: true` or
  those impacted by an active change record and without a linked
  dossier). Propose a slug from the target's description.
- **Mode A, `--serves` missing**: ask which primitive the research
  serves. A freestanding dossier is allowed but rare — flag as unusual.
- **Mode A, `--question` missing**: ask for one literal sentence. Refuse
  to synthesise the question yourself.
- **Mode B, `--change-record` missing, multiple candidates**: list the
  active change records and ask which one governs the triage.
- **Mode B, `--translate` missing**: default to triage-only; mention the
  option explicitly so the human knows to re-run with `--translate` if
  they want translation in the same pass.

## Next-step suggestions

After Mode A:

```
Próximos passos sugeridos:
- /argo-open-decision <slug> --phase <p>        (se a research fecha escopo de decisão)
- /argo-open-trade-study <slug> --phase <p>     (se aparecer um comparativo estruturado)
- /argo-research <new-slug> --serves <kind>:<id>  (para cada open sub-question que o humano aceitar)
- /argo-next                                    (deixa Argo escolher a próxima ação)
```

After Mode B:

```
Próximos passos sugeridos:
- Revisar .argo/research/triage-<YYYY-MM-DD>.md linha a linha.
- Para cada dossier classificado useful_verbatim ou useful_with_update que ainda não foi traduzido: /argo-research <slug> --serves <kind>:<id> (ou re-rodar o triage com --translate).
- Para dossiers superseded: confirmar descarte; Argo não fará referência a eles.
- /argo-next
```

## /clear discipline

Pode dar `/clear`. Os dossiers vivem em `.argo/research/` e os entries
no state.yaml sobrevivem a reset de sessão. Na próxima sessão
`/argo-next` escolhe a próxima ação informada pelos dossiers recentes.
