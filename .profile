# POSIX environment for login shells and, on athena, for the graphical session
# (the port's ~/.config/uwsm/env sources this file). Per-host additions live in
# ~/.profile.local (public per-host layer) and ~/.profile.private (private repo).
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -d "$HOME/go/bin" ] && export PATH="$HOME/go/bin:$PATH"
[ -f "$HOME/.profile.local" ] && . "$HOME/.profile.local"
[ -f "$HOME/.profile.private" ] && . "$HOME/.profile.private"
