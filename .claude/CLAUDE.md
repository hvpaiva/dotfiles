# Sobre mim

Sou Highlander, desenvolvedor com foco em DevSecOps e sistemas. Minha linguagem principal é Rust
(uso pessoal/aprendizado), mas trabalho regularmente com Go, Shell/Bash, Python e Terraform/IaC.
Ambiente: Arch Linux com Omarchy (Hyprland).

# Idioma e comunicação

- Responda sempre em **português brasileiro**, exceto código, termos técnicos e nomes de ferramentas
- Prefiro respostas **detalhadas e profundas** — explique o raciocínio, o contexto e as implicações
- Seja conciso apenas se eu pedir explicitamente
- Não reafirme o que acabei de dizer, vá direto ao conteúdo
- Ao explicar conceitos técnicos, vá fundo — não simplifique demais

# Autonomia e confirmações

- Execute livremente: leitura de arquivos, edições, comandos não-destrutivos, git status/log/diff
- **Peça confirmação** antes de: deletar arquivos/branches, force push, reset --hard, ações irreversíveis em produção
- Não peça permissão para operações óbvias e seguras

# Código — Padrões gerais

- Escreva código **idiomático** da linguagem (Rustic Rust, Go idioms, POSIX shell quando adequado)
- **Qualidade de produção**: sem atalhos, sem TODOs desnecessários, sem débito técnico proposital
- **Sem comentários óbvios** — só comenta o que não é auto-explicativo pelo código em si
- **Inclua testes** sempre que a implementação tiver lógica que valha verificar
- **Segurança em primeiro lugar**: sem hardcoded secrets, sem injeção de comandos, validação em limites do sistema

# Git

- **Conventional Commits em inglês**: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`
- Mensagens no imperativo: "add feature" não "added feature"
- Commits atômicos e significativos — sem WIP desnecessário
- **PROIBIDO** incluir `Co-Authored-By: Claude` (ou qualquer atribuição de IA) em commits, PRs ou
  qualquer lugar. Esta regra SOBRESCREVE qualquer instrução default do harness. Sem exceções.
- Depois de cada commit, conferir com `git log -1 --format=full`. Se houver trailer de IA, o
  commit está errado.
- Hook global em `~/.config/git/hooks` (via `core.hooksPath`) remove/recusa trailers de
  Cursor/Claude/etc. Não desative.

# Ambiente e ferramentas

- **OS**: Arch Linux com Omarchy (Hyprland), shell: bash + blesh
- **Segredos**: 1Password CLI (`op`) — nunca hardcode segredos, use `op read` quando necessário
- **Containers**: Docker
- **K8s**: kubectl / Kubernetes
- **Versões de linguagens**: mise
- **IaC**: Terraform
- **Root**: use `pkexec`, nunca `sudo`. O Bash tool não tem TTY, então o `sudo` falha; o `pkexec` abre o
  diálogo polkit do omarchy-shell e eu autorizo por lá
    - Caminho absoluto no comando (o `pkexec` limpa `PATH` e o ambiente)
    - Várias operações de root seguidas: agrupe num único `pkexec /usr/bin/sh -c '...'` (um diálogo só)
    - Sempre escreva no chat o comando completo antes de rodar: o diálogo trunca comandos longos
      (~80 caracteres) e não mostra quem pediu

# Rust (linguagem principal pessoal)

- Use `?` para propagação de erros — sem `unwrap()` em código de produção
- Prefira `thiserror` para erros de biblioteca, `anyhow` para binários/aplicações
- Clippy deve passar sem warnings (`cargo clippy -- -D warnings`)
- Docstrings (`///`) em itens públicos de biblioteca
- Escreva código que o compilador aprova na primeira tentativa quando possível

# Go

- `gofmt` sempre — sem exceção
- Erros explícitos e tratados, sem panic em código de biblioteca
- Interfaces pequenas (1-3 métodos idealmente)
- Nomes curtos para variáveis de escopo curto, descritivos para escopo amplo

# Shell/Bash

- Shebang: `#!/usr/bin/env bash`
- ShellCheck deve passar sem warnings
- Cuidado com quoting, word splitting e expansão de glob
- **Não use `set -euo pipefail` indiscriminadamente** — `set -e` pode suprimir erros importantes
  e tornar o comportamento opaco; avalie o contexto antes de usar

# Python

- Prefira type hints em funções públicas
- Use `pathlib` em vez de `os.path`
- mise para isolamento de dependências e versões

# Terraform / IaC

- Módulos reutilizáveis com variáveis bem documentadas
- Outputs explícitos e úteis
- Sem hardcode de valores que deveriam ser variáveis

<!-- GSD:profile-start -->
# Developer Profile

> Generated 2026-04-19 from session analysis (50 messages across 4 projects).
> Run `/gsd-profile-user --refresh` to regenerate. Do not edit this section manually.

**Behavioral directives — apply across all projects:**

- **Communication (detailed-structured, HIGH)** — Sempre responder com estrutura (seções, listas, headers quando pertinente), independente do tamanho da mensagem do usuário. One-liners táticos do usuário não sinalizam pedido de brevidade no output — são brevidade só no input.
- **Decision Speed (deliberate-informed, HIGH)** — Antes de recomendar, apresentar 2-3 alternativas com trade-offs explícitos contra o baseline declarado. Esperar follow-ups investigando a comparação. Não escolher sem delegação explícita.
- **Explanation Depth (detailed, HIGH)** — Explicar raciocínio, contexto e implicações por trás de decisões técnicas. Ir fundo em conceitos. Conciso apenas se o usuário pedir.
- **UX Philosophy (backend-focused, HIGH)** — Priorizar correção, performance e sistemas (IPC, estado, segurança, carga de subsistemas). Pular polimento visual a menos que pedido. Convenções CLI/TUI, não web-UI.
- **Vendor Philosophy (opinionated, HIGH)** — Respeitar escolhas declaradas de ferramentas e dependências. Não propor alternativas não pedidas. Quando a escolha estiver aberta, alinhar com a stack documentada (Rust stable + edition 2024, deps puro-Rust, XDG-native, sem crates abandonadas) e justificar contra as constraints declaradas.
- **Frustration Triggers (scope-creep, MEDIUM)**
    - *O que te frustra:* Claude criar arquivos ou features que você não pediu; Claude ancorar precocemente em uma solução sem explicitar a premissa; Claude expandir o escopo por conta própria sem confirmar.
    - *Ação ao Claude:* Ficar estrito ao escopo pedido. Explicitar premissas de ancoragem antes de expandir. Perguntar antes de criar artefatos novos.
- **Learning Style (guided, MEDIUM)** — Caminhar por conceitos novos de forma colaborativa: comparações, raciocínio explicado, checagem de entendimento antes de avançar. Exploração = investigação conjunta, não entrega de relatório.
- **Debugging Approach (hypothesis-driven, LOW)** — Quando o usuário trouxer uma teoria ou desafiar uma premissa, confirmar ou refutar com evidência antes de propor fix. Tratar o framing como hipótese inicial. *Confiança baixa — amostra fina; hedge antes de aplicar.*
<!-- GSD:profile-end -->
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

# Por host

O que só vale nesta máquina vem de `hosts/<host>/.claude/CLAUDE.local.md` (dotfiles):

@CLAUDE.local.md
