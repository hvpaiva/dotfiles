# dotfiles

Dotfiles para Arch Linux + [Hyprland](https://hyprland.org/) + [Omarchy](https://omarchy.com/), gerenciados com [chezmoi](https://www.chezmoi.io/).

## Bootstrap

Em uma nova maquina com Arch/Omarchy instalado:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply hvpaiva
```

O chezmoi vai:

1. Perguntar o **perfil** da maquina (`desktop` ou `notebook`)
2. Perguntar o **proposito** (`personal`, `work` ou `both`)
3. Perguntar o **email para git**
4. Aplicar todas as configs
5. Instalar todos os pacotes do perfil selecionado
6. Configurar o hook do pacman para tracking automatico
7. Definir fish como shell padrao, ativar mise e servicos systemd

## Estrutura

```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl          # Perguntas de perfil (desktop/notebook, work/personal)
├── .chezmoiignore              # Exclusoes por perfil
├── run_once_after_01-*         # Instala pacotes
├── run_once_after_02-*         # Instala hook do pacman
├── run_once_after_99-*         # Setup final (shell, mise, systemd)
│
├── dot_config/
│   ├── packages/               # Listas categorizadas (249 pacotes)
│   ├── hypr/                   # Hyprland (monitors.conf templateado)
│   ├── nvim/                   # Neovim (LazyVim)
│   ├── git/                    # Git (email templateado)
│   ├── fish/ bash/ tmux/       # Shell
│   ├── ghostty/                # Terminal
│   ├── waybar/ mako/ walker/   # Desktop UI
│   ├── scripts/                # install_pkgs.sh, pkg-reconcile.sh, etc.
│   └── ...                     # btop, eza, lazygit, mise, sesh, etc.
│
├── private_dot_ssh/            # SSH config + chave publica
│                               # (chave privada fica no 1Password)
└── test/
    └── run_tests.sh            # Suite de testes automatizados
```

## Perfis

O chezmoi usa templates para adaptar configs por maquina:

| Variavel | Opcoes | Afeta |
|----------|--------|-------|
| `profile` | `desktop`, `notebook` | monitors.conf, pacotes nvidia/gaming |
| `purpose` | `personal`, `work`, `both` | pacotes terraform/helm/cursor |
| `git_email` | qualquer email | git config |

Os valores ficam em `~/.config/chezmoi/chezmoi.toml` (gerado no `chezmoi init`).

### Monitors

- **desktop**: `monitor=,preferred,auto,auto` (detecta automaticamente)
- **notebook**: `monitor=eDP-1,preferred,auto,2` (display integrado a 2x)

## Gerenciamento de pacotes

### Categorias

Os 249 pacotes estao divididos em 6 listas em `~/.config/packages/`:

| Arquivo | Quando instala | Exemplos |
|---------|---------------|----------|
| `core.txt` | Sempre | base, hyprland, fish, pipewire, fonts |
| `dev.txt` | Sempre | git, neovim, docker, rust, mise |
| `apps.txt` | Sempre | 1password, zen-browser, signal, spotify |
| `desktop.txt` | profile=desktop | nvidia-open-dkms, steam |
| `work.txt` | purpose=work\|both | terraform, helm, cursor-bin |
| `gaming.txt` | profile=desktop | retroarch + 33 cores libretro |

Formato: uma linha por pacote, `NOME ORIGEM` (pacman/yay/paru).

### Tracking automatico

Um hook do pacman (`/etc/pacman.d/hooks/pkg-snapshot-append.hook`) detecta novos pacotes instalados e adiciona em `~/.config/packages/uncategorized.txt`. Voce depois move para a categoria certa.

### Reconciliacao

```bash
~/.config/scripts/pkg-reconcile.sh
```

Mostra pacotes instalados que nao estao em nenhuma lista, e pacotes nas listas que nao estao instalados.

### Instalacao manual

```bash
~/.config/scripts/install_pkgs.sh ~/.config/packages/core.txt ~/.config/packages/dev.txt
```

Instala em batch por origem (pacman primeiro, depois yay/paru). Se o batch falhar, tenta individualmente e reporta quais falharam.

## Segredos

Nenhum segredo neste repositorio. A chave SSH privada fica no vault do [1Password](https://1password.com/) e e acessada via SSH agent:

```
# ~/.ssh/config
Host *
    IdentityAgent ~/.1password/agent.sock
```

O token do Advent of Code (`cargo-aoc`) e outros segredos ficam exclusivamente no 1Password.

## Decisoes de design

### Por que chezmoi e nao stow/bare git?

- **Templates**: configs variam por maquina (monitors, git email, pacotes nvidia)
- **Scripts de bootstrap**: `run_once_after_*` instalam pacotes e configuram servicos automaticamente
- **Ignore inteligente**: `.chezmoiignore` suporta templates — ignora `desktop.txt` se profile=notebook
- **Merge nao-destrutivo**: chezmoi nunca sobrescreve sem mostrar diff primeiro

### Por que listas de pacotes em .txt e nao no script?

- **Legibilidade**: facil ver/editar o que esta instalado
- **Reconciliacao**: `pkg-reconcile.sh` compara declarado vs instalado
- **Hook automatico**: novos pacotes vao para `uncategorized.txt` automaticamente
- **Perfis**: bootstrap inclui so as listas do perfil selecionado

### Por que run_once_after e nao run_once_before?

Scripts `before` rodam *antes* do chezmoi aplicar os arquivos. Na primeira execucao, os scripts de pacotes e as listas `.txt` ainda nao existem. Por isso usamos `after` — garante que tudo ja foi copiado antes de tentar instalar.

### Por que nao versionar fish_variables?

`fish_variables` contem estado de runtime (PATH, variaveis de plugins). Cada maquina gera o seu. Versionar causaria conflitos constantes.

### Por que manter lazy-lock.json?

O lockfile do Lazy.nvim garante versoes reproduziveis dos plugins. Funciona como um `package-lock.json` — ao aplicar em nova maquina, os plugins serao instalados nas mesmas versoes.

## Testes

```bash
cd ~/.local/share/chezmoi
./test/run_tests.sh
```

A suite valida:

- **Estrutura**: arquivos essenciais existem, nenhum `run_once_before` acidental
- **Pacotes**: sem duplicatas, formato correto, origens validas, 249+ declarados
- **Templates**: sintaxe ok, prompts de perfil presentes
- **Scripts**: `bash -n` em todos, shellcheck se disponivel
- **Segredos**: nenhum AWS key, private key ou .env no repo
- **Chezmoi**: >100 arquivos gerenciados, templates renderizam

## Uso diario

```bash
# Editar uma config
chezmoi edit ~/.config/hypr/bindings.conf

# Ver diferenças antes de aplicar
chezmoi diff

# Aplicar mudancas
chezmoi apply

# Adicionar novo arquivo ao chezmoi
chezmoi add ~/.config/nova-app/config

# Atualizar de outra maquina
chezmoi update

# Re-inicializar (mudar perfil)
chezmoi init --data=false
```

## O que o bootstrap faz

O single command `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply hvpaiva` executa, em ordem:

1. **Instala chezmoi** em `~/.local/bin/`
2. **Clona este repo** para `~/.local/share/chezmoi/`
3. **Pergunta perfil** (desktop/notebook, personal/work/both, email)
4. **Aplica todos os arquivos** — configs, scripts, SSH, packages lists
5. **`run_once_after_01`** — instala yay se necessario, depois instala todos os pacotes em batch
6. **`run_once_after_02`** — instala o hook do pacman em `/etc/pacman.d/hooks/`
7. **`run_once_after_99`** — define fish como shell, instala runtimes mise, plugins fisher, servicos systemd

Resultado: maquina totalmente configurada. Abrir um terminal, logar no Hyprland, pronto.
