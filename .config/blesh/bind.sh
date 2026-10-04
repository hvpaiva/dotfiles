# Custom ble.sh key bindings
bind 'set menu-complete-display-prefix off'

# Move within the command (including wrapped lines), then search at its edges.
# The _ble_* variables are provided by the running ble.sh editor.
# shellcheck disable=SC2154
function ble/widget/blerc/line-or-history {
  local direction=$1 can_move=

  # Keep other search bindings unchanged, and let pending searches finish.
  if [[ $_ble_decode_keymap == nsearch ]] &&
     { [[ :$_ble_edit_nsearch_opts: != *:blerc-line-history:* ]] ||
       ((${#_ble_util_fiberchain[@]})); }; then
    ble/widget/nsearch/"$direction"
    return
  fi

  if ble/edit/use-textmap; then
    # getxy.cur assigns both coordinates through Bash's dynamic scope.
    # shellcheck disable=SC2034
    local x y
    ble/textmap#getxy.cur "$_ble_edit_ind"
    if [[ $direction == backward ]]; then
      ((y > _ble_textmap_begy)) && can_move=1
    else
      ((y < _ble_textmap_endy)) && can_move=1
    fi
  elif [[ $direction == backward ]]; then
    [[ ${_ble_edit_str::_ble_edit_ind} == *$'\n'* ]] && can_move=1
  else
    [[ ${_ble_edit_str:_ble_edit_ind} == *$'\n'* ]] && can_move=1
  fi

  if [[ $can_move ]]; then
    # Leave search without accepting/executing the recalled command.
    [[ $_ble_decode_keymap == nsearch ]] && ble/widget/nsearch/.exit
    if [[ $_ble_decode_keymap == vi_nmap ]]; then
      ble/widget/vi-command/graphical-"$direction"-line
    else
      ble/widget/"$direction"-line
    fi
  elif [[ $_ble_decode_keymap == nsearch ]]; then
    ble/widget/nsearch/"$direction"
  else
    ble/widget/history-search-"$direction" \
      hide-status:immediate-accept:point=end:blerc-line-history
  fi
}

function blerc/history-keybindings {
  local keymap
  for keymap in vi_imap vi_nmap nsearch; do
    ble-bind -m "$keymap" -f up 'blerc/line-or-history backward'
    ble-bind -m "$keymap" -f down 'blerc/line-or-history forward'
  done
}
blehook/eval-after-load keymap_vi blerc/history-keybindings
