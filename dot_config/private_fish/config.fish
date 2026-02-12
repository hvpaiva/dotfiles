set -u fish_greeting ""

set -Ux PATH $HOME/.cargo/bin $PATH
fish_add_path -U ~/.cargo/bin
fish_add_path -U ~/.local/bin

if status is-interactive
    starship init fish | source
    enable_transience
end

set -g fish_key_bindings fish_vi_key_bindings
set fish_cursor_default block
set fish_cursor_insert block
set fish_cursor_replace_one underscore
set fish_cursor_replace underscore
set fish_cursor_external line
set fish_cursor_visual block

set -Ux fifc_editor nvim

set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -x MANROFFOPT -c

function n
    if test (count $argv) -eq 0
        nvim .
    else
        nvim $argv
    end
end

function cd
    if test (count $argv) -eq 0
        builtin cd ~
        return
    else if test -d "$argv[1]"
        builtin cd $argv
    else
        z $argv && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    end
end

function starship_transient_prompt_func
    starship module character
end

function open
    xdg-open $argv >/dev/null 2>&1 &
end

if type -q zoxide
    zoxide init fish | source
    set -x _ZO_ECHO 1
    set -x _ZO_RESOLVE_SYMLINKS 1
end

if type -q fzf
    fzf --fish | source
end

set -Ux FZF_DEFAULT_OPTS '
  --color=fg:#CDD6F4,fg+:#d0d0d0,bg:-1,bg+:#262626
  --color=hl:#A2DD9D,hl+:#5fd7ff,info:#CBA6F7,marker:#B4BEFE
  --color=prompt:#CBA6F7,spinner:#F5E0DC,pointer:#F5E0DC,header:#A2DD9D
  --color=border:#262626,label:#aeaeae,query:#d9d9d9
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="❯ "
  --marker="*" --pointer="◆" --separator="─" --scrollbar=""
  --info="right"' 
