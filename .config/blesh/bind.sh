# Custom ble.sh key bindings
bind 'set menu-complete-display-prefix off'

function blerc/history-keybindings {
  local keymap
  for keymap in vi_imap vi_nmap; do
    ble-bind -m "$keymap" -f up 'history-search-backward hide-status:immediate-accept:point=end'
    ble-bind -m "$keymap" -f down 'history-search-forward hide-status:immediate-accept:point=end'
  done
}
blehook/eval-after-load keymap_vi blerc/history-keybindings
