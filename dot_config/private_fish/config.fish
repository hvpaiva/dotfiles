
set -u fish_greeting ""

# Variables
set -x GPG_TTY (tty)
set -x EDITOR nvim
set -x DOTNET_CLI_TELEMETRY_OPTOUT 1
set -x HOMEBREW_NO_ANALYTICS 1
set -x GOPATH "$HOME/go"
set -x GOBIN "$GOPATH/bin"
set -x STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
set -x OP_BIOMETRIC_UNLOCK_ENABLED true
set -x MELI_ENV true
set -gx macOS_Theme (cat $HOME/.color_mode | string collect)
set -x JAVA_HOME (asdf where java)
set -x EZA_CONFIG_DIR "$HOME/.config/eza"

if [ "$MELI_ENV" = true ]
    set -x GOPRIVATE "github.com/mercadolibre/*,github.com/melisource/*"
    set -x GONOSUMDB "github.com/mercadolibre/*,github.com/melisource/*"
    set -x GOPROXY "https://proxy.golang.org,direct,https://go.artifacts.furycloud.io"
    set -x GONOPROXY "github.com/mercadolibre/*,github.com/melisource/*"
end

set fish_color_param cyan
set fish_pager_color_completion blue --bold
set fish_color_normal black
set fish_color_error red
set fish_color_comment gray
set fish_color_autosuggestion gray

set -g fish_key_bindings fish_vi_key_bindings
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore
set fish_cursor_replace underscore
set fish_cursor_external line
set fish_cursor_visual block

if [ "$macOS_Theme" = light ]
    set -x LS_COLORS "vivid generate $HOME/.config/vivid/onelight.yml"
else if [ "$macOS_Theme" = dark ]
    set -x LS_COLORS "vivid generate $HOME/.config/vivid/onedark.yml"
end

# Paths
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/bin/brew
fish_add_path /opt/homebrew/sbin
fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.local/share/nvim/mason/bin"
fish_add_path "$HOME/.srvc_cli/venv/bin"
fish_add_path "$HOME/.fury/fury_venv/bin"
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.scripts/bin"

source $HOME/.config/fish/fzf.fish
source $HOME/.config/fish/aliases.fish
source $HOME/.config/fish/functions.fish
source $HOME/.config/fish/theme.fish


if type -q zoxide
    zoxide init fish | source
    set -x _ZO_DATA_DIR "$HOME/.local/share/zoxide"
    set -x _ZO_ECHO 1
    set -x _ZO_RESOLVE_SYMLINKS 1
end

if status is-interactive
    load_env_vars ~/.env
    starship init fish | source
end

# ASDF
fish_add_path (asdf where python)/bin
fish_add_path (asdf where perl)/bin
fish_add_path (asdf where golang)/packages/bin


colorscript random
