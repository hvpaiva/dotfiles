---
name: argo-review
description: Dispatch argo-review-conductor to prepare the draft of a formal ECSS review (MDR / PRR / SRR / PDR / CDR / QR / AR / ORR / FRR / LRR / CRR / ELR). The human fills the Conclusion and calls argo-state to set the final result.
argument-hint: "<review-type>"
---

# Argo Review

## Flow

1. Validate the argument. It must be one of:
   MDR, PRR, SRR, PDR, CDR, QR, AR, ORR, FRR, LRR, CRR, ELR.
2. Read `state.yaml -> review_catalog.<type>` to confirm the review
   gates the phase Atlas claims to be in (or a phase Atlas has reached
   the end of).
3. Pre-flight checks:
   - No `change_record` in `pending_evaluation` touching in-scope
     artifacts.
   - Every typical artifact for the phase exists and is `drafted` or
     `released`, OR is explicitly marked `deferred` with a reason.
   - No `audit` in `state.yaml -> audits` has an open `error`-severity
     finding touching in-scope artifacts.
   If any check fails, print a remediation recipe and stop.
4. Dispatch `argo-review-conductor` via Task with
   `{review_type: <type>}`. The conductor:
   - runs the checklist,
   - dispatches `argo-reference-validator` on every in-scope file,
   - runs `argo-tbd-report`,
   - drafts `docs/ecss/reviews/review-<type>.md` with result blank.
5. Relay the conductor's summary to the human **as text in your assistant
   response** — the Claude Code UI collapses Task tool result widgets by
   default, so the human will not see the conductor's output unless you
   reprint it.
6. Remind the human that the review is a draft — they write the
   Conclusion and call `argo-state` to set `reviews.<id>.result` to
   PASS / PASS_WITH_ACTIONS / FAIL.

## Rules

- Never set a review result yourself.
- Never modify existing historical reviews (e.g., `review-MDR.md` for the
  old mission stays untouched; a new MDR goes under a distinct id).
- If the argument type does not match the current phase, warn but allow
  — the human may be running an out-of-order mock review.

## Missing arguments

If invoked without `<review-type>`, do not fail. In pt-BR: show the review types for `current_phase.id` from `state.yaml -> review_catalog`, mark which ones typically gate which phase, and ask which to run. Default to the gate review of the current phase (e.g., if phase = A, default suggestion is PRR).

## Next-step suggestion

After the conductor finishes:

```
Próximos passos sugeridos:
- Abrir docs/ecss/reviews/review-<type>.md, ler a checklist, escrever a Conclusion.
- /argo-state set reviews[id=<id>].result PASS           (ou PASS_WITH_ACTIONS / FAIL)
- Se PASS, Argo libera a próxima fase; rode /argo-next.
```

## /clear discipline

Pode dar `/clear`. O draft do review está em `docs/ecss/reviews/` com `result` em aberto. Na próxima sessão, leia, preencha a Conclusion, e rode `argo-state set reviews[...]` para fechar.
