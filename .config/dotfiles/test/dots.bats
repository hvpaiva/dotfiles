#!/usr/bin/env bats
# Unit tests for the logic in ~/.local/bin/dots: pure helpers, and the git-backed
# helpers against throwaway repositories. Nothing here touches the network, the
# real $HOME or sudo. Run with: bats ~/.config/dotfiles/test

setup() {
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
  git -C "$src" branch -m master
  git clone -q --bare "$src" "$BATS_TEST_TMPDIR/origin.git"
  git -C "$src" remote add origin "$BATS_TEST_TMPDIR/origin.git"
  git clone -q --bare "$BATS_TEST_TMPDIR/origin.git" "$PUBLIC_GIT_DIR"
  repo_git public config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  repo_git public reset -q --hard HEAD
  repo_git public fetch -q origin
  repo_git public branch -q --set-upstream-to=origin/master master
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
  st_branch=master st_upstream=origin/master st_ahead=0 st_behind=0
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
  [ "$st_branch" = master ] && [ "$st_n" -eq 0 ] && [ "$(origin_text)" = "in sync" ]
  printf 'x\n' >"$HOME/.bashrc"; printf 'new\n' >"$HOME/.new"
  repo_state public
  [ "$st_n" -eq 2 ] && [[ $st_changes == *"?? .new"* ]]
  repo_git public add -A && repo_git public commit -q -m "local"
  repo_state public; [ "$(origin_text)" = "1 to push" ]
  commit "$BATS_TEST_TMPDIR/src" other "upstream moved"
  git -C "$BATS_TEST_TMPDIR/src" push -q origin master
  repo_git public fetch -q origin
  repo_state public; [ "$(origin_text)" = "diverged 1/1" ]
}

@test "repo_update fast-forwards, keeps a local edit, refuses to diverge" {
  make_public
  commit "$BATS_TEST_TMPDIR/src" other "upstream moved"
  git -C "$BATS_TEST_TMPDIR/src" push -q origin master
  printf 'edited\n' >"$HOME/.bashrc"
  repo_git public fetch -q origin
  run repo_update public 0
  [[ $output == *"1 new commit(s)"* ]]
  [ -f "$HOME/other" ] && [ "$(cat "$HOME/.bashrc")" = edited ]
  repo_git public add -A && repo_git public commit -q -m "local"
  commit "$BATS_TEST_TMPDIR/src" more "upstream moved again"
  git -C "$BATS_TEST_TMPDIR/src" push -q origin master
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

@test "a recorded nvim commit counts as a dotfiles change until it is committed" {
  make_public; make_nvim
  repo_state public; [ "$st_n" -eq 0 ]
  record_nvim >/dev/null
  repo_state public
  [ "$st_n" -eq 1 ] && [[ $st_changes == "M  .config/nvim" ]]
  repo_git public commit -q -m "record nvim"
  repo_state public; [ "$st_n" -eq 0 ]
}

@test "root_hide keeps the root entries out of the work tree, root show brings them back" {
  make_public
  for f in README.md bootstrap.sh; do commit "$BATS_TEST_TMPDIR/src" "$f" "add $f"; done
  git -C "$BATS_TEST_TMPDIR/src" push -q origin master
  repo_git public fetch -q origin; repo_git public merge -q --ff-only origin/master
  [ -f "$HOME/README.md" ]
  ! root_hidden
  root_hide 1
  root_hidden
  [ ! -e "$HOME/README.md" ] && [ ! -e "$HOME/bootstrap.sh" ] && [ -f "$HOME/.bashrc" ]
  [ -z "$(repo_git public status --porcelain)" ]
  cmd_root show >/dev/null
  [ -f "$HOME/README.md" ]
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

@test "mise_missing takes the first column of mise ls --missing" {
  mise() { printf 'node   24.1.0   ~/.config/mise/config.toml  latest\nbun    1.3.13\n'; }
  [ "$(mise_missing | tr '\n' ' ')" = "node bun " ]
}
