#!/usr/bin/env bats
# Bats' `[ ]` assertions are its idiom; ~/.config/shellcheckrc asks for `[[ ]]` in Bash.
# shellcheck disable=SC2292
# Unit tests for the logic in ~/.local/bin/dots: pure helpers, and the git-backed
# helpers against throwaway repositories. Nothing here touches the network, the
# real $HOME or sudo. Run with: bats ~/.config/dotfiles/test

setup_file() {
  # Tests replace HOME, so mise shims would lose their config/trust state. Keep
  # the active binaries on PATH and the running Bats installation for nested tests.
  local dir shims=${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims
  local -a dirs
  IFS=: read -r -a dirs <<<"$PATH"
  PATH=$BATS_ROOT/bin
  for dir in "${dirs[@]}"; do
    [[ $dir == "$shims" ]] || PATH+=:$dir
  done
  export PATH
}

setup() {
  # Never inherit terminal input: run captures prompts and would hide a waiting read.
  # Tests that exercise input provide it explicitly (for example, with a here-string).
  exec </dev/null
  export HOME=$BATS_TEST_TMPDIR/home
  mkdir -p "$HOME"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  # shellcheck disable=SC1090
  source "$BATS_TEST_DIRNAME/../../../.local/bin/dots"
  hostname() { printf testhost; }
}

# a commit in DIR (init if needed), touching FILE
commit() { # DIR FILE MESSAGE
  [[ -d $1/.git ]] || { mkdir -p "$1" && git -C "$1" init -q -b main; }
  printf '%s\n' "$3" >"$1/$2"
  git -C "$1" add -A && git -C "$1" commit -q -m "$3"
}
# origin (bare) + the bare dotfiles clone with $HOME as work tree, like the bootstrap
make_public() {
  local src=$BATS_TEST_TMPDIR/src
  # like the real whitelist: the git dir and the nvim clone are not the dotfiles repo's business
  mkdir -p "$src"; printf '/.dotfiles/\n/.config/nvim/\n' >"$src/.gitignore"
  commit "$src" .bashrc "initial"
  git -C "$src" branch -m main
  git clone -q --bare "$src" "$BATS_TEST_TMPDIR/origin.git"
  git -C "$src" remote add origin "$BATS_TEST_TMPDIR/origin.git"
  git clone -q --bare "$BATS_TEST_TMPDIR/origin.git" "$PUBLIC_GIT_DIR"
  repo_git public config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  repo_git public reset -q --hard HEAD
  repo_git public fetch -q origin
  repo_git public branch -q --set-upstream-to=origin/main main
}
make_nvim() {
  commit "$NVIM_DIR" init.lua "nvim initial"
}
record() { repo_git public update-index --add --cacheinfo "160000,$(repo_git nvim rev-parse HEAD),$NVIM_PATH"; }

@test "change_state maps porcelain codes" {
  [ "$(change_state '??')" = untracked ]
  [ "$(change_state ' M')" = modified ]
  [ "$(change_state 'M ')" = modified ]
  [ "$(change_state 'D ')" = deleted ]
  [ "$(change_state 'A ')" = added ]
  [ "$(change_state 'R ')" = renamed ]
  [ "$(change_state 'UU')" = conflict ]
}

@test "default_message names up to three files" {
  [ "$(default_message ' M .config/bash/aliases')" = "chore: update aliases" ]
  [ "$(default_message $' M a/one\n?? b/two\nR  old -> c/three')" = "chore: update one, two, three" ]
  [ "$(default_message $' M 1\n M 2\n M 3\n M 4\n M 5')" = "chore: update 1, 2, 3 and 2 more" ]
}

@test "theme_name strips the omarchy prefix and theme suffix" {
  [ "$(theme_name git@github.com:x/omarchy-all-hallows-eve-theme.git)" = all-hallows-eve ]
  [ "$(theme_name https://github.com/x/omarchy-rose-pine-dark)" = rose-pine-dark ]
  [ "$(theme_name https://github.com/x/omarchy-monokai-theme)" = monokai ]
}

@test "origin_text phrases the ahead/behind counts" {
  st_branch=main st_upstream=origin/main st_ahead=0 st_behind=0
  [ "$(origin_text)" = "in sync" ]
  st_ahead=2; [ "$(origin_text)" = "2 to push" ]
  st_ahead=0 st_behind=3; [ "$(origin_text)" = "3 behind" ]
  st_ahead=1; [ "$(origin_text)" = "diverged 1/3" ]
  st_upstream=''; [ "$(origin_text)" = "no upstream" ]
  st_branch=detached; [ "$(origin_text)" = "detached HEAD" ]
}

@test "cell_colour reads N/M as all in place or not" {
  c_g=G c_y=Y
  [ "$(cell_colour 6/6 0)" = G ]
  [ "$(cell_colour 5/6 0)" = Y ]
  [ "$(cell_colour '6/6, x replaced' 0)" = Y ]
}

@test "table aligns columns and pads short rows" {
  run table <<<"$(row NAME STATE; row alpha ok; row b 'two words')"
  [ "${lines[0]}" = "NAME    STATE       " ]
  [ "${lines[1]}" = "alpha   ok          " ]
  [ "${lines[2]}" = "b       two words   " ]
}

@test "detect_os reads the family from os-release" {
  export DOTS_OS_RELEASE=$BATS_TEST_TMPDIR/os
  printf 'ID=omarchy\nID_LIKE=arch\n' >"$DOTS_OS_RELEASE"; detect_os
  [ "$os" = arch ] && [ "${DROP[0]}" = herdr ]
  printf 'ID=ubuntu\n' >"$DOTS_OS_RELEASE"; detect_os
  [ "$os" = ubuntu ] && [ "${DROP[0]}" = mise ]
  printf 'ID=manjaro\nID_LIKE="arch"\n' >"$DOTS_OS_RELEASE"; detect_os
  [ "$os" = arch ]
  printf 'ID=fedora\n' >"$DOTS_OS_RELEASE"; detect_os
  [ "$os" = other ] && [ "${#DROP[@]}" -eq 0 ]
}

@test "host_name prefers the marker over hostname" {
  host_name; [ "$host" = testhost ]
  mkdir -p "$(dirname "$HOST_FILE")"; printf 'zeus\n' >"$HOST_FILE"
  host_name; [ "$host" = zeus ]
}

@test "link_tree links, keeps, and adopts a live file that replaced a link" {
  local root=$HOSTS_DIR/testhost
  mkdir -p "$root/.config/app"; printf 'repo\n' >"$root/.config/app/conf"
  host_name
  link_tree "$root" hosts/testhost
  [ "$lt_linked" -eq 1 ] && [ -L "$HOME/.config/app/conf" ]
  link_tree "$root" hosts/testhost
  [ "$lt_kept" -eq 1 ] && [ "$lt_linked" -eq 0 ]
  rm "$HOME/.config/app/conf"; printf 'live\n' >"$HOME/.config/app/conf"
  run link_tree "$root" hosts/testhost
  [[ $output == *"adopted the live .config/app/conf"* ]]
  [ "$(cat "$root/.config/app/conf")" = live ] && [ -L "$HOME/.config/app/conf" ]
}

@test "link_all removes a link into a tree whose file went away, nothing else" {
  local root=$HOSTS_DIR/testhost
  mkdir -p "$root/.config/app" "$HOME/.config/other"; printf 1 >"$root/.config/app/a"; printf 1 >"$root/.config/app/b"
  host_name
  link_all 1
  [ "$la_ok" -eq 2 ] && [ -L "$HOME/.config/app/b" ]
  ln -s "$HOME/nowhere" "$HOME/.config/other/foreign"   # dangling, not made by dots
  rm "$root/.config/app/b"
  link_state
  [ "$lk_stale" -eq 1 ] && [[ $(links_text) == "1/1, .config/app/b stale" ]]
  run link_all 0
  [[ $output == *"removed the stale .config/app/b"* ]] && [[ $output == *"1 stale removed"* ]]
  [ ! -L "$HOME/.config/app/b" ] && [ -L "$HOME/.config/app/a" ] && [ -L "$HOME/.config/other/foreign" ]
  link_state
  [ "$lk_stale" -eq 0 ]
}

@test "link_state counts links in place, replaced and missing" {
  local root=$HOSTS_DIR/testhost
  mkdir -p "$root/a" "$HOME/a"; printf 1 >"$root/a/ok"; printf 1 >"$root/a/replaced"; printf 1 >"$root/a/missing"
  host_name
  ln -s "$root/a/ok" "$HOME/a/ok"; printf 2 >"$HOME/a/replaced"
  link_state
  [ "$lk_ok" -eq 1 ] && [ "$lk_replaced" -eq 1 ] && [ "$lk_missing" -eq 1 ]
  [[ $(links_text) == "1/3, "* ]] && [[ $(links_text) == *"a/replaced replaced"* ]]
}

@test "themes_missing and tmux_plugins_missing read the config files" {
  mkdir -p "$HOME/.config/omarchy/themes/monokai" "$HOME/.config/tmux" "$TPM_DIR/tpm"
  printf '# c\nhttps://github.com/x/omarchy-monokai-theme\nhttps://github.com/x/omarchy-darcula-theme\n' >"$HOME/.config/omarchy/themes.txt"
  [ "$(themes_missing)" = "https://github.com/x/omarchy-darcula-theme" ]
  printf 'set -g @plugin "tmux-plugins/tpm"\nset -g @plugin "tmux-plugins/tmux-yank"\n' >"$HOME/.config/tmux/extras.conf"
  [ "$(tmux_plugins | wc -l)" -eq 2 ]
  [ "$(tmux_plugins_missing)" = tmux-yank ]
}

@test "missing_pkgs and installed_pkgs go through the distro tool" {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  printf '#!/bin/sh\ncase "$1" in -T) shift; for p; do [ "$p" = present ] || echo "$p"; done ;; -Qq) shift; for p; do [ "$p" = present ] && echo "$p"; done ;; esac\n' >"$BATS_TEST_TMPDIR/bin/pacman"
  chmod +x "$BATS_TEST_TMPDIR/bin/pacman"; PATH=$BATS_TEST_TMPDIR/bin:$PATH
  os=arch
  [ "$(missing_pkgs present absent)" = absent ]
  [ "$(installed_pkgs present absent)" = present ]
}

@test "repo_state and origin_text on a real repo: clean, ahead, behind" {
  make_public
  repo_state public
  [ "$st_branch" = main ] && [ "$st_n" -eq 0 ] && [ "$(origin_text)" = "in sync" ]
  printf 'x\n' >"$HOME/.bashrc"; printf 'new\n' >"$HOME/.new"
  repo_state public
  [ "$st_n" -eq 2 ] && [[ $st_changes == *"?? .new"* ]]
  repo_git public add -A && repo_git public commit -q -m "local"
  repo_state public; [ "$(origin_text)" = "1 to push" ]
  commit "$BATS_TEST_TMPDIR/src" other "upstream moved"
  git -C "$BATS_TEST_TMPDIR/src" push -q origin main
  repo_git public fetch -q origin
  repo_state public; [ "$(origin_text)" = "diverged 1/1" ]
}

@test "repo_update fast-forwards, keeps a local edit, refuses to diverge" {
  make_public
  commit "$BATS_TEST_TMPDIR/src" other "upstream moved"
  git -C "$BATS_TEST_TMPDIR/src" push -q origin main
  printf 'edited\n' >"$HOME/.bashrc"
  repo_git public fetch -q origin
  run repo_update public 0
  [[ $output == *"1 new commit(s)"* ]]
  [ -f "$HOME/other" ] && [ "$(cat "$HOME/.bashrc")" = edited ]
  repo_git public add -A && repo_git public commit -q -m "local"
  commit "$BATS_TEST_TMPDIR/src" more "upstream moved again"
  git -C "$BATS_TEST_TMPDIR/src" push -q origin main
  repo_git public fetch -q origin
  run repo_update public 0
  [ "$status" -eq 1 ] && [[ $output == *"cannot fast-forward"* ]]
}

@test "nvim_pointer_state follows the recorded commit" {
  make_public; make_nvim
  [ "$(nvim_pointer_state)" = none ]
  record; [ "$(nvim_pointer_state)" = same ]
  commit "$NVIM_DIR" more "nvim moved"
  [ "$(nvim_pointer_state)" = ahead ]
  git -C "$NVIM_DIR" reset -q --hard HEAD~1
  record; commit "$NVIM_DIR" more "nvim moved"; record
  git -C "$NVIM_DIR" reset -q --hard HEAD~1
  [ "$(nvim_pointer_state)" = behind ]
  commit "$NVIM_DIR" elsewhere "nvim diverged"
  [ "$(nvim_pointer_state)" = diverged ]
  repo_git public update-index --add --cacheinfo "160000,0000000000000000000000000000000000000001,$NVIM_PATH"
  [ "$(nvim_pointer_state)" = unknown ]
}

@test "record_nvim stages the live commit only when it moved forward" {
  make_public; make_nvim
  run record_nvim
  [[ $output == *"recorded"* ]]
  [ "$(repo_git public ls-files -s "$NVIM_PATH" | awk '{print $2}')" = "$(git -C "$NVIM_DIR" rev-parse HEAD)" ]
  commit "$NVIM_DIR" more "nvim moved"
  record_nvim >/dev/null
  git -C "$NVIM_DIR" reset -q --hard HEAD~1
  run record_nvim
  [[ $output == *"older"* ]]
  [ "$(repo_git public ls-files -s "$NVIM_PATH" | awk '{print $2}')" != "$(git -C "$NVIM_DIR" rev-parse HEAD)" ]
}

@test "a live nvim commit ahead of the record is a dotfiles change, behind it is nvim behind record" {
  make_public; make_nvim
  repo_state public; [[ $st_changes == "A  .config/nvim" ]]
  record; repo_git public commit -q -m "record nvim"
  repo_state public; [ "$st_n" -eq 0 ]
  commit "$NVIM_DIR" more "nvim moved"
  repo_state public; [ "$st_n" -eq 1 ] && [[ $st_changes == "M  .config/nvim" ]]
  record; repo_git public commit -q -m "record nvim again"
  git -C "$NVIM_DIR" reset -q --hard HEAD~1
  repo_state public; [ "$st_n" -eq 0 ]
  repo_state nvim; [ "$(nvim_origin_text)" = "behind record" ]
}

@test "next_text names one command, in order, and what needs a hand" {
  nx_update=0 nx_save=0 nx_doctor=0 nx_hand=''
  [ "$(next_text)" = "nothing to do" ]
  nx_doctor=1; [ "$(next_text)" = "dots doctor" ]; nx_doctor=0
  next_note "in sync" 2 dotfiles; [ "$(next_text)" = "dots save" ]
  next_note "3 behind" 0 private; [ "$(next_text)" = "dots update, then dots save" ]
  next_note "diverged 1/2" 0 nvim; [ "$(next_text)" = "dots update, then dots save; by hand: nvim diverged 1/2" ]
  nx_update=0 nx_save=0 nx_doctor=0 nx_hand=''
  next_note "2 to push" 0 nvim; [ "$(next_text)" = "dots save" ]
}

@test "a recorded nvim commit counts as a dotfiles change until it is committed" {
  make_public; make_nvim
  repo_state public; [[ $st_changes == "A  .config/nvim" ]]
  record_nvim >/dev/null
  repo_state public
  [ "$st_n" -eq 1 ] && [[ $st_changes == "M  .config/nvim" ]]
  repo_git public commit -q -m "record nvim"
  repo_state public; [ "$st_n" -eq 0 ]
}

@test "root_hide keeps the root entries out of the work tree, root show brings them back" {
  make_public
  for f in README.md bootstrap.sh; do commit "$BATS_TEST_TMPDIR/src" "$f" "add $f"; done
  git -C "$BATS_TEST_TMPDIR/src" push -q origin main
  repo_git public fetch -q origin; repo_git public merge -q --ff-only origin/main
  [ -f "$HOME/README.md" ]
  ! root_hidden
  root_hide 1
  root_hidden
  [ ! -e "$HOME/README.md" ] && [ ! -e "$HOME/bootstrap.sh" ] && [ -f "$HOME/.bashrc" ]
  [ -z "$(repo_git public status --porcelain)" ]
  cmd_root show >/dev/null
  [ -f "$HOME/README.md" ]
  printf 'edited\n' >>"$HOME/README.md"
  run root_hide 1
  [ "$status" -eq 1 ]
  [[ $output == *"README.md changed: dots save first"* ]]
  [ -f "$HOME/README.md" ] && [ -f "$HOME/bootstrap.sh" ]
  [ "$(repo_git public ls-files -t README.md)" = "H README.md" ]
  repo_git public commit -q -am "edit README"
  root_hide 1
  root_hidden
}

# a pacman that knows dependencies: rust-src and rust-analyzer need rust, keep needs rust too
fake_pacman() { # INSTALLED…
  mkdir -p "$BATS_TEST_TMPDIR/bin"; printf '%s\n' "$@" >"$BATS_TEST_TMPDIR/installed"
  cat >"$BATS_TEST_TMPDIR/bin/pacman" <<'PM'
#!/usr/bin/env bash
db=${BATS_TEST_TMPDIR:?}/installed
case $1 in
  -Qq) shift; for p; do grep -qx "$p" "$db" && echo "$p"; done; exit 0 ;;
  -Rns) shift; [[ $1 == --noconfirm ]] && shift
    for p; do
      for d in rust-src rust-analyzer keep; do
        [[ $p == rust ]] && grep -qx "$d" "$db" && ! printf '%s\n' "$@" | grep -qx "$d" && { echo "removing rust breaks $d" >&2; exit 1; }
      done
    done
    for p; do grep -vx "$p" "$db" >"$db.tmp"; mv "$db.tmp" "$db"; done ;;
