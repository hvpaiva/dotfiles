set -o vi

function blerc/vim-mode-hook {
  ble-import vim-surround
}
blehook/eval-after-load keymap_vi blerc/vim-mode-hook

# Vi mode in a simple way. Just the colors change.
function ble/prompt/backslash:my/vim-mode {
  bleopt keymap_vi_mode_update_prompt:=1
  case $_ble_decode_keymap in
  (vi_[on]map) ble/prompt/process-prompt-string '\e[94m\$ ' ;;
  (vi_imap) ble/prompt/process-prompt-string '\e[92m\$ ' ;;
  (vi_smap) ble/prompt/process-prompt-string '\e[91m\$ ' ;;
  (vi_xmap) ble/prompt/process-prompt-string '\e[95m\$ ' ;;
  esac
}

# Prompt:
# <dir>
# $
PS1='\e[33m\n\w\n\q{my/vim-mode}'

# Deactivate default vi mode, like --INSERT--
bleopt keymap_vi_mode_show:=

