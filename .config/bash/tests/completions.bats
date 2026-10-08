#!/usr/bin/env bats

setup_file() {
  [[ -r /usr/share/bash-completion/bash_completion ]] || skip "bash-completion not installed"
}

setup() {
  export LC_ALL=C
  source /usr/share/bash-completion/bash_completion
  completions=$BATS_TEST_DIRNAME/../../../.local/share/bash-completion/completions
  cd "$BATS_TEST_TMPDIR" || return
}

probe() {
  COMP_WORDS=("$@")
  COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
  COMP_LINE="${COMP_WORDS[*]}"
  COMP_POINT=${#COMP_LINE}
  COMPREPLY=()
  local function
  function=$(complete -p "$1" | sed -E 's/.*-F ([^ ]+) .*/\1/')
  "$function" "$1" "${COMP_WORDS[-1]}" "${COMP_WORDS[-2]}" 2>"$BATS_TEST_TMPDIR/stderr" || :
}

has_candidate() {
  local candidate
  for candidate in "${COMPREPLY[@]}"; do
    [[ $candidate == "$1" ]] && return 0
  done
  printf 'Missing candidate %s in %s\n' "$1" "${COMPREPLY[*]}" >&2
  return 1
}

no_errors() {
  local outside_completion='compopt: not currently executing completion function' errors
  errors=$(grep -v "$outside_completion" "$BATS_TEST_TMPDIR/stderr" || :)
  [[ -z $errors ]] || { printf '%s\n' "$errors" >&2; return 1; }
}

@test "go completes commands, subcommands, flags and packages" {
  command -v go >/dev/null || skip "go not installed"
  source "$completions/go"
  mkdir pkg
  probe go bu
  no_errors
  has_candidate build
  probe go mod ''
  has_candidate tidy
  probe go build -
  has_candidate -race
  probe go build ''
  has_candidate ./...
  has_candidate pkg
  probe go env GOPA
  has_candidate GOPATH
}

@test "ollama completes subcommands and flags" {
  source "$completions/ollama"
  probe ollama r
  no_errors
  has_candidate run
  has_candidate rm
  probe ollama run --verb
  has_candidate --verbose
}

@test "pkexec completes commands, users and the wrapped command" {
  command -v systemctl >/dev/null || skip "systemctl not installed"
  source "$completions/pkexec"
  probe pkexec systemct
  no_errors
  has_candidate systemctl
  probe pkexec --user ro
  has_candidate root
  probe pkexec systemctl resta
  has_candidate restart
}
