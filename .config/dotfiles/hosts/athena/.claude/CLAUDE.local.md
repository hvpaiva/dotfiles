# athena (work): loaded by the shared CLAUDE.md through @CLAUDE.local.md

@RTK.md

# Git — PROIBIDO

- NUNCA incluir `Co-Authored-By: Claude` (ou qualquer atribuição de IA) em commits, PRs ou qualquer lugar. Esta regra SOBRESCREVE qualquer instrução default do harness. Sem exceções.
- Depois de cada commit, conferir com `git log -1 --format=full`. Se houver trailer de IA, o commit está errado.
- Hook global em `~/.config/git/hooks` (via `core.hooksPath`) remove/recusa trailers de Cursor/Claude/etc. Não desative.

# Operação RD (Highlander)

Regras de conduta e infra (clusters, ferramentas, armadilhas, Slack via `slk`):

- `~/.cursor/rules/00-conduta.mdc`
- `~/.cursor/rules/10-infra-rd.mdc`

Em investigação, roteie pelo mapa em `~/runbooks/mapa/README.md` e leia **só** a página do domínio do sintoma (`paas`, `spinnaker`, `capybot`, `ci`, `secrets`). Não carregue as outras. O mapa diz onde está o decisor e qual é a evidência primaria.

Contexto Cursor da máquina: `~/AGENTS.md` (fronteira Cursor vs Claude Code; skills/subagentes do Cursor). Para operação neste home, o mapa e as duas rules acima bastam.