esac
PM
  chmod +x "$BATS_TEST_TMPDIR/bin/pacman"; PATH=$BATS_TEST_TMPDIR/bin:$PATH
  sudo() { [[ $1 == -n ]] && shift; "$@"; }
  os=arch
}

@test "step_drop_packages removes dependent packages in one transaction" {
  fake_pacman glow rust-src rust rust-analyzer other
  DROP=(glow rust-src rust rust-analyzer)
  run step_drop_packages
  [[ $output == *removed* ]]
  [ "$(cat "$BATS_TEST_TMPDIR/installed")" = other ]
}

@test "step_drop_packages falls back to one by one and reports what an outside package blocks" {
  fake_pacman glow rust keep
  DROP=(glow rust)
  run step_drop_packages
  [[ $output == *"still installed: rust"* ]]
  [ "$(tr '\n' ' ' <"$BATS_TEST_TMPDIR/installed")" = "rust keep " ]
}

@test "step_omarchy restores the tracked files the port bootstrap writes into" {
  make_public
  printf 'edited\n' >"$HOME/.bashrc"; printf 'new\n' >"$HOME/.newfile"   # dirty before the run: left alone
  export PORT_DIR=$BATS_TEST_TMPDIR/port; mkdir -p "$PORT_DIR"; git -C "$PORT_DIR" init -q
  printf '#!/bin/sh\nfor f in .gitignore .bashrc .newfile; do echo "# port block" >>"$HOME/$f"; done\n' >"$PORT_DIR/bootstrap.sh"
  chmod +x "$PORT_DIR/bootstrap.sh"; git -C "$PORT_DIR" add -A && git -C "$PORT_DIR" commit -q -m init
  os=ubuntu skip_omarchy=0
  run step_omarchy
  [[ $output == *"restored after the port's run: .gitignore"* ]]
  [ "$(cat "$HOME/.gitignore")" = $'/.dotfiles/\n/.config/nvim/' ]
  [ "$(cat "$HOME/.bashrc")" = $'edited\n# port block' ]
  [ "$(cat "$HOME/.newfile")" = $'new\n# port block' ]
}

