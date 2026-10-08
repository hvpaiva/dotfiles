#!/usr/bin/env bats

setup_file() {
  command -v tmux >/dev/null || skip "tmux not installed"
  [[ -f $HOME/.local/share/blesh/ble.sh ]] || skip "ble.sh not installed"
  E2E_SOCKET=$BATS_FILE_TMPDIR/tmux.sock
  E2E_CACHE=$BATS_FILE_TMPDIR/cache
  mkdir -p "$E2E_CACHE"
  printf '%s\n' 'mapfile -t env <"$1"' 'exec env -i "${env[@]}" bash -i' >"$BATS_FILE_TMPDIR/launch"
  export E2E_SOCKET E2E_CACHE
  work=$BATS_FILE_TMPDIR/warmup state=$BATS_FILE_TMPDIR/warmup/state session=warmup
  mkdir -p "$state"/{augur,state,zoxide}
  mkdir -m 700 "$state/run"
  : >"$state/history"
  start_shell
  sleep 2
  t send-keys -t "$session" -l exit
  t send-keys -t "$session" Enter
  sleep 0.5
}

teardown_file() {
  tmux -S "$E2E_SOCKET" kill-server 2>/dev/null || :
}

setup() {
  work=$BATS_TEST_TMPDIR
  state=$BATS_TEST_TMPDIR/state
  mkdir -p "$state"/{augur,state,zoxide}
  mkdir -m 700 "$state/run"
  : >"$state/history"
  session=t$BATS_TEST_NUMBER
}

teardown() {
  tmux -S "$E2E_SOCKET" kill-session -t "$session" 2>/dev/null || :
}

t() { tmux -S "$E2E_SOCKET" "$@"; }

start_shell() {
  printf '%s\n' "HOME=$HOME" "USER=$USER" "PATH=$PATH" LANG=C.UTF-8 TERM=xterm-256color \
    "XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}" "XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}" \
    "HISTFILE=$state/history" "XDG_CACHE_HOME=$E2E_CACHE" "XDG_STATE_HOME=$state/state" \
    "XDG_RUNTIME_DIR=$state/run" "AUGUR_STATE_DIR=$state/augur" "_ZO_DATA_DIR=$state/zoxide" \
    >"$work/env"
  t -f /dev/null new-session -d -s "$session" -x 100 -y 25 -c "$work" \
    bash "$BATS_FILE_TMPDIR/launch" "$work/env"
  wait_for caret
}

screen() { t capture-pane -p -e -t "$session"; }
current_line() { screen | grep -v '^$' | tail -1; }
prompt_line() { screen | grep $'^\e\\[9[1-5]m\\$ ' | tail -1; }
caret() { current_line | grep -q $'^\e\\[9[1-5]m\\$ '; }
normal_mode() { prompt_line | grep -q $'^\e\\[95m\\$ '; }
shows() { t capture-pane -p -t "$session" | grep -q -- "$1"; }

wait_for() {
  local i
  for ((i = 0; i < 100; i++)); do
    "$@" && return 0
    sleep 0.05
  done
  screen | cat -v >&2
  return 1
}

type_text() {
  local text=$1
  [[ $text == *';' ]] && text=${text%;}'\;'
  t send-keys -t "$session" -l -- "$text"
}

press() { t send-keys -t "$session" "$@"; }

cursor_row() { t display -p -t "$session" '#{cursor_y}'; }
on_row() { (($(cursor_row) == $1)); }
cursor_is() { [[ $(t display -p -t "$session" '#{cursor_shape}') == "$1" ]]; }

type_multiline() {
  type_text 'for i in 1 2; do'
  press Enter
  type_text 'echo "$i"'
  press Enter
  type_text 'done'
  wait_for shows '^done$'
}

@test "a new shell starts without error output" {
  start_shell
  sleep 0.5
  run shows 'bash:'
  [ "$status" -eq 1 ]
}

@test "the caret stays on the prompt when the window is resized during a history search" {
  printf '%s\n' 'echo from-history' >"$state/history"
  start_shell
  press Up
  wait_for shows from-history
  t resize-window -t "$session" -x 90 -y 25
  sleep 0.5
  wait_for caret
}

@test "Esc reaches normal mode without waiting for readline's key timeout" {
  start_shell
  type_text 'echo x'
  local start=$EPOCHREALTIME
  press Escape
  wait_for normal_mode
  local elapsed=$(( (${EPOCHREALTIME/[.,]/} - ${start/[.,]/}) / 1000 ))
  ((elapsed < 400)) || { echo "Esc took ${elapsed} ms" >&2; return 1; }
}

@test "the terminal keeps its own cursor in every vi mode" {
  start_shell
  type_text 'echo x'
  sleep 0.3
  cursor_is default
  press Escape
  wait_for normal_mode
  cursor_is default
  press v
  sleep 0.3
  cursor_is default
}

@test "C-z at the prompt leaves the editor in vi mode" {
  start_shell
  press C-z
  sleep 0.5
  type_text 'echo after'
  press Enter
  wait_for shows '^after'
  type_text 'echo x'
  press Escape
  wait_for normal_mode
}

@test "Esc followed at once by c changes text instead of running Alt-C" {
  start_shell
  type_text 'echo abc'
  sleep 0.3
  press Escape c c
  type_text 'echo changed'
  wait_for shows '^\$ echo changed$'
  run shows 'echo abc'
  [ "$status" -eq 1 ]
}

@test "C-r in normal mode redoes" {
  start_shell
  sleep 1
  type_text 'echo one two'
  sleep 0.5
  press Escape
  wait_for normal_mode
  sleep 0.5
  press 0 d w
  wait_for shows '^\$ one two$'
  press u
  wait_for shows '^\$ echo one two$'
  press C-r
  wait_for shows '^\$ one two$'
}

@test "Up moves through the lines of a multi-line command, then to the previous entry" {
  printf '%s\n' 'echo previous' >"$state/history"
  start_shell
  type_multiline
  local last
  last=$(cursor_row)
  press Up
  wait_for on_row $((last - 1))
  press Up
  wait_for on_row $((last - 2))
  press Up
  wait_for shows '^\$ echo previous$'
  run shows 'done'
  [ "$status" -eq 1 ]
}

@test "gg and G move to the first and last line of the command" {
  printf '%s\n' 'echo previous' >"$state/history"
  start_shell
  type_multiline
  local last
  last=$(cursor_row)
  press Escape
  wait_for normal_mode
  press g g
  wait_for on_row $((last - 2))
  press G
  wait_for on_row "$last"
  run shows 'previous'
  [ "$status" -eq 1 ]
}

@test "an alias completes as the command it expands to" {
  command -v git >/dev/null || skip "git not installed"
  start_shell
  type_text 'alias gx=git'
  press Enter
  sleep 0.3
  type_text 'gx chec'
  press Tab
  wait_for shows 'gx checkout'
}
