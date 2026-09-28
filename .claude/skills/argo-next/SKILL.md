---
name: argo-next
description: Compute the deterministic next action from the current Atlas state, present it, ask the human to confirm, then dispatch. Use when you open a session and want to just "do the next thing" without manually picking a skill.
---

# Argo Next (v2)

Under Argo v2, `/argo-next` is **not** an LLM picking an action. It is a thin
relay over the deterministic state-machine engine in
`argo-state next-action`. The algorithm lives in
`$ARGO_HOME/scripts/argo-state` (`compute_next_action`); the design rationale is
in `.argo/design/argo-v2-flow.md` §11.1.

Your job:
1. Run the engine.
2. Present the proposal in pt-BR, with the raw YAML pasted so the human sees
   what the machine decided.
3. Ask for confirmation.
4. Dispatch exactly once; stop.

## Flow

### 1. Validate state

Run via Bash:
- `$ARGO_HOME/scripts/argo-state validate`

If output is anything other than `OK`, **reprint the errors in your assistant
response** (Bash panels are collapsed in the Claude Code UI by default) and
stop. Do not propose an action on an inconsistent state.

### 2. Run the engine

Run via Bash:
- `$ARGO_HOME/scripts/argo-state next-action`

The engine returns a YAML block:

```yaml
kind: <dispose-change-record | advance-sub-flow | resume-work-item | continue-work-item | enter-phase | open-work-item | gate-review | human-decision>
skill: <slash-command or 'argo-state ...' or '(one of ...)'>
args: <string>
rationale: <one-sentence explanation>
alternatives: [...]
```

### 3. Present to the human (pt-BR)

Exact shape:

```
**Próximo passo (motor determinístico)**: `<skill>` `<args>`

**Razão**: <rationale, verbatim>

**Alternativas que o motor também permitiria** (se `alternatives` não vazio):
- <alt1>
- <alt2>

**Pendências antes de eu dispatchar**:
- <arg1>: [preciso que você me diga / posso assumir <default>?]
- <pergunta livre sobre intenção, se aplicável>

**Confirma?** (sim / ajustar args / trocar por uma das alternativas / não, deixa eu explorar manualmente)
```

Include the raw YAML output from `next-action` after this block, so the human
can see exactly what the machine returned.

### 4. Interpret `kind` and dispatch guidance

| `kind` | What to actually dispatch |
|---|---|
| `dispose-change-record` | `/argo-impact <change-record-id>` |
| `advance-sub-flow` | `argo-state advance-sub-flow <phase> <sub-flow-id>` (via Bash) |
| `resume-work-item` | `/argo-resume-work <work-item-id>` |
| `continue-work-item` | The dispatching skill named in `skill` (map of types lives in `argo-state`, `_dispatching_skill_for_type`). |
| `enter-phase` | `argo-state enter-phase <phase>` (via Bash). |
| `open-work-item` | Ask the human which `type` to pick from `alternatives`; then run the corresponding dispatching skill. Never pick for them. |
| `gate-review` | `/argo-review <gate-review-type>` |
| `human-decision` | Do not dispatch. Surface the rationale and suggest `/argo-status` or manual exploration. |

### 5. Wait for the human

Do not run anything until you have a `sim` or equivalent.

- `ajustar args` → ask for the replacement. Never auto-fill what the human
  did not confirm.
- `trocar por outra ação` → list the alternatives from Step 2 and let them pick.
- `não, deixa eu explorar` → stop and suggest `/argo-status`.

### 6. Dispatch

When confirmed, run the slash command or Bash via the correct tool. Relay
the dispatched action's output **as text in your assistant response** —
the UI collapses Bash and Task tool result widgets by default.

### 7. Closing message

After the dispatched action completes, print:

```
Concluído: <what was done>

Próximo `/argo-next` ainda vai propor uma ação — o motor recalcula do
estado atual. Se quiser /clear agora, o hook de SessionStart reinjeta
o contexto na próxima sessão.
```

## Rules

- One action per invocation. Never chain.
- Do not skip the pendency question even when you think you can infer all args.
- Language with the human is pt-BR; data fields and YAML stay verbatim.
- Never dispatch an action whose gates you know will fail — explain the gate
  first and let the human decide whether to remediate or change direction.
- Do not second-guess the engine's priority. If the `kind` feels wrong, it
  probably reflects a real state inconsistency — report it and let the human
  decide whether to correct state or override the proposal.
