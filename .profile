# POSIX environment for login shells and, on athena, for the graphical session
# (the port's ~/.config/uwsm/env sources this file). Per-host additions live in
# ~/.profile.local (public per-host layer) and ~/.profile.private (private repo).
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
if [ -d "$HOME/.local/share/mise/shims" ]; then
  case "$PATH" in
    "$HOME/.local/share/mise/shims:"*) ;;
    *) export PATH="$HOME/.local/share/mise/shims:$PATH" ;;
  esac
fi
# go install targets; after mise, which owns the tools both could provide
case ":$PATH:" in *":$HOME/go/bin:"*) ;; *) [ -d "$HOME/go/bin" ] && export PATH="$PATH:$HOME/go/bin" ;; esac
# dots and the mise build live in ~/.local/bin; Omarchy appends it too, this covers hosts without it
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$PATH:$HOME/.local/bin" ;; esac
[ -f "$HOME/.profile.local" ] && . "$HOME/.profile.local"
[ -f "$HOME/.profile.private" ] && . "$HOME/.profile.private"
