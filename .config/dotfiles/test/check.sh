#!/usr/bin/env bash
# Shared by CI and dots check/save. Check the supplied tree without sourcing its configs.
set -euo pipefail
shopt -s nullglob
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
mode=${1:-all}
case $mode in lint | unit | all) ;; *) echo "usage: check.sh [lint|unit|all]" >&2; exit 2 ;; esac

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "validation requires $1; install it and retry dots check" >&2
    exit 1
  }
}

if [[ $mode != unit ]]; then
  need shellcheck
  shell_files=("$root/bootstrap.sh" "$root/.local/bin/dots")
  bash_files=("$root/.bashrc" "$root/.bash_profile")
  ruby_files=()
  executable_files=("${shell_files[@]}")
  for f in "$root"/.config/dotfiles/test/*.sh "$root"/.config/git/hooks/* "$root"/.config/scripts/*; do
    [[ -f $f ]] || continue
    shell_files+=("$f")
    [[ $f == *.sh ]] || executable_files+=("$f")
  done
  for f in "$root"/.config/bash/* "$root"/.config/blesh/*.sh "$root/.local/share/bash-completion/completions/dots"; do
    [[ -f $f ]] || continue
    case $f in
      *.rb) ruby_files+=("$f") ;;
      *) bash_files+=("$f") ;;
    esac
  done
  ruby_files+=("$root"/.config/bash/tests/*.rb)
  shellcheck -S warning -e SC1090,SC1091 "${shell_files[@]}"
  shellcheck -S warning -e SC1090,SC1091 -s bash "${bash_files[@]}"
  shellcheck -S warning -e SC1090,SC1091 -s sh "$root/.profile"
  for f in "${shell_files[@]}" "${bash_files[@]}"; do bash -n "$f"; done
  sh -n "$root/.profile"
  if ((${#ruby_files[@]})); then
    need ruby
    for f in "${ruby_files[@]}"; do ruby -c "$f"; done
  fi
  for f in "${executable_files[@]}"; do
    [[ -x $f ]] || { echo "not executable: ${f#"$root/"}" >&2; exit 1; }
  done
fi

if [[ $mode != lint ]]; then
  need bats
  bats "$root/.config/dotfiles/test"
  # The shell's own tests skip what needs a tool this machine lacks (tmux, ble.sh, rich-ri...)
  shell_tests=("$root"/.config/bash/tests/*.bats)
  if ((${#shell_tests[@]})); then
    bats "${shell_tests[@]}"
  fi
fi
