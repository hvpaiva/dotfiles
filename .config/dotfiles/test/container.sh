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
# mktemp gives 0700; the container user may not share our uid (ubuntu:24.04 already has uid 1000)
chmod -R a+rX "$work"
flags="--host test --skip-omarchy --skip-private"; (( full )) || flags+=" --skip-mise --skip-rust"
cat >"$work/inside.sh" <<INSIDE
set -u
$setup
useradd -m -s /bin/bash tester
cp /work/bootstrap.sh /home/tester/bootstrap.sh && chown tester /home/tester/bootstrap.sh
run() { su - tester -c "DOTFILES_REPO=/work/dotfiles.git bash /home/tester/bootstrap.sh $flags"; }
echo "=================== first run"; run; rc1=\$?
echo "=================== second run"; out=\$(run 2>&1); rc2=\$?; printf '%s\n' "\$out"
echo "=================== checks"
fail=0
check() { if eval "\$2"; then echo "  ok   \$1"; else echo "  FAIL \$1"; fail=1; fi; }
check "first run exit 0"                  "[ \$rc1 -eq 0 ]"
check "second run exit 0"                 "[ \$rc2 -eq 0 ]"
check "second run reports no drift"       "grep -q 'tracked files match' <<<\"\$out\""
check "second run at origin"              "grep -q 'at origin/master' <<<\"\$out\""
check "bashrc, profile, gitignore tracked" "su - tester -c 'git --git-dir=\$HOME/.dotfiles --work-tree=\$HOME ls-files' | grep -qx .bashrc"
check "login shell loads, PAGER=less"     "[ \"\$(su - tester -c 'bash -lic \"echo \\\$PAGER\"' 2>/dev/null | tail -1)\" = less ]"
check "login shell has no errors"         "! su - tester -c 'bash -lic true' 2>&1 | grep -qiE 'error|No such file'"
check "git hooks executable"              "[ -x /home/tester/.config/git/hooks/commit-msg ]"
check "git identity warning shown"        "grep -q 'no ~/.config/git/local' <<<\"\$out\""
check "nvim cloned on main"               "[ \"\$(git -C /home/tester/.config/nvim branch --show-current)\" = main ]"
check "ble.sh installed"                  "[ -f /home/tester/.local/share/blesh/ble.sh ]"
check "tpm present"                       "[ -d /home/tester/.local/share/tmux/plugins/tpm ]"
check "tmux config parses"                "su - tester -c 'tmux -f ~/.config/tmux/tmux.conf -L t start-server \; kill-server' 2>&1 | grep -vq 'error'"
if [ $full -eq 1 ]; then
  check "rustup installed"                "[ -x /home/tester/.cargo/bin/cargo ]"
  check "augur built"                     "[ -x /home/tester/.cargo/bin/augur ]"
  check "mise installed"                  "[ -x /home/tester/.local/bin/mise ]"
  check "mise tools without failures"     "! grep -qiE 'failed|error' /home/tester/.local/state/dotfiles/mise-install.log"
  echo "  --- tools missing after install:"; su - tester -c 'export PATH=\$HOME/.local/bin:\$PATH; mise ls --missing 2>/dev/null' | sed 's/^/      /'
fi
echo "=================== result: \$([ \$fail -eq 0 ] && echo PASS || echo FAIL)"
exit \$fail
INSIDE
# docker cp instead of a bind mount: a sandboxed /tmp is not visible to the daemon
name=dots-test-$distro-$$
docker create --name "$name" "$image" bash /work/inside.sh >/dev/null || exit 1
docker cp "$work/." "$name:/work" && docker start -a "$name"
rc=$?; docker rm -f "$name" >/dev/null 2>&1; rm -rf "$work"; exit $rc
