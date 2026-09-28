# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them in ~/.config/bash/)
source "$OMARCHY_PATH/default/bash/rc"

# Only what diverges from those defaults
source ~/.config/bash/rc

# rustup's PATH entry; guarded internally against duplicates
. "$HOME/.cargo/env"

# Line editor. Loads last so it imports the readline state set above.
source -- ~/.local/share/blesh/ble.sh
