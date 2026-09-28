# POSIX environment for login shells and, on athena, for the graphical session
# (the port's ~/.config/uwsm/env sources this file). Per-host PATH additions and
# work variables go in ~/.profile.local, which is not tracked.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -f "$HOME/.profile.local" ] && . "$HOME/.profile.local"