fake_bashdb() { # RELEASE — a bashdb in ~/.local/bin that reports RELEASE, on stderr like the real one
  mkdir -p "$HOME/.local/bin"
  printf '#!/bin/sh\necho "bashdb, release %s" >&2\n' "$1" >"$BASHDB_BIN"
  chmod +x "$BASHDB_BIN"
}

@test "bashdb_state compares the installed release with the running bash" {
  bash_release() { printf 5.3; }
  bashdb_state
  [ "$bd_state" = missing ]
  fake_bashdb 5.3-1.2.0
  bashdb_state
  [ "$bd_state" = ok ] && [ "$bd_release" = 5.3-1.2.0 ]
  bash_release() { printf 5.4; }
  bashdb_state
  [ "$bd_state" = stale ] && [ "$bd_bash" = 5.4 ]
}

@test "step_bashdb keeps a build for this bash and fetches the branch of a new one" {
  have() { return 0; }
  git() { printf '%s\n' "$*" >>"$BATS_TEST_TMPDIR/git"; return 1; }
  STATE_DIR=$BATS_TEST_TMPDIR/state; mkdir -p "$STATE_DIR"
  fake_bashdb 5.3-1.2.0
  bash_release() { printf 5.3; }
  run step_bashdb
  [[ $output == *5.3-1.2.0* ]]
  [ ! -e "$BATS_TEST_TMPDIR/git" ]
  bash_release() { printf 5.4; }
  run step_bashdb
  [[ $output == *"no upstream branch for bash 5.4 yet"* ]]
  [[ $(cat "$BATS_TEST_TMPDIR/git") == *"-b bash-5.4 $BASHDB_REPO"* ]]
}

