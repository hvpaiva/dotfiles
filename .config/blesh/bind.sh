# Custom ble.sh key bindings
bind 'set menu-complete-display-prefix off'

# Move within the command (including wrapped lines), then search at its edges.
# The _ble_* variables are provided by the running ble.sh editor.
# shellcheck disable=SC2154
function ble/widget/blerc/line-or-history {
  local direction=$1 can_move='' index count
  ble/history/get-index -v index
  ble/history/get-count -v count

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
  elif ((index < count)) || [[ $_ble_edit_str == *$'\n'* ]]; then
    # Only the line being typed searches for the text before the cursor: a recalled
    # entry or a multi-line command steps to the neighbouring entry.
    if [[ $_ble_decode_keymap == vi_nmap ]]; then
      ble/widget/vi-command/"$direction"-line
    else
      ble/widget/"$direction"-line history
    fi
  else
    # history_share reads other sessions' commands only after the search has picked its
    # entry; read them first so it starts from the newest command.
    [[ $bleopt_history_share ]] && history -n
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

# Ubuntu's fzf 0.44 key bindings, imported from readline, map C-z to emacs-editing-mode,
# C-r in normal mode to fzf and M-c to a C-z macro. In vi mode C-z resumes the last
# suspended job (ble.sh's default), C-r redoes, and M-c (fzf cd) is unbound: Esc followed
# quickly by c arrives as M-c. Runs again after fzf's integration, which rebinds C-r and M-c.
function blerc/vi-keybindings {
  ble-bind -m vi_imap -c C-z fg
  ble-bind -m vi_nmap -c C-z fg
  ble-bind -m vi_nmap -f C-r vi_nmap/redo
  ble-bind -m vi_imap -f M-c -
  ble-bind -m vi_nmap -f M-c -
}
blehook/eval-after-load keymap_vi blerc/vi-keybindings
