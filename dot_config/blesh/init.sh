function blerc/define-sabbrev-date {
  ble-sabbrev -m '\date'='ble/util/assign COMPREPLY "date +%F"'
}
blehook/eval-after-load complete blerc/define-sabbrev-date

# Prompt:
# <dir>
# $
PS1='\e[33m\n\w\n\e[32m\$ '

# enables and configures vi mode
# this script overrides the PS1
source ~/.config/blesh/vi.sh

# Transient mode 
bleopt prompt_ps1_transient=always:trim

# Disable EOF marker like "[ble: EOF]"
bleopt prompt_eol_mark='' 

# Disable exit marker like "[ble: exit]"
bleopt exec_exit_mark=

# Disable some other markers like "[ble: ...]"
bleopt edit_marker=
bleopt edit_marker_error=

# Show the exit code when error, like:
# [1]
bleopt exec_errexit_mark=$'\e[91m[%d]\e[m'

# Share the command history with other bash sessions
bleopt history_share=1

# ble other options
source ~/.config/blesh/bind.sh
source ~/.config/blesh/theme.sh

# Set up fzf
ble-import -d integration/fzf-completion
ble-import -d integration/fzf-key-bindings
