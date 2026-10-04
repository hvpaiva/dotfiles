#!/usr/bin/env bash
# The README one-liner on a clean machine: run the bootstrap twice in a fresh container,
# check the second run changes nothing, then exercise dots save and dots update against the
# local origin.
#
#   test/container.sh arch|ubuntu [--full]
#
# The container clones from a local bare copy of this repo (DOTFILES_SRC, default ~/.dotfiles),
# so uncommitted work is not tested: commit first. The container starts with what a fresh
# desktop install of each distro guarantees and nothing else (Arch/Omarchy: git, curl, sudo;
# Ubuntu: curl, sudo — no git), plus a distro copy of tools the layer replaces, so the
# dependency and removal steps are exercised. Omarchy itself cannot run in a container, so
# that step is skipped. Without --full the mise and rust steps are skipped too; with it the
# run installs everything and takes a while (GITHUB_TOKEN, if set, is passed to mise).
set -u
distro=${1:?usage: container.sh arch|ubuntu [--full]}; shift
full=0; [[ ${1:-} == --full ]] && full=1
src=${DOTFILES_SRC:-$HOME/.dotfiles}
case $distro in
  arch)
    image=archlinux:latest
    setup='pacman -Sy --noconfirm --needed git curl sudo zoxide starship shellcheck ruby bats >/dev/null'
    left='pacman -Qq zoxide starship 2>/dev/null | wc -l'
    # shellcheck disable=SC2016
    pacman_check='check "pacman install hook installed" "$(test -r /etc/pacman.d/hooks/pkg-snapshot-append.hook && echo yes)" yes' ;;
  ubuntu)
    image=ubuntu:24.04
    setup='apt-get update -qq >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y curl sudo ca-certificates zoxide shellcheck ruby bats >/dev/null'
    # shellcheck disable=SC2016
    left='dpkg-query -W -f="\${db:Status-Status}\n" zoxide 2>/dev/null | grep -cx installed'
    pacman_check='' ;;
  *) echo "unknown distro: $distro" >&2; exit 2 ;;
esac
work=$(mktemp -d)
git clone -q --bare "$src" "$work/dotfiles.git" || exit 1
# a detached HEAD in the source (CI checkouts) would leave the clone without a main branch
if ! git --git-dir="$work/dotfiles.git" symbolic-ref -q HEAD >/dev/null; then
  git --git-dir="$work/dotfiles.git" branch -f main HEAD && git --git-dir="$work/dotfiles.git" symbolic-ref HEAD refs/heads/main
fi
git --git-dir="$work/dotfiles.git" show HEAD:bootstrap.sh >"$work/bootstrap.sh"
flags="--host test --skip-omarchy --skip-private"; (( full )) || flags+=" --skip-mise --skip-rust"
token=${GITHUB_TOKEN:-}

# As the test user, after both bootstrap runs: a local change goes out with dots save and
# dots update brings the machine back to clean.
cat >"$work/flow.sh" <<'FLOW'
set -u
export PATH=$HOME/.local/bin:$PATH
# no signing key and no identity file in the container
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false
export GIT_AUTHOR_EMAIL=tester@example.com GIT_COMMITTER_EMAIL=tester@example.com
echo '# container test' >>"$HOME/.XCompose"
echo "----- dots status"; dots status -o
echo "----- dots save";   dots save -m "test: save from the container" || exit 1
echo "----- dots update"; dots update --quick || exit 1
[ -z "$(dots git status --porcelain)" ] || { echo "dirty after save"; exit 1; }
FLOW

# As the test user, last: key=value facts for the checks.
cat >"$work/probe.sh" <<'PROBE'
d() { git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }
echo "tracked_bashrc=$(d ls-files .bashrc)"
echo "pager=$(bash -lic 'printf %s "$PAGER"' 2>/dev/null)"
echo "dots_path=$(bash -lic 'command -v dots' 2>/dev/null)"
echo "login_errors=$(bash -lic true 2>&1 | grep -ciE 'error|no such file')"
echo "hooks_exec=$([ -x "$HOME/.config/git/hooks/commit-msg" ] && echo yes || echo no)"
echo "nvim_branch=$(git -C "$HOME/.config/nvim" branch --show-current 2>/dev/null)"
echo "blesh=$([ -f "$HOME/.local/share/blesh/ble.sh" ] && echo yes || echo no)"
echo "tpm=$([ -d "$HOME/.local/share/tmux/plugins/tpm" ] && echo yes || echo no)"
tmux_out=$(tmux -L probe -f "$HOME/.config/tmux/tmux.conf" new-session -d -s p 2>&1); tmux -L probe kill-server 2>/dev/null
echo "tmux_errors=$(grep -ci error <<<"$tmux_out")"
echo "deps=$(for c in git make gawk tmux cc; do command -v "$c" >/dev/null && printf '%s ' "$c"; done)"
echo "ssh_tools=$(for c in ssh ssh-keygen; do command -v "$c" >/dev/null && printf '%s ' "$c"; done)"
echo "root_in_home=$({ [ -e "$HOME/README.md" ] && echo 1; [ -e "$HOME/bootstrap.sh" ] && echo 1; [ -e "$HOME/.github" ] && echo 1; } | wc -l)"
echo "root_checked_out=$(d ls-files -t README.md bootstrap.sh .github | grep -vc '^S ')"
echo "cargo=$([ -x "$HOME/.cargo/bin/cargo" ] && echo yes || echo no)"
echo "augur=$([ -x "$HOME/.cargo/bin/augur" ] && echo yes || echo no)"
echo "mise=$([ -x "$HOME/.local/bin/mise" ] && echo yes || echo no)"
echo "mise_missing=$(PATH=$HOME/.local/bin:$PATH mise ls --missing --no-header 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
echo "mise_log_errors=$(grep -ciE 'failed|error' "$HOME/.local/state/dotfiles/mise-install.log" 2>/dev/null || true)"
PROBE