@test "mise_missing takes the first column of mise ls --missing" {
  mise() { printf 'node   24.1.0   ~/.config/mise/config.toml  latest\nbun    1.3.13\n'; }
  [ "$(mise_missing | tr '\n' ' ')" = "node bun " ]
}

tmux_fixture() {
  local binary=$HOME/.local/share/mise/installs/tmux/3.7c/tmux
  mkdir -p "${binary%/*}" "$HOME/.local/share/mise/shims" "$TPM_DIR/tpm" "$HOME/.config/tmux"
  cat >"$binary" <<'SH'
#!/bin/sh
case "$1" in
  -V) printf 'tmux 3.7c\n' ;;
  display-message)
    [ -n "${DOTS_TEST_SERVER_VERSION:-}" ] || exit 1
    printf '%s\n' "$DOTS_TEST_SERVER_VERSION" ;;
  *) exit 1 ;;
esac
SH
  chmod +x "$binary"
  cp "$binary" "$HOME/.local/share/mise/shims/tmux"
  printf 'set -g @plugin "tmux-plugins/tpm"\n' >"$HOME/.config/tmux/extras.conf"
  mise() {
    case "$*" in
      'current tmux') printf '3.7c\n' ;;
      'which tmux') printf '%s\n' "$HOME/.local/share/mise/installs/tmux/3.7c/tmux" ;;
      *) return 1 ;;
    esac
  }
  export PATH="$HOME/.local/share/mise/shims:$PATH"
}

@test "tmux check accepts the configured mise binary without a running server" {
  tmux_fixture
  checks_tmux
  [ "$chk_warns" -eq 0 ]
  [[ $chk_rows == *"tmux 3.7c, mise, tpm, 1 plugins"* ]]
}

@test "tmux check accepts mise activation without shims" {
  tmux_fixture
  PATH="$HOME/.local/share/mise/installs/tmux/3.7c:$PATH"
  checks_tmux
  [ "$chk_warns" -eq 0 ]
}

@test "tmux check warns when a distro binary shadows mise even at the same version" {
  tmux_fixture
  mkdir -p "$BATS_TEST_TMPDIR/system"
  cp "$HOME/.local/share/mise/shims/tmux" "$BATS_TEST_TMPDIR/system/tmux"
  PATH="$BATS_TEST_TMPDIR/system:$PATH"
  checks_tmux
  [ "$chk_warns" -eq 1 ]
  [[ $chk_rows == *"outside mise ($BATS_TEST_TMPDIR/system/tmux)"* ]]
}

@test "tmux check warns when the client does not match the configured version" {
  tmux_fixture
  sed -i 's/tmux 3.7c/tmux 3.4/' "$HOME/.local/share/mise/shims/tmux"
  checks_tmux
  [ "$chk_warns" -eq 1 ]
  [[ $chk_rows == *"tmux 3.4, expected 3.7c from mise"* ]]
}

@test "tmux check warns about an older running server" {
  tmux_fixture
  export DOTS_TEST_SERVER_VERSION=3.4
  checks_tmux
  [ "$chk_warns" -eq 1 ]
  [[ $chk_rows == *"server 3.4 differs from 3.7c"* ]]
}

@test "tmux check reports a missing mise installation" {
  mise() { return 1; }
  checks_tmux
  [ "$chk_warns" -eq 1 ]
  [[ $chk_rows == *"mise tmux not installed: dots update"* ]]
}

@test "tmux check still reports missing plugins" {
  tmux_fixture
  printf 'set -g @plugin "tmux-plugins/tmux-yank"\n' >>"$HOME/.config/tmux/extras.conf"
  checks_tmux
  [ "$chk_warns" -eq 1 ]
  [[ $chk_rows == *"plugins missing: tmux-yank"* ]]
}

