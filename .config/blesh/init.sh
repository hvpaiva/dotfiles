# Per-host tweaks (BLESH_HOST_LABEL for the prompt), from hosts/<host>
[[ -f ~/.config/blesh/local.sh ]] && source ~/.config/blesh/local.sh

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

if command -v fzf &>/dev/null; then
  # Ubuntu ships fzf's completion.bash as bash-completion's loader for the fzf command
  # alone, so the ** trigger is not set up until something completes `fzf`
  if ! declare -F _fzf_complete >/dev/null && [[ -r /usr/share/bash-completion/completions/fzf ]]; then
    source /usr/share/bash-completion/completions/fzf
  fi
  ble-import -d integration/fzf-completion
  ble-import -d -C blerc/vi-keybindings integration/fzf-key-bindings
fi

# Context-aware inline suggestions (~/dev/personal/augur), after everything that sets up completion.
if [[ -f ~/dev/personal/augur/shell/augur.bash ]]; then
  source ~/dev/personal/augur/shell/augur.bash
  # Up to 800 ms for the language model, where the augur build has the option
  [[ ${bleopt_augur_model_timeout+set} ]] && bleopt augur_model_timeout=800
fi
