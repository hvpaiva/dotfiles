#
# ~/.bash_profile — bash reads this instead of ~/.profile on login, so source it first
# (PATH and POSIX env, including the per-host ~/.profile.local), then the interactive rc.
#
[[ -f ~/.profile ]] && . ~/.profile
[[ -f ~/.bashrc ]] && . ~/.bashrc