@test "noninteractive bash prioritizes mise over distro binaries" {
  tmux_fixture
  export PATH="/usr/bin:/bin:$HOME/.local/share/mise/shims"
  run bash --noprofile --norc -c 'source "$1"; command -v tmux' bash "$BATS_TEST_DIRNAME/../../../.bashrc"
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.local/share/mise/shims/tmux" ]
}

@test "the login profile prioritizes mise without adding another entry on reload" {
  tmux_fixture
  export PATH="/usr/bin:/bin:$HOME/.local/share/mise/shims"
  run sh -c '. "$1"; first=$PATH; . "$1"; [ "$first" = "$PATH" ] && command -v tmux' sh "$BATS_TEST_DIRNAME/../../../.profile"
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.local/share/mise/shims/tmux" ]
}

# the backups setup, bootstrap.sh and the port leave behind, in a throwaway $HOME
make_backups() {
  mkdir -p "$STATE_DIR/pre-checkout-20260101-000000" "$STATE_DIR/nvim-1700000000" \
    "$HOME/.local/state/dotfiles-cleanup-20260927/bun" "$HOME/.config/hypr.bak-omarchy" "$HOME/.config/hypr"
  printf 'x\n' >"$HOME/.config/hypr/xdph.conf.bak-omarchy" >"$HOME/.config/hypr.bak-omarchy/xdph.conf.bak-omarchy"
  printf 'log\n' >"$STATE_DIR/setup.log"
  printf 'live\n' >"$HOME/.config/hypr/xdph.conf"
}

@test "backups finds the state folders and the port copies once, nothing else" {
  make_backups
  run backups
  [ "$status" -eq 0 ]
  [ "$output" = "$STATE_DIR/pre-checkout-20260101-000000
$STATE_DIR/nvim-1700000000
$HOME/.local/state/dotfiles-cleanup-20260927
$HOME/.config/hypr.bak-omarchy
$HOME/.config/hypr/xdph.conf.bak-omarchy" ]
}

@test "backups_text counts them and fails when there is none" {
  ! backups_text
  make_backups
  [[ $(backups_text) == "5, "* ]]
}

@test "clean lists and keeps without --all, removes with --all -y, leaves logs and live files" {
  make_backups
  run cmd_clean
  [ "$status" -eq 0 ]
  [[ $output == *"~/.config/hypr/xdph.conf.bak-omarchy"* ]]
  [[ $output == *"dots clean --all removes them"* ]]
  [ -d "$STATE_DIR/nvim-1700000000" ]
  run cmd_clean --all </dev/null
  [ "$status" -eq 1 ]
  [[ $output == *"no terminal"* ]]
  [ -d "$STATE_DIR/nvim-1700000000" ]
  run cmd_clean --all -y
  [ "$status" -eq 0 ]
  [ -z "$(backups)" ]
  [ -f "$STATE_DIR/setup.log" ] && [ -f "$HOME/.config/hypr/xdph.conf" ]
  run cmd_clean
  [ "$output" = "$(line backups none)" ]
}

@test "backup_age reports today or whole days" {
  mkdir -p "$STATE_DIR/nvim-1"
  [ "$(backup_age "$STATE_DIR/nvim-1")" = today ]
  touch -d '3 days ago' "$STATE_DIR/nvim-1"
  [ "$(backup_age "$STATE_DIR/nvim-1")" = 3d ]
}

@test "chromium_policy lists the shared and per-host ids once, comments dropped" {
  mkdir -p "$(dirname "$CHROMIUM_EXT")"
  printf 'aaaa  # one\n# a comment line\nbbbb\n' >"$CHROMIUM_EXT"
  printf 'bbbb\ncccc # host\n' >"$CHROMIUM_EXT_LOCAL"
  [ "$(chromium_ids | paste -sd,)" = "aaaa,bbbb,cccc" ]
  run chromium_policy
  [ "$output" = '{
  "ExtensionInstallForcelist": [
    "aaaa;https://clients2.google.com/service/update2/crx",
    "bbbb;https://clients2.google.com/service/update2/crx",
    "cccc;https://clients2.google.com/service/update2/crx"
  ]
}' ]
  python3 -c 'import json,sys; json.load(sys.stdin)' <<<"$output"
  CHROMIUM_POLICY=$BATS_TEST_TMPDIR/policy.json
  chromium_policy_state; [ "$cp_state" = missing ]
  chromium_policy >"$CHROMIUM_POLICY"
  chromium_policy_state; [ "$cp_state" = current ] && [ "$cp_n" -eq 3 ]
  printf 'dddd\n' >>"$CHROMIUM_EXT"
  chromium_policy_state; [ "$cp_state" = outdated ]
}

# 1Password, gh and tailscale as stubs: op answers fields from files, gh keeps its
# login and the keys it was given in files, tailscale is never running
make_secret_stubs() {
  mkdir -p "$BATS_TEST_TMPDIR/bin" "$BATS_TEST_TMPDIR/op"
  cat >"$BATS_TEST_TMPDIR/bin/op" <<'OP'
#!/usr/bin/env bash
case $1 in
  whoami) [[ -f ${BATS_TEST_TMPDIR:?}/op/unlocked ]] ;;
  read) f=${BATS_TEST_TMPDIR:?}/op/${2##*/}; [[ -f $f ]] && cat "$f" ;;
esac
OP
  cat >"$BATS_TEST_TMPDIR/bin/gh" <<'GH'
#!/usr/bin/env bash
d=${BATS_TEST_TMPDIR:?}/gh; mkdir -p "$d"; touch "$d/keys" "$d/signing"
case "$1 $2" in
  "auth status") [[ -f $d/token ]] || exit 1; if [[ $(<"$d/token") == narrow ]]; then echo "Token scopes: 'repo'"; else echo "Token scopes: 'admin:public_key', 'admin:ssh_signing_key', 'repo'"; fi ;;
  "auth login") cat >"$d/token" ;;
  "api user/keys") [[ $(<"$d/token") == narrow ]] && exit 1; [[ $3 == --jq ]] && cat "$d/keys"; exit 0 ;;
  "api user/ssh_signing_keys") [[ $(<"$d/token") == narrow ]] && exit 1; [[ $3 == --jq ]] && cat "$d/signing"; exit 0 ;;
  "ssh-key add") if [[ $* == *"--type signing"* ]]; then cut -d' ' -f1,2 <"$3" >>"$d/signing"; else cut -d' ' -f1,2 <"$3" >>"$d/keys"; fi ;;
