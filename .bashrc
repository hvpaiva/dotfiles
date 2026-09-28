# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions (absent on a plain server or container)
# (don't mess with these directly, just overwrite them in ~/.config/bash/)
[[ -n ${OMARCHY_PATH-} && -r $OMARCHY_PATH/default/bash/rc ]] && source "$OMARCHY_PATH/default/bash/rc"

# Only what diverges from those defaults
source ~/.config/bash/rc

# rustup's PATH entry; guarded internally against duplicates
[[ -f ~/.cargo/env ]] && . "$HOME/.cargo/env"

# Line editor. Loads last so it imports the readline state set above.
[[ -f ~/.local/share/blesh/ble.sh ]] && source -- ~/.local/share/blesh/ble.sh
