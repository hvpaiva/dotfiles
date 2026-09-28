---
name: argo-state
description: Thin wrapper over the `argo-state` script. Supports `get <path>`, `set <path> <value>`, `validate`, `view`, `backup`, `next`, `impacted-of <id>`. Use when you want a precise state-level operation without going through a higher-level skill.
argument-hint: "<subcommand> [args...]"
---

# Argo State

You call `$ARGO_HOME/scripts/argo-state` with the given arguments and relay its
output. This skill exists so the human has a predictable surface for state
mutations while the higher-level skills (open-decision, close-decision, etc.)
also exist.

## Flow

1. Parse the argument into subcommand + args.
2. Run `$ARGO_HOME/scripts/argo-state <subcommand> [args...]` via Bash.
3. Relay stdout and stderr verbatim to the human **as text inside a fenced code block in your assistant response**. The Bash tool's own output panel is collapsed by default in the Claude Code UI ("+N lines (ctrl+o to expand)"), so the human will not see the script output unless you reprint it. "Verbatim" here means: paste the captured stdout (and stderr, if any) into the response, unedited, with no summarization, paraphrase, or commentary in between.

## Supported subcommands (pass through unchanged)

- `get <path>` — dotted-path query.
- `set <path> <value>` — validated write (creates backup first).
- `validate` — cross-reference + invariant check.
- `view` — human-readable markdown snapshot.
- `backup` — create a timestamped copy.
- `next` — print the `next_step` block.
- `impacted-of <change-record-id>` — show impacted artifacts/decisions/open_items.
- `open-decision <slug> --phase <p> [--sep-section <s>] [--summary <s>]`
- `close-decision <id>`
- `suspend-decision <id> [--by <change-record-id>]`
- `revalidate-decision <id> [--by <change-record-id>]`
- `reaffirm-decision <id>`
- `open-artifact <id> --type <t> --phase <p> [--drd <ref>] [--drd-source <path>]`
- `open-change-record --path <p> --scope <...> [--slug <s>] [--kind <k>]`
- `dispose-change-record <id> --disposition <...>`

## Rules

- Do not re-interpret the output. The script's error messages are already
  actionable.
- If the human provides an unsupported subcommand, print `argo-state --help`
  and stop.
- The script itself handles backups, validation, and safe writes. Do not
  replicate any of that here.

## Missing arguments

If invoked without a subcommand (`/argo-state` with no args), do not fail. In pt-BR, list the supported subcommands above and ask which one the human wants. For subcommands with their own required args (e.g., `open-decision <slug> --phase <p>`), if the human picks one but omits args, ask for each missing arg, showing relevant options from `.argo/state.yaml` (open artifacts, pending decisions, change_records) and offering defaults (e.g., `--phase` defaults to `current_phase.id`).

## Next-step suggestion

After a successful mutating subcommand (anything that writes state.yaml), close with a short "Próximos passos sugeridos" section — 1 or 2 concrete slash commands the human can run next, or `/argo-next`.

## /clear discipline

Pode dar `/clear` agora. O estado está em `.argo/state.yaml` (acabou de ser atualizado com backup em `.backups/`), o hook `SessionStart` reinjeta o contexto na próxima sessão, e `/argo-next` (ou `/argo-status`) propõe o próximo passo.