esac
GH
  chmod +x "$BATS_TEST_TMPDIR/bin/op" "$BATS_TEST_TMPDIR/bin/gh"
  export PATH=$BATS_TEST_TMPDIR/bin:$PATH
  host=testhost
}

@test "secrets_gh logs gh in with the token from 1Password, once" {
  make_secret_stubs; touch "$BATS_TEST_TMPDIR/op/unlocked"
  run secrets_gh
  [ "$status" -eq 1 ] && [[ $output == *"github-token not set"* ]]
  printf 'ghp_x\n' >"$BATS_TEST_TMPDIR/op/github-token"
  run secrets_gh
  [ "$status" -eq 0 ] && [[ $output == *"logged in with the token"* ]] && [ "$(cat "$BATS_TEST_TMPDIR/gh/token")" = ghp_x ]
  run secrets_gh
  [[ $output == *"gh         logged in"* ]]
  # a token without the key scopes: replaced by the one from 1Password
  printf 'narrow' >"$BATS_TEST_TMPDIR/gh/token"
  run secrets_gh
  [ "$status" -eq 0 ] && [[ $output == *"logged in again with the token from 1Password"* ]]
  printf 'narrow' >"$BATS_TEST_TMPDIR/gh/token"; rm "$BATS_TEST_TMPDIR/op/github-token"
  run secrets_gh
  [ "$status" -eq 1 ] && [[ $output == *"gh auth refresh -h github.com -s admin:public_key -s admin:ssh_signing_key"* ]]
}

@test "secrets_key does not add a key it could not list" {
  make_secret_stubs; mkdir -p "$BATS_TEST_TMPDIR/gh"; printf 'narrow' >"$BATS_TEST_TMPDIR/gh/token"
  mkdir -p "$HOME/.ssh"; ssh-keygen -q -t ed25519 -N '' -f "$HOME/.ssh/id_ed25519"
  run secrets_key
  [ "$status" -eq 1 ] && [[ $output == *"cannot list the keys on GitHub"* ]] && [ ! -s "$BATS_TEST_TMPDIR/gh/keys" ]
}

@test "secrets_key generates this machine's key and registers it for auth and signing, idempotent" {
  make_secret_stubs; printf 'ghp_x\n' >"$BATS_TEST_TMPDIR/op/github-token"; secrets_gh >/dev/null
  [ "$(ssh_key)" = "$HOME/.ssh/id_ed25519" ]
  run secrets_key
  [ "$status" -eq 0 ]
  [[ $output == *"generated ~/.ssh/id_ed25519"* ]] && [[ $output == *"key added to GitHub as Testhost (on-disk)"* ]]
  pub=$(cut -d' ' -f1,2 <"$HOME/.ssh/id_ed25519.pub")
  [ "$(cat "$BATS_TEST_TMPDIR/gh/keys")" = "$pub" ] && [ "$(cat "$BATS_TEST_TMPDIR/gh/signing")" = "$pub" ]
  run secrets_key
  [[ $output == *"ssh        key on GitHub"* ]] && [[ $output == *"signing    key on GitHub"* ]]
  [ "$(wc -l <"$BATS_TEST_TMPDIR/gh/keys")" -eq 1 ]
  # another key configured for signing: left alone
  export GIT_CONFIG_GLOBAL=$BATS_TEST_TMPDIR/gitconfig; git config --global user.signingkey "$HOME/.ssh/other.pub"
  : >"$BATS_TEST_TMPDIR/gh/signing"
  run secrets_key
  [[ $output == *"another key signs here"* ]] && [ ! -s "$BATS_TEST_TMPDIR/gh/signing" ]
}

@test "step_identity writes git/local, adds the key to allowed_signers once, writes the cloudflare token" {
  make_secret_stubs; touch "$BATS_TEST_TMPDIR/op/unlocked"
  mkdir -p "$HOME/.ssh" "$HOME/.config/git" "$HOME/.config/bash" "$PRIVATE_DIR/common/.config/git"
  ssh-keygen -q -t ed25519 -N '' -f "$HOME/.ssh/id_ed25519"
  printf '# trusted\nme@x.dev,me@work.com ssh-ed25519 AAAAold\n' >"$PRIVATE_DIR/common/.config/git/allowed_signers"
  printf 'f=$HOME/.local/state/cloudflare/token\n' >"$HOME/.config/bash/private"
  printf 'cf-secret\n' >"$BATS_TEST_TMPDIR/op/cloudflare-token"
  export GIT_CONFIG_GLOBAL=$HOME/.config/git/local
  mv "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/away.pub"
  run step_identity
  [ "$status" -eq 0 ] && [ ! -e "$HOME/.config/git/local" ]   # no key to sign with: no identity written
  [[ $output == *"token written"* ]]
  mv "$HOME/.ssh/away.pub" "$HOME/.ssh/id_ed25519.pub"
  run step_identity
  [ "$status" -eq 0 ]
  [[ $output == *"identity written"* ]] && [[ $output == *"added to allowed_signers"* ]]
  grep -q "email = contact@hvpaiva.dev" "$HOME/.config/git/local"
  grep -q "signingkey = ~/.ssh/id_ed25519.pub" "$HOME/.config/git/local"
  pub=$(cut -d' ' -f1,2 <"$HOME/.ssh/id_ed25519.pub")
  [ "$(tail -1 "$PRIVATE_DIR/common/.config/git/allowed_signers")" = "me@x.dev,me@work.com $pub" ]
  [ "$(cat "$HOME/.local/state/cloudflare/token")" = cf-secret ]
  [ "$(stat -c %a "$HOME/.local/state/cloudflare/token")" = 600 ]
  run step_identity
  [[ $output != *"added to allowed_signers"* ]] && [ "$(grep -c "$pub" "$PRIVATE_DIR/common/.config/git/allowed_signers")" -eq 1 ]
}

