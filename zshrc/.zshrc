# Path to your oh-my-zsh installation.
# Reevaluate the prompt string each time it's displaying a prompt
setopt prompt_subst
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
autoload bashcompinit && bashcompinit
autoload -Uz compinit
compinit
source <(kubectl completion zsh)
complete -C '/usr/local/bin/aws_completer' aws

source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^w' autosuggest-execute
bindkey '^e' autosuggest-accept
bindkey '^u' autosuggest-toggle
bindkey '^L' vi-forward-word
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search

eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# You may need to manually set your language environment
export LANG=en_US.UTF-8

export EDITOR=/opt/homebrew/bin/nvim
export XDG_CONFIG_HOME="$HOME/.config"

alias la=tree
alias cat=bat

# Git
alias gc="git commit -m"
alias gca="git commit -a -m"
alias gp="git push origin HEAD"
alias gpu="git pull origin"
alias gst="git status"
alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
alias gdiff="git diff"
alias gco="git checkout"
alias gb='git branch'
alias gba='git branch -a'
alias gadd='git add'
alias ga='git add -p'
alias gcoall='git checkout -- .'
alias gr='git remote'
alias gre='git reset'

# Docker
alias dco="docker compose"
alias dps="docker ps"
alias dpa="docker ps -a"
alias dl="docker ps -l -q"
alias dx="docker exec -it"

# Dirs
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

# Darwin
alias reload-dotfiles='darwin-rebuild switch --impure --flake ~/dotfiles/nix-darwin && sudo chmod 777 /Users/hpaiva/.config/nvim/lazy-lock.json'

# GO
export GOPATH='/Users/hpaiva/go'

# VIM
alias v="/opt/homebrew/bin/nvim"
alias vim="/opt/homebrew/bin/nvim"

# Nmap
alias nm="nmap -sC -sV -oN nmap"

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/hpaiva/.vimpkg/bin:${GOPATH}/bin:/Users/hpaiva/.cargo/bin

alias cl='clear'

# K8S
export KUBECONFIG=~/.kube/config
alias k="kubectl"
alias ka="kubectl apply -f"
alias kg="kubectl get"
alias kd="kubectl describe"
alias kdel="kubectl delete"
alias kl="kubectl logs"
alias kgpo="kubectl get pod"
alias kgd="kubectl get deployments"
alias kc="kubectx"
alias kns="kubens"
alias kl="kubectl logs -f"
alias ke="kubectl exec -it"
alias kcns='kubectl config set-context --current --namespace'
alias podname=''

# HTTP requests with xh!
alias http="xh"

# VI Mode!!!
bindkey jj vi-cmd-mode

# Eza
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias ltree="eza --tree --level=2  --icons --git"

# SEC STUFF
alias gobust='gobuster dir --wordlist ~/security/wordlists/diccnoext.txt --wildcard --url'
alias dirsearch='python dirsearch.py -w db/dicc.txt -b -u'
alias massdns='~/hacking/tools/massdns/bin/massdns -r ~/hacking/tools/massdns/lists/resolvers.txt -t A -o S bf-targets.txt -w livehosts.txt -s 4000'
alias server='python -m http.server 4445'
alias tunnel='ngrok http 4445'
alias fuzz='ffuf -w ~/hacking/SecLists/content_discovery_all.txt -mc all -u'
alias gr='~/go/src/github.com/tomnomnom/gf/gf'

### FZF ###
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PATH=/opt/homebrew/bin:$PATH

alias mat='osascript -e "tell application \"System Events\" to key code 126 using {command down}" && tmux neww "cmatrix"'

# Nix!
export NIX_CONF_DIR=$HOME/.config/nix
export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
export PATH=/nix/var/nix/profiles/default/bin:$PATH
export PATH=$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH

function ranger {
	local IFS=$'\t\n'
	local tempfile="$(mktemp -t tmp.XXXXXX)"
	local ranger_cmd=(
		command
		ranger
		--cmd="map Q chain shell echo %d > "$tempfile"; quitall"
	)

	${ranger_cmd[@]} "$@"
	if [[ -f "$tempfile" ]] && [[ "$(cat -- "$tempfile")" != "$(echo -n `pwd`)" ]]; then
		cd -- "$(cat "$tempfile")" || return
	fi
	command rm -f -- "$tempfile" 2>/dev/null
}
alias rr='ranger'

# Meli Configs
export GOPRIVATE=github.com/mercadolibre/*,github.com/melisource/*
export GONOSUMDB=github.com/mercadolibre/*,github.com/melisource/*
export GOPROXY=https://go.artifacts.furycloud.io/
export GONOPROXY=https://go.artifacts.furycloud.io/
export PATH=$PATH:/usr/local/go/bin
export PATH="$HOME/.pyenv/bin:$PATH"

## Fury CLI
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export PATH="/Users/hpaiva/Library/Python/3.9/bin:$PATH"
export PATH="/Users/hpaiva/.local/bin:$PATH"

## Services CLI
export PATH=$PATH:/Users/hpaiva/.srvc_cli/venv/bin
eval "$(_SRVC2_COMPLETE=zsh_source srvc2)"

#SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# navigation
cx() { cd "$@" && l; }
fcd() { cd "$(find . -type d -not -path '*/.*' | fzf)" && l; }
f() { echo "$(find . -type f -not -path '*/.*' | fzf)" | pbcopy }
fv() { nvim "$(find . -type f -not -path '*/.*' | fzf)" }

# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
	 . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix
 
# NVM 
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"
eval "$(direnv hook zsh)"

if command -v tmux &> /dev/null; then
  if [[ -z "$TMUX" ]]; then
    tmux attach-session -t default || tmux new-session -s default
  fi
fi
