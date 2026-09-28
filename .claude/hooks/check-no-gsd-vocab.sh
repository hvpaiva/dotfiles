#!/usr/bin/env bash
# check-no-gsd-vocab.sh
#
# Blocks orchestration-system vocabulary (COMPASS/Argo/GSD decision IDs,
# finding IDs, requirement IDs, phase/plan refs, artifact filenames, pitfalls,
# rules, waves, etc.) from leaking outside the planning folder.
#
# Allowlist: paths containing `.planning/` or `.claude/`.
#
# Modes:
#   --mode=claude            PreToolUse hook (reads JSON on stdin)
#   --mode=git-pre-commit    git pre-commit hook (scans staged diff additions)
#   --mode=git-commit-msg    git commit-msg hook (argv[2] = msg file)
#
# Exit codes:
#   0  allow
#   1  block (git hook convention)
#   2  block (Claude Code PreToolUse convention — stderr shown to Claude)

set -u
export LC_ALL=${LC_ALL:-C.UTF-8}

MODE=""
for arg in "$@"; do
  case "$arg" in
    --mode=*) MODE="${arg#--mode=}" ;;
  esac
done

# Flat PCRE regex. One line per token class so the regex stays readable in
# source even though we collapse it for grep. Keep in sync with
# ~/.claude/BLOCK-POLICY.md.
read -r -d '' BLOCKLIST <<'EOF' || true
\b(?:CORE|DAE|IPC|HIST)-\d+\b
\b(?:WR|IN|CR|FD|EV|G)-\d+\b
\bD-\d+(?:\.\d+)?\b
\bT-\d{2}-\d{2}-\d{2,}\b
\bS-\d+\b
\bW\d+\s+(?:fix|doc|mitigation|regression|patch|documentation)\b
\b[Bb][1-9]\b(?=\s*[:\x{2014}\x{2013}]|\s+(?:wire|path|Option|user|decision))
\bPitfall\s+\d+\b
\bPITFALLS\s*#?\s*\d+
\bRule\s+\d+\b
\b[Ww]ave\s+\d+\b
\b(?:PLAN|SPEC|SUMMARY|REVIEW(?:-FIX)?|UAT|ROADMAP|PROJECT|REQUIREMENTS|STATE|INTEL|CONTEXT|RESEARCH|FEATURES|PATTERNS|PITFALLS|DEVIATIONS)\.md\b
\b(?:FEATURES|SUMMARY|ROADMAP|CONTEXT|RESEARCH)\s+§
§A\.\d+
§Success\s*#?\s*\d+
§Phase\s+\d+
\bPhase\s+\d+\b
\bphase-\d+\b
TODO\(phase-\d+\)
\b[Pp]lan\s+\d+-\d+\b
\bTask\s+\d+(?:-\d+)?\b
\.planning/
\bGSD\b
\bgsd\b
\bUAT\b
\bTDD\b
\bRED\s+gate\b
\bGREEN\s+gate\b
\bpublish-gate\b
\btraceability\b
\bREQ-ID\b
\bdeviation\s*#?\s*\d+
\bauto-fix(?:ed)?\b
\bdeviation\s+log\b
\borchestrator\b
\bexecutor\s+worktree\b
\bworktree-agent\b
\b(?:feat|fix|chore|docs|refactor|test|ci|style|perf|build|revert)\(\s*(?:\d+|\d+-\d+|phase-\d+|roadmap|state)\s*\)\s*:
\bRESEARCH\s+Open\s+Q\b
EOF

# Collapse into one | alternation, strip blank lines.
PCRE=$(printf '%s\n' "$BLOCKLIST" | grep -v '^\s*$' | paste -sd '|' -)

path_is_allowlisted() {
  local p="$1"
  [ -z "$p" ] && return 1
  p="${p#./}"
  case "$p" in
    .planning/*|*/.planning/*|*.planning|*/.planning) return 0 ;;
    .claude/*|*/.claude/*|"$HOME/.claude/"*|"$HOME/.claude") return 0 ;;
    CLAUDE.md|*/CLAUDE.md) return 0 ;;
  esac
  return 1
}

