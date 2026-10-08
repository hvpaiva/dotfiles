set -o vi

function blerc/vim-mode-hook {
  ble-import vim-surround
  # Redraw the prompt on every vi mode change. The option only exists once the vi
  # keymap is loaded, so it is set here and not from inside the prompt hook (that
  # re-entered the mode indicator unit and ble.sh reported a cyclic dependency).
  bleopt keymap_vi_mode_update_prompt=1
}
blehook/eval-after-load keymap_vi blerc/vim-mode-hook

# Vi mode in a simple way. Just the colors change: green to insert, pink in normal mode
# and its command line, blue in visual, red in select. get-vi-keymap finds the vi keymap
# under auto_complete, menu_complete, nsearch and the like, and makes the prompt depend
# on the keymap stack, so the caret follows the mode and is drawn in every keymap. The
# first prompt can come before the vi keymap module loads, in insert mode.
function ble/prompt/backslash:my/vim-mode {
  # shellcheck disable=SC2154  # ble.sh's own variable
  local keymap=$_ble_decode_keymap
  ble/is-function ble/keymap:vi/script/get-vi-keymap && ble/keymap:vi/script/get-vi-keymap
  case $keymap in
  (vi_[onc]map) ble/prompt/process-prompt-string '\e[95m\$ ' ;;
  (vi_xmap) ble/prompt/process-prompt-string '\e[94m\$ ' ;;
  (vi_smap) ble/prompt/process-prompt-string '\e[91m\$ ' ;;
  (*) ble/prompt/process-prompt-string '\e[92m\$ ' ;;
  esac
}

# Host label, only over SSH: the name dots uses for this host (~/.config/dotfiles/host,
# written by `dots setup`), which on athena is not the asset-tag hostname. BLESH_HOST_LABEL
# (blesh/local.sh) still overrides it; without either, the hostname.
function ble/prompt/backslash:my/ssh-host {
  local label=${BLESH_HOST_LABEL-}
  [[ -z $label && -r ~/.config/dotfiles/host ]] && label=$(<~/.config/dotfiles/host)
  if [[ -n ${SSH_CONNECTION-} || -n ${SSH_CLIENT-} ]]; then
    ble/prompt/process-prompt-string "\e[36m${label:-\\h} "
  fi
}

# Prompt:
# [host ]<dir>   # host only over SSH
# $
PS1='\n\q{my/ssh-host}\e[33m\w\n\q{my/vim-mode}'

# Deactivate default vi mode, like --INSERT--
bleopt keymap_vi_mode_show:=
