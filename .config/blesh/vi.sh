set -o vi

function blerc/vim-mode-hook {
  ble-import vim-surround
  # Redraw the prompt on every vi mode change. The option only exists once the vi
  # keymap is loaded, so it is set here and not from inside the prompt hook (that
  # re-entered the mode indicator unit and ble.sh reported a cyclic dependency).
  bleopt keymap_vi_mode_update_prompt=1
}
blehook/eval-after-load keymap_vi blerc/vim-mode-hook

# Vi mode in a simple way. Just the colors change.
function ble/prompt/backslash:my/vim-mode {
  case $_ble_decode_keymap in
  (vi_[on]map) ble/prompt/process-prompt-string '\e[94m\$ ' ;;
  (vi_imap) ble/prompt/process-prompt-string '\e[92m\$ ' ;;
  (vi_smap) ble/prompt/process-prompt-string '\e[91m\$ ' ;;
  (vi_xmap) ble/prompt/process-prompt-string '\e[95m\$ ' ;;
  esac
}

# Host label, only over SSH. BLESH_HOST_LABEL (set in blesh/local.sh) replaces the
# hostname where that is an asset tag rather than a name.
function ble/prompt/backslash:my/ssh-host {
  if [[ -n ${SSH_CONNECTION-} || -n ${SSH_CLIENT-} ]]; then
    ble/prompt/process-prompt-string "\e[36m${BLESH_HOST_LABEL:-\\h} "
  fi
}

# Prompt:
# [host ]<dir>   # host only over SSH
# $
PS1='\n\q{my/ssh-host}\e[33m\w\n\q{my/vim-mode}'

# Deactivate default vi mode, like --INSERT--
bleopt keymap_vi_mode_show:=