# Activation gate. Decision order at the repo root:
#   1. `.gsd-block-policy.ignore` present → always no-op (override opt-out,
#      use this in a GSD-style project that has too much legitimate overlap
#      with the blocklist vocabulary).
#   2. `.planning/` directory present → active (auto-on for GSD projects).
#   3. `.gsd-block-policy` file present → active (manual opt-in marker,
#      for projects that use a different planning folder convention).
#   4. Otherwise → no-op.
# Outside any git repo the hook is always a no-op.
repo_has_policy() {
  local start="$1"
  [ -z "$start" ] && return 1
  local dir
  if [ -d "$start" ]; then
    dir="$start"
  else
    dir="$(dirname "$start")"
    while [ -n "$dir" ] && [ "$dir" != "/" ] && [ ! -d "$dir" ]; do
      dir="$(dirname "$dir")"
    done
  fi
  [ -d "$dir" ] || return 1
  local root
  root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || return 1
  [ -f "$root/.gsd-block-policy.ignore" ] && return 1
  [ -d "$root/.planning" ] && return 0
  [ -f "$root/.gsd-block-policy" ] && return 0
  return 1
}

# Scan a blob of text; print matched tokens one per line (deduplicated).
scan_text() {
  local text="$1"
  [ -z "$text" ] && return 0
  printf '%s' "$text" | grep -Po "$PCRE" 2>/dev/null | sort -u
}

emit_block() {
  local subject="$1"
  local matches="$2"
  local one_line
  one_line=$(printf '%s' "$matches" | tr '\n' ',' | sed 's/,$//;s/,/, /g')
  cat >&2 <<MSG
BLOCKED: $subject
  tokens matched: $one_line
  policy: internal orchestration vocabulary lives ONLY under .planning/
  explainer: ~/.claude/BLOCK-POLICY.md
  remedy: rephrase the content to remove these tokens. Do NOT relocate source
          files, tests, configs, or user-facing docs into .planning/ — that
          folder is reserved for planning artifacts authored there from scratch.
          Code and external docs must be self-contained WITHOUT this vocabulary.
MSG
}

case "$MODE" in
  claude)
    payload=$(cat)
    tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // empty')
    file_path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')

    case "$tool_name" in
      Write)         text=$(printf '%s' "$payload" | jq -r '.tool_input.content    // empty') ;;
      Edit)          text=$(printf '%s' "$payload" | jq -r '.tool_input.new_string // empty') ;;
      NotebookEdit)  text=$(printf '%s' "$payload" | jq -r '.tool_input.new_source // empty') ;;
      *)             exit 0 ;;
    esac

    if path_is_allowlisted "$file_path"; then
      exit 0
    fi

    if ! repo_has_policy "$file_path"; then
      exit 0
    fi

    matches=$(scan_text "$text")
    if [ -n "$matches" ]; then
      emit_block "$file_path (via $tool_name)" "$matches"
      exit 2
    fi
    exit 0
    ;;

  git-pre-commit)
    if ! repo_has_policy "$PWD"; then
      exit 0
    fi
    any=0
    while IFS= read -r -d '' file; do
      if path_is_allowlisted "$file"; then
        continue
      fi
      added=$(git diff --cached --unified=0 -- "$file" 2>/dev/null \
              | grep -E '^\+[^+]' \
              | sed 's/^\+//')
      [ -z "$added" ] && continue
      matches=$(scan_text "$added")
      if [ -n "$matches" ]; then
        emit_block "$file (staged diff)" "$matches"
        any=1
      fi
    done < <(git diff --cached --name-only -z 2>/dev/null)
    exit $any
    ;;

  git-commit-msg)
    if ! repo_has_policy "$PWD"; then
      exit 0
    fi
    msg_file="${2:-}"
    if [ -z "$msg_file" ] || [ ! -f "$msg_file" ]; then
      echo "commit-msg hook: missing message file" >&2
      exit 1
    fi
    msg_clean=$(grep -v '^\s*#' "$msg_file" || true)
    matches=$(scan_text "$msg_clean")
    if [ -n "$matches" ]; then
      emit_block "commit message" "$matches"
      exit 1
    fi
    exit 0
    ;;

  *)
    echo "usage: $0 --mode={claude|git-pre-commit|git-commit-msg} [args...]" >&2
    exit 1
    ;;
esac
