# POSIX environment for login shells and, on athena, for the graphical session
# (the port's ~/.config/uwsm/env sources this file). Per-host additions live in
# ~/.profile.local (public per-host layer) and ~/.profile.private (private repo).
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -d "$HOME/go/bin" ] && export PATH="$HOME/go/bin:$PATH"
# dots and the mise build live in ~/.local/bin; Omarchy appends it too, this covers hosts without it
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$PATH:$HOME/.local/bin" ;; esac
[ -f "$HOME/.profile.local" ] && . "$HOME/.profile.local"
[ -f "$HOME/.profile.private" ] && . "$HOME/.profile.private"
