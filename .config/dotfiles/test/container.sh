#!/usr/bin/env bash
# Run the bootstrap twice in a clean container and check that the second run is a no-op.
#
#   test/container.sh arch|ubuntu [--full]
#
# The container clones from a local bare copy of this repo (DOTFILES_SRC, default
# ~/.dotfiles), so uncommitted work is not tested: commit first. Without --full the
# mise and rust steps are skipped; with it the run installs everything and takes a while.
set -u
distro=${1:?usage: container.sh arch|ubuntu [--full]}; shift
full=0; [[ ${1:-} == --full ]] && full=1
src=${DOTFILES_SRC:-$HOME/.dotfiles}
case $distro in
  arch)   image=archlinux:latest; setup='pacman -Sy --noconfirm --needed git curl make gawk base-devel tmux sudo which >/dev/null' ;;
  ubuntu) image=ubuntu:24.04;     setup='apt-get update -qq >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y git curl make gawk build-essential tmux sudo ca-certificates >/dev/null' ;;
  *) echo "unknown distro: $distro" >&2; exit 2 ;;
esac
work=$(mktemp -d)
git clone -q --bare "$src" "$work/dotfiles.git" || exit 1
git --git-dir="$work/dotfiles.git" show HEAD:.config/dotfiles/bootstrap.sh >"$work/bootstrap.sh"
flags="--host test --skip-omarchy --skip-private"; (( full )) || flags+=" --skip-mise --skip-rust"

# Runs as the test user after both bootstrap runs and prints key=value lines.
cat >"$work/probe.sh" <<'PROBE'
d() { git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }
echo "tracked_bashrc=$(d ls-files .bashrc)"
echo "pager=$(bash -lic 'printf %s "$PAGER"' 2>/dev/null)"
echo "login_errors=$(bash -lic true 2>&1 | grep -ciE 'error|no such file')"
echo "hooks_exec=$([ -x "$HOME/.config/git/hooks/commit-msg" ] && echo yes || echo no)"
echo "nvim_branch=$(git -C "$HOME/.config/nvim" branch --show-current 2>/dev/null)"
echo "blesh=$([ -f "$HOME/.local/share/blesh/ble.sh" ] && echo yes || echo no)"
echo "tpm=$([ -d "$HOME/.local/share/tmux/plugins/tpm" ] && echo yes || echo no)"
tmux_out=$(tmux -L probe -f "$HOME/.config/tmux/tmux.conf" new-session -d -s p 2>&1); tmux -L probe kill-server 2>/dev/null
echo "tmux_errors=$(grep -ci error <<<"$tmux_out")"
echo "cargo=$([ -x "$HOME/.cargo/bin/cargo" ] && echo yes || echo no)"
echo "augur=$([ -x "$HOME/.cargo/bin/augur" ] && echo yes || echo no)"
echo "mise=$([ -x "$HOME/.local/bin/mise" ] && echo yes || echo no)"
echo "mise_missing=$(PATH=$HOME/.local/bin:$PATH mise ls --missing 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
echo "mise_log_errors=$(grep -ciE 'failed|error' "$HOME/.local/state/dotfiles/mise-install.log" 2>/dev/null || true)"
PROBE

cat >"$work/inside.sh" <<INSIDE
set -u
$setup
useradd -m -s /bin/bash tester
chown -R tester:tester /work
run() { su - tester -c "DOTFILES_REPO=/work/dotfiles.git bash /work/bootstrap.sh $flags"; }
echo "=================== first run"; run; rc1=\$?
echo "=================== second run"; out=\$(run 2>&1); rc2=\$?; printf '%s\n' "\$out"
echo "=================== checks"
probe=\$(su - tester -c 'bash /work/probe.sh' 2>/dev/null)
get() { sed -n "s/^\$1=//p" <<<"\$probe"; }
fail=0
check() { if [ "\$2" = "\$3" ]; then echo "  ok   \$1"; else echo "  FAIL \$1 (got '\$2', want '\$3')"; fail=1; fi; }
check "first run exit 0"              "\$rc1" 0
check "second run exit 0"             "\$rc2" 0
check "second run reports no drift"   "\$(grep -c 'tracked files match' <<<"\$out")" 1
check "second run at origin"          "\$(grep -c 'at origin/master' <<<"\$out")" 1
check "bashrc tracked"                "\$(get tracked_bashrc)" .bashrc
check "login shell: PAGER=less"       "\$(get pager)" less
check "login shell: no errors"        "\$(get login_errors)" 0
check "git hooks executable"          "\$(get hooks_exec)" yes
check "git identity warning shown"    "\$(grep -c 'no ~/.config/git/local' <<<"\$out")" 1
check "nvim cloned on main"           "\$(get nvim_branch)" main
check "ble.sh installed"              "\$(get blesh)" yes
check "tpm present"                   "\$(get tpm)" yes
check "tmux config loads"             "\$(get tmux_errors)" 0
if [ $full -eq 1 ]; then
  check "rustup installed"            "\$(get cargo)" yes
  check "augur built"                 "\$(get augur)" yes
  check "mise installed"              "\$(get mise)" yes
  check "mise: nothing missing"       "\$(get mise_missing)" ""
  check "mise: no install errors"     "\$(get mise_log_errors)" 0
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
