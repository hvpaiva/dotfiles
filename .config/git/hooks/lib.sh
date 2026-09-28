# shellcheck shell=bash
# Shared by the global hooks in this directory (core.hooksPath).

# Remove attribution trailers that coding agents append to commit messages.
# Human co-authors are kept: only lines naming an AI vendor or tool go.
strip_ai_trailers() {
  local file=$1 tmp
  [[ -f $file ]] || return 0
  tmp=$(mktemp) || return 1
  grep -viE \
    -e '^co-authored-by:.*(claude|anthropic|cursor|openai|chatgpt|copilot|composer|gpt-|gemini|codex|noreply@anthropic|ai@|agent@)' \
    -e '^claude-session:' \
    -e '^(generated-by|generated-with|made-with|assisted-by):' \
    -e '^signed-off-by:[[:space:]]*cursor' \
    -e 'generated with \[?claude code' \
    "$file" > "$tmp"
  # collapse the blank lines left behind
  cat -s "$tmp" > "$file" && rm -f "$tmp"
}

# A global core.hooksPath disables the repository's own hooks, so run them here,
# then the per-host hook of the same name (~/.config/git/hooks.local, not tracked).
chain() {
  local hook=$1 dir; shift
  dir=$(git rev-parse --git-common-dir 2>/dev/null) || dir=$(git rev-parse --git-dir 2>/dev/null)
  if [[ -n $dir && -x $dir/hooks/$hook ]]; then "$dir/hooks/$hook" "$@" || return $?; fi
  if [[ -x $HOME/.config/git/hooks.local/$hook ]]; then "$HOME/.config/git/hooks.local/$hook" "$@" || return $?; fi
  return 0
}