cat >"$work/inside.sh" <<INSIDE
set -u
$setup
useradd -m -s /bin/bash tester
echo 'tester ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/tester && chmod 440 /etc/sudoers.d/tester
chown -R tester:tester /work
env_="DOTFILES_REPO=/work/dotfiles.git DOTFILES_PUSH_URL=/work/dotfiles.git MISE_GITHUB_TOKEN=$token"
run() { su - tester -c "\$env_ bash <(cat /work/bootstrap.sh) $flags"; }
echo "=================== first run"; run; rc1=\$?
echo "=================== second run"; out=\$(run 2>&1); rc2=\$?; printf '%s\n' "\$out"
echo "=================== dots save / update"; su - tester -c 'bash /work/flow.sh'; rcf=\$?
echo "=================== checks"
probe=\$(su - tester -c 'bash /work/probe.sh' 2>/dev/null)
get() { sed -n "s/^\$1=//p" <<<"\$probe"; }
fail=0
check() { if [ "\$2" = "\$3" ]; then echo "  ok   \$1"; else echo "  FAIL \$1 (got '\$2', want '\$3')"; fail=1; fi; }
check "first run exit 0"                 "\$rc1" 0
check "second run exit 0"                "\$rc2" 0
check "second run: dotfiles clean"       "\$(grep -cE '^dotfiles +ok +clean, in sync' <<<"\$out")" 1
check "second run: no distro copies"     "\$(grep -cE '^packages +ok +no distro copies' <<<"\$out")" 1
check "second run: build deps present"   "\$(grep -cE '^deps +ok +all present' <<<"\$out")" 1
check "second run: links in place"       "\$(grep -cE '^links +ok ' <<<"\$out")" 1
check "second run: root entries hidden"  "\$(grep -cE '^root +ok ' <<<"\$out")" 1
check "second run: setup done"           "\$(grep -cE '^setup +done' <<<"\$out")" 1
check "git identity warning shown"       "\$(grep -cE '^git +warn +no identity' <<<"\$out")" 1
$pacman_check
check "distro copies removed"            "\$($left)" 0
check "build deps installed"             "\$(get deps)" "git make gawk tmux cc "
check "SSH client and keygen installed"  "\$(get ssh_tools)" "ssh ssh-keygen "
check "bashrc tracked"                   "\$(get tracked_bashrc)" .bashrc
check "login shell: PAGER=less"          "\$(get pager)" less
check "login shell: dots on PATH"        "\$(get dots_path)" /home/tester/.local/bin/dots
check "login shell: no errors"           "\$(get login_errors)" 0
check "git hooks executable"             "\$(get hooks_exec)" yes
check "nvim cloned on main"              "\$(get nvim_branch)" main
check "ble.sh installed"                 "\$(get blesh)" yes
check "tpm present"                      "\$(get tpm)" yes
check "tmux config loads"                "\$(get tmux_errors)" 0
check "root entries out of \\\$HOME"      "\$(get root_in_home)" 0
check "root entries skip-worktree"       "\$(get root_checked_out)" 0
check "dots save: commit reached origin" "\$(su - tester -c 'git --git-dir=/work/dotfiles.git log -1 --format=%s')" "test: save from the container"
check "dots save / update flow exit 0"   "\$rcf" 0
if [ $full -eq 1 ]; then
  check "rustup installed"               "\$(get cargo)" yes
  check "augur built"                    "\$(get augur)" yes
  check "mise installed"                 "\$(get mise)" yes
  check "mise: nothing missing"          "\$(get mise_missing)" ""
  check "mise: no install errors"        "\$(get mise_log_errors)" 0
  [ "\$(get mise_log_errors)" = 0 ] || { echo "  --- mise-install.log errors:"; grep -iE 'failed|error' /home/tester/.local/state/dotfiles/mise-install.log | head -12 | sed 's/^/      /'; }
fi
echo "=================== result: \$([ \$fail -eq 0 ] && echo PASS || echo FAIL)"
exit \$fail
INSIDE
chmod -R a+rX "$work"
# docker cp instead of a bind mount: works from a sandboxed /tmp and keeps the daemon out of $HOME
name=dots-test-$distro-$$
docker create --name "$name" "$image" bash /work/inside.sh >/dev/null || exit 1
docker cp "$work/." "$name:/work" && docker start -a "$name"
rc=$?; docker rm -f "$name" >/dev/null 2>&1; rm -rf "$work"; exit $rc