@test "set_pkgs merges the host's sets, drops comments, duplicates and what the layer removes" {
  detect_os   # DOTS_OS_RELEASE unset: os=other, DROP empty; the lists do not depend on it
  os=arch; DROP=(zoxide)
  mkdir -p "$HOME/.config/packages/arch"
  printf '# zeus\ncore\napps  # gui\n\n' >"$SETS_FILE"
  printf 'git\nzoxide\ntmux # multiplexer\n' >"$HOME/.config/packages/arch/core.txt"
  printf 'tmux\nsignal-desktop\n' >"$HOME/.config/packages/arch/apps.txt"
  [ "$(set_names | paste -sd,)" = core,apps ]
  [ "$(set_pkgs | paste -sd,)" = git,signal-desktop,tmux ]
}

@test "the nvim record is found from any working directory" {
  make_public; make_nvim; record
  mkdir -p "$HOME/dev/elsewhere"; cd "$HOME/dev/elsewhere"
  [ "$(nvim_pointer_state)" = same ]
  [ -z "$(repo_git public status --porcelain --ignore-submodules=all)" ]
}

@test "mise_held names what mise cannot resolve yet, with the date it can" {
  mise() {
    echo "mise WARN  Failed to resolve tool version list for gem:slipway: [~/.config/mise/config.toml] gem:slipway@latest: no versions found for gem:slipway matching minimum_release_age (24h): it hid 1 release, the newest being 0.1.0 (released 2026-09-30, eligible 2026-10-01 17:48 -03). Install that one now." >&2
    echo "mise WARN  Failed to resolve tool version list for npm:gone: [~/.config/mise/config.toml] npm:gone@latest: not found" >&2
  }
  [ -z "$(mise_missing)" ]
  run mise_held
  [ "${lines[0]}" = "gem:slipway until 2026-10-01 17:48" ]
  [ "${lines[1]}" = "npm:gone unresolved" ]
}

# ── mise-intercept (~/.config/bash/mise-intercept) ──────────────────────────
mi_setup() {
  local bin=$BATS_TEST_TMPDIR/bin t
  mkdir -p "$bin"
  for t in cargo gem npm pnpm bun yarn go pipx uv; do
    printf '#!/bin/sh\necho "orig %s $*"\n' "$t" >"$bin/$t"; chmod +x "$bin/$t"
  done
  printf '#!/bin/sh\necho "mise $*"\n' >"$bin/mise"; chmod +x "$bin/mise"
  PATH=$bin:$PATH
  source "$BATS_TEST_DIRNAME/../../bash/mise-intercept"
}
mi_yes() { _mi_tty() { return 0; }; }

# last line of OUTPUT: what ran in the end
last() { printf '%s\n' "$1" | tail -n1; }

@test "mise-intercept offers mise for global installs and runs it on yes" {
  mi_setup; mi_yes
  out=$(cargo install bacon cargo-aoc <<<y)
  [[ $out == *"mise use -g cargo:bacon cargo:cargo-aoc"* ]] && [ "$(last "$out")" = "mise use -g cargo:bacon cargo:cargo-aoc" ]
  [ "$(last "$(cargo install tardis-cli --version 0.1.0 --locked <<<'')")" = "mise use -g cargo:tardis-cli@0.1.0" ]
  [ "$(last "$(gem install slipway -N <<<y)")" = "mise use -g gem:slipway" ]
  [ "$(last "$(npm i -g @scope/tool@1.2 <<<y)")" = "mise use -g npm:@scope/tool@1.2" ]
  [ "$(last "$(go install golang.org/x/tools/gopls@latest <<<y)")" = "mise use -g go:golang.org/x/tools/gopls" ]
  [ "$(last "$(uv tool install graphifyy==0.4.23 <<<y)")" = "mise use -g pipx:graphifyy@0.4.23" ]
}

@test "mise-intercept runs the original on no, and without a terminal" {
  mi_setup; mi_yes
  [ "$(last "$(cargo install bacon <<<n)")" = "orig cargo install bacon" ]
  mi_setup
  out=$(cargo install bacon 2>&1)
  [ "$(last "$out")" = "orig cargo install bacon" ] && [[ $out == *"mise use -g cargo:bacon"* ]]
}

@test "mise-intercept leaves local, project and untranslatable commands alone" {
  mi_setup; mi_yes
  run cargo install --path .;               [ "$output" = "orig cargo install --path ." ]
  run cargo build --release;                [ "$output" = "orig cargo build --release" ]
  run npm install left-pad;                 [ "$output" = "orig npm install left-pad" ]
  run npm i -g ./local-pkg;                 [[ ${lines[-1]} == "orig npm i -g ./local-pkg" ]]
  run go install ./cmd/tool;                [ "$output" = "orig go install ./cmd/tool" ]
  run go install;                           [ "$output" = "orig go install" ]
  run gem list;                             [ "$output" = "orig gem list" ]
  run gem install ./local.gem;              [ "$output" = "orig gem install ./local.gem" ]
  run cargo install ripgrep --features pcre2; [[ ${lines[-1]} == "orig cargo install ripgrep --features pcre2" ]]
  run uv pip install requests;              [ "$output" = "orig uv pip install requests" ]
}

@test "outside_mise lists direct installs, not local builds or the port's tools" {
  local bin=$BATS_TEST_TMPDIR/obin gp=$BATS_TEST_TMPDIR/gopath
  mkdir -p "$bin" "$gp/bin"; touch "$gp/bin/wails" "$gp/bin/sesh"
  printf '#!/bin/sh\nprintf "augur v0.1.0 (/src/augur):\\n    augur\\nbacon v3.19.0:\\n    bacon\\n"\n' >"$bin/cargo"
  printf '#!/bin/sh\nprintf "/n/lib\\n/n/lib/node_modules/npm\\n/n/lib/node_modules/corepack\\n/n/lib/node_modules/ccusage\\n"\n' >"$bin/npm"
  printf '#!/bin/sh\necho %s\n' "$gp" >"$bin/go"
  printf '#!/bin/sh\nprintf "graphifyy v0.4.23\\n- graphify\\n"\n' >"$bin/uv"
  chmod +x "$bin"/*
  PATH=$bin:/usr/bin:/bin
  run outside_mise
  [ "$output" = "$(printf 'cargo:bacon\ngo:sesh\nnpm:ccusage\nuv:graphifyy')" ]
}

@test "the claude-session filter keeps model and effort out of git" {
  command -v jq >/dev/null || skip "jq not installed"
  make_public
  local f=.config/dotfiles/hosts/testhost/.claude/settings.json
  mkdir -p "$HOME/${f%/*}"
  printf '*/.claude/settings.json filter=claude-session\n' >"$HOME/.config/dotfiles/hosts/.gitattributes"
  printf '{\n  "hooks": {},\n  "model": "opus",\n  "effortLevel": "high"\n}\n' >"$HOME/$f"
  repo_filters
  repo_git public add -f "$f" .config/dotfiles/hosts/.gitattributes && repo_git public commit -q -m settings
  [ "$(repo_git public show "HEAD:$f")" = "$(printf '{\n  "hooks": {}\n}')" ]
  grep -q '"model": "opus"' "$HOME/$f"
  printf '{\n  "hooks": {},\n  "model": "fable",\n  "effortLevel": "xhigh"\n}\n' >"$HOME/$f"
  repo_refresh_filtered
  repo_state public; [ "$st_n" -eq 0 ]
  printf '{\n  "hooks": {"x": 1},\n  "model": "fable"\n}\n' >"$HOME/$f"
  repo_refresh_filtered
  repo_state public; [ "$st_n" -eq 1 ]
  [ "$(repo_git public diff --cached --name-only)" = "" ]
}

