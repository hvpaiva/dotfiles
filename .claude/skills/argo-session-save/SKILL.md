---
name: argo-session-save
description: End-of-session snapshot — forces a state.yaml backup, prints the derived view, verifies validation, and appends a one-line session log. Use before ending any productive Atlas session.
---

# Argo Session Save

## Flow

1. `$ARGO_HOME/scripts/argo-state backup` → capture the backup path.
2. `$ARGO_HOME/scripts/argo-state validate` → fail loud if the state is broken;
   do not proceed.
3. `$ARGO_HOME/scripts/argo-state view` → reprint the derived snapshot **as text inside a fenced code block in your assistant response**. The Claude Code UI collapses Bash output panels by default ("+N lines (ctrl+o to expand)"); if you do not reprint, the human will not see the snapshot.
4. Append an entry to `.argo/sessions.log` (create if missing) with:
   ```
   <YYYY-MM-DD HH:MM> backup=<path> phase=<current_phase.id> <headline>
   ```
   The headline is the first line of `next_step.headline` from state.
5. Report to the human:
   ```
   Sessão salva.
   - Backup: <path>
   - Fase atual: <id — name (state)>
   - Validate: OK
   - Próximo passo: <headline>
   ```

## Rules

- If `validate` returns errors, do NOT append to `sessions.log`. Report the
  errors and ask the human to fix before saving.
- Do not mutate state.yaml — the backup + view + append-to-log is enough.
- This skill is purely a discipline aid. It does not replace agents that
  already persist their own state changes.

## /clear discipline

Essa skill existe *para* dar `/clear` depois dela. Ao terminar, diga ao humano em uma linha: "Sessão salva. Pode dar `/clear` agora — na próxima sessão o `SessionStart` reinjeta o contexto, e `/argo-next` mostra o próximo passo."
