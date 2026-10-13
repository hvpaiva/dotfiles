#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../functions"
  mkdir -p "$BATS_TEST_TMPDIR/bin" "$BATS_TEST_TMPDIR/work"
  cat >"$BATS_TEST_TMPDIR/bin/satori" <<'BASH'
#!/usr/bin/env bash
[[ $1 == init ]] || exit 2
dir=${2:-dojo}
if [[ -e $dir && -n $(ls -A "$dir") ]]; then
  echo "$dir is not empty" >&2
  exit 2
fi
mkdir -p "$dir/.satori" "$dir/unit"
BASH
  chmod +x "$BATS_TEST_TMPDIR/bin/satori"
  PATH=$BATS_TEST_TMPDIR/bin:$PATH
  work=$BATS_TEST_TMPDIR/work
  builtin cd "$work" || return
}

@test "init creates the dojo and enters it" {
  sat init
  [[ $PWD == "$work/dojo" ]]
  [[ -d $work/dojo/.satori ]]
}

@test "restart from inside the dojo rebuilds it in place instead of nesting a new one" {
  sat init
  touch "$work/dojo/unit/progress.rb"
  builtin cd unit
  sat restart
  [[ $PWD == "$work/dojo" ]]
  [[ -d $work/dojo/.satori ]]
  [[ ! -e $work/dojo/unit/progress.rb ]]
  [[ ! -e $work/dojo/dojo ]]
}

@test "restart without a dojo behaves like init" {
  sat restart
  [[ $PWD == "$work/dojo" ]]
}

@test "reset from inside the dojo removes it and leaves the shell in the parent" {
  sat init
  sat reset
  [[ $PWD == "$work" ]]
  [[ ! -e $work/dojo ]]
}

@test "reset without a dojo is a no-op" {
  sat reset
  [[ $PWD == "$work" ]]
}

@test "reset refuses a dojo directory that satori did not create" {
  mkdir dojo
  touch dojo/keep
  run sat reset
  [[ $status -eq 1 ]]
  [[ $output == *"not a satori dojo"* ]]
  [[ -e $work/dojo/keep ]]
}

@test "a failed init leaves the shell where it was" {
  sat init
  builtin cd unit
  local result=0
  sat init 2>/dev/null || result=$?
  [[ $result -eq 2 ]]
  [[ $PWD == "$work/dojo/unit" ]]
}

@test "an unknown command prints usage" {
  run sat
  [[ $status -eq 2 ]]
  [[ $output == usage:* ]]
}