# A small complete tree exercises the real shared checker without recursively
# running this suite inside every save test.
make_checkable_public() {
  make_public
  mkdir -p "$HOME/.config/dotfiles/test" "$HOME/.config/bash/tests" "$HOME/.local/bin"
  cp "$BATS_TEST_DIRNAME/check.sh" "$HOME/.config/dotfiles/test/check.sh"
  printf '# bash\n' >"$HOME/.bashrc"
  printf '# bash\n' >"$HOME/.bash_profile"
  printf '# sh\n' >"$HOME/.profile"
  printf '#!/usr/bin/env bash\n:\n' >"$HOME/bootstrap.sh"
  cp "$HOME/bootstrap.sh" "$HOME/.local/bin/dots"
  chmod +x "$HOME/bootstrap.sh" "$HOME/.local/bin/dots"
  printf '@test "fixture passes" { true; }\n' >"$HOME/.config/dotfiles/test/smoke.bats"
  repo_git public add -A && repo_git public commit -q -m checker
}

@test "save rejects unstaged Bash errors before committing or pushing any repo, preserving the index" {
  make_checkable_public; make_nvim
  commit "$PRIVATE_DIR" settings initial
  printf 'private change\n' >>"$PRIVATE_DIR/settings"
  printf 'nvim change\n' >>"$NVIM_DIR/init.lua"
  local public_head private_head nvim_head staged origin_head
  public_head=$(repo_git public rev-parse HEAD)
  private_head=$(repo_git private rev-parse HEAD)
  nvim_head=$(repo_git nvim rev-parse HEAD)
  origin_head=$(git --git-dir="$BATS_TEST_TMPDIR/origin.git" rev-parse HEAD)
  printf '# staged\n' >>"$HOME/.bashrc"
  repo_git public add .bashrc
  staged=$(repo_git public write-tree)
  printf 'if then\n' >>"$HOME/.bashrc"
  run cmd_save -m invalid
  [ "$status" -ne 0 ]
  [[ $output == *"validation failed; no commits or pushes made"* ]]
  [ "$(repo_git public rev-parse HEAD)" = "$public_head" ]
  [ "$(repo_git private rev-parse HEAD)" = "$private_head" ]
  [ "$(repo_git nvim rev-parse HEAD)" = "$nvim_head" ]
  [ "$(git --git-dir="$BATS_TEST_TMPDIR/origin.git" rev-parse HEAD)" = "$origin_head" ]
  [ "$(repo_git public write-tree)" = "$staged" ]
  [[ $(cat "$HOME/.bashrc") == *'if then'* ]]
}

@test "check reads hidden sparse files and leaves them hidden" {
  make_checkable_public
  printf 'if then\n' >>"$HOME/bootstrap.sh"
  repo_git public add bootstrap.sh && repo_git public commit -q -m broken
  repo_git public sparse-checkout set --no-cone "${ROOT_PATTERNS[@]}"
  [ ! -e "$HOME/bootstrap.sh" ]
  local staged; staged=$(repo_git public write-tree)
  run cmd_check
  [ "$status" -ne 0 ]
  [[ $output == *bootstrap.sh* ]]
  [ ! -e "$HOME/bootstrap.sh" ]
  [ "$(repo_git public write-tree)" = "$staged" ]
}

@test "save validates new Ruby files separately from Bash and accepts a tests directory" {
  make_checkable_public
  printf 'puts ["ruby"].map { |value| value.upcase }\n' >"$HOME/.config/bash/helper.rb"
  printf '@test "example" { true; }\n' >"$HOME/.config/bash/tests/example.bats"
  run cmd_save --no-push -m valid
  [ "$status" -eq 0 ]
  [ "$(repo_git public log -1 --format=%s)" = valid ]
  [ -z "$(repo_git public status --porcelain)" ]
  [ "$(git --git-dir="$BATS_TEST_TMPDIR/origin.git" log -1 --format=%s)" = initial ]
}

@test "save with no-push still rejects invalid Ruby and failing unit tests" {
  make_checkable_public
  local head; head=$(repo_git public rev-parse HEAD)
  printf 'def broken(\n' >"$HOME/.config/bash/helper.rb"
  run cmd_save --no-push -m invalid
  [ "$status" -ne 0 ]
  [[ $output == *helper.rb* ]]
  [ "$(repo_git public rev-parse HEAD)" = "$head" ]
  rm "$HOME/.config/bash/helper.rb"
  printf '@test "fixture fails" { false; }\n' >"$HOME/.config/dotfiles/test/smoke.bats"
  run cmd_save --no-push -m invalid
  [ "$status" -ne 0 ]
  [[ $output == *"not ok 1 fixture fails"* ]]
  [ "$(repo_git public rev-parse HEAD)" = "$head" ]
}

@test "the shared checker fails with an actionable message when shellcheck is missing" {
  local bin=$BATS_TEST_TMPDIR/minimal-bin
  mkdir "$bin"
  ln -s "$(command -v dirname)" "$bin/dirname"
  run env PATH="$bin" "$(command -v bash)" "$BATS_TEST_DIRNAME/check.sh" lint
  [ "$status" -ne 0 ]
  [[ $output == *"validation requires shellcheck; install it and retry dots check"* ]]
}
