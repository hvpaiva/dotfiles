#!/usr/bin/env bats
# Black-box tests for hosts/athena/.claude/hooks/prose-send-gate.py: JSON payload in,
# deny or silence out. HOME is a throwaway directory wired to the repo's prose-lint and
# Vale config, so the real $HOME is never read. Run with: bats ~/.config/dotfiles/test

setup_file() {
  # Tests replace HOME, so mise shims (which dots puts first on PATH) would lose
  # their config/trust state and every vale call would fail. Keep the active
  # binaries instead, as dots.bats does.
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
  exec </dev/null
  command -v vale >/dev/null || skip "vale not installed"
  athena=$BATS_TEST_DIRNAME/../hosts/athena
  gate=$athena/.claude/hooks/prose-send-gate.py
  export HOME=$BATS_TEST_TMPDIR/home
  mkdir -p "$HOME/.local/bin" "$HOME/.config"
  ln -s "$athena/.local/bin/prose-lint" "$HOME/.local/bin/prose-lint"
  ln -s "$athena/.config/vale" "$HOME/.config/vale"
}

bash_payload() { jq -nc --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c}, cwd: "/tmp"}'; }
write_payload() { jq -nc --arg p "$1" --arg c "$2" '{tool_name: "Write", tool_input: {file_path: $p, content: $c}}'; }
mcp_payload() { jq -nc --arg t "$1" --argjson i "$2" '{tool_name: $t, tool_input: $i}'; }

decision() { run "$gate" <<<"$1"; }

assert_denied() {
  [ "$status" -eq 0 ]
  [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = deny ]
}

assert_allowed() {
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "slk send with a label is denied" {
  decision "$(bash_payload 'slk send C0AB12CD3 "Status: tudo certo"')"
  assert_denied
  [[ $output == *Conduta.Rotulo* ]]
}

@test "slk send with an em dash after --thread is denied" {
  decision "$(bash_payload 'slk send C0AB12CD3 --thread 1787236461.230889 "ok — feito"')"
  assert_denied
  [[ $output == *Conduta.Travessao* ]]
}

@test "slk send with clean prose is allowed" {
  decision "$(bash_payload 'slk send C0AB12CD3 "Tudo certo por aqui."')"
  assert_allowed
}

@test "text piped into slk send is linted" {
  decision "$(bash_payload 'echo "Resumo: deploy ok" | slk send D0AB12CD3')"
  assert_denied
}

@test "slk queue approve carries no text and is allowed" {
  decision "$(bash_payload 'slk queue approve 2')"
  assert_allowed
}

@test "gh pr create body from a heredoc is linted" {
  local cmd
  cmd=$(printf 'gh pr create --title "fix deploy" --body "$(cat <<%sEOF%s\nMotivo: o deploy quebrava.\nEOF\n)"' "'" "'")
  decision "$(bash_payload "$cmd")"
  assert_denied
  [[ $output == *"gh pr create body"* ]]
}

@test "gh body read from --body-file is linted" {
  printf 'Contexto: algo.\n' >"$BATS_TEST_TMPDIR/body.md"
  decision "$(bash_payload "gh pr comment 12 --body-file $BATS_TEST_TMPDIR/body.md")"
  assert_denied
}

@test "commands that send nothing are allowed" {
  decision "$(bash_payload 'git commit -m "Status: wip" && ls -la')"
  assert_allowed
}

@test "unparseable shell fails open" {
  decision "$(bash_payload 'slk send C0AB12CD3 "Status: aberto')"
  assert_allowed
}

@test "writing a markdown document with a label is denied" {
  decision "$(write_payload "$BATS_TEST_TMPDIR/doc.md" 'Contexto: algo.')"
  assert_denied
}

@test "agent files are never linted" {
  decision "$(write_payload "$HOME/.claude/projects/x/memory/a.md" '**Why:** algo.')"
  assert_allowed
  decision "$(write_payload "$BATS_TEST_TMPDIR/repo/.claude/skills/x/SKILL.md" 'Uso: algo.')"
  assert_allowed
  decision "$(write_payload "$BATS_TEST_TMPDIR/repo/AGENTS.md" 'Uso: algo.')"
  assert_allowed
}

@test "a .prose-lint-skip marker exempts the tree below it" {
  mkdir -p "$BATS_TEST_TMPDIR/study/labs"
  touch "$BATS_TEST_TMPDIR/study/.prose-lint-skip"
  decision "$(write_payload "$BATS_TEST_TMPDIR/study/labs/README.md" '- **Tipo:** investigacao')"
  assert_allowed
}

@test "non-markdown files are ignored" {
  decision "$(write_payload "$BATS_TEST_TMPDIR/a.rb" 'Status: x')"
  assert_allowed
}

@test "publishing MCP tools are linted, including JSON-encoded bodies" {
  decision "$(mcp_payload mcp__claude_ai_Atlassian_Rovo__addCommentToJiraIssue '{"issueIdOrKey":"X-1","commentBody":"Feito — testado."}')"
  assert_denied
  decision "$(mcp_payload mcp__claude_ai_Slack__slack_send_message_draft '{"channel_id":"C1","message":"Update: ok"}')"
  assert_denied
  decision "$(mcp_payload mcp__claude_ai_Atlassian_Rovo__createConfluencePage '{"title":"x","body":"{\"type\":\"doc\",\"content\":[{\"type\":\"text\",\"text\":\"Contexto: algo.\"}]}"}')"
  assert_denied
}

@test "reading MCP tools are allowed" {
  decision "$(mcp_payload mcp__claude_ai_Atlassian_Rovo__searchJiraIssuesUsingJql '{"jql":"Status: x"}')"
  assert_allowed
}

@test "GitHub review comments are linted, file pushes are not" {
  decision "$(mcp_payload mcp__plugin_github_github__add_issue_comment '{"owner":"o","repo":"r","issue_number":1,"body":"Nota: revisar."}')"
  assert_denied
  decision "$(mcp_payload mcp__plugin_github_github__create_or_update_file '{"path":"a.md","content":"Nota: x"}')"
  assert_allowed
}

@test "Cursor payloads reaching the Claude registration stay silent" {
  decision '{"cursor_version":"1.7","tool_name":"Bash","tool_input":{"command":"slk send C1 \"Status: x\""}}'
  assert_allowed
}

cursor_decision() { run "$gate" --cursor <<<"$1"; }

cursor_permission() { jq -r '.permission' <<<"$output"; }

@test "cursor beforeShellExecution denies with an agent message" {
  cursor_decision "$(jq -nc --arg c 'slk send C1 "Status: x"' \
    '{hook_event_name: "beforeShellExecution", cursor_version: "3.4", command: $c, cwd: "/tmp"}')"
  [ "$status" -eq 0 ]
  [ "$(cursor_permission)" = deny ]
  [[ $(jq -r '.agent_message' <<<"$output") == *Conduta.Rotulo* ]]
}

@test "cursor always answers with valid JSON when allowing" {
  cursor_decision '{"hook_event_name":"beforeShellExecution","cursor_version":"3.4","command":"ls","cwd":"/tmp"}'
  [ "$(cursor_permission)" = allow ]
  cursor_decision 'not json'
  [ "$status" -eq 0 ]
  [ "$(cursor_permission)" = allow ]
}

@test "cursor beforeMCPExecution parses the JSON-string tool_input" {
  cursor_decision "$(jq -nc --arg i '{"owner":"o","repo":"r","body":"Feito — ok."}' \
    '{hook_event_name: "beforeMCPExecution", cursor_version: "3.4", mcp_server_name: "github", tool_name: "create_pull_request_review", tool_input: $i}')"
  [ "$(cursor_permission)" = deny ]
  cursor_decision "$(jq -nc --arg i '{"query":"Status: x"}' \
    '{hook_event_name: "beforeMCPExecution", cursor_version: "3.4", mcp_server_name: "github", tool_name: "search_issues", tool_input: $i}')"
  [ "$(cursor_permission)" = allow ]
}

@test "cursor preToolUse Write lints markdown content and edits" {
  cursor_decision "$(jq -nc --arg p "$BATS_TEST_TMPDIR/doc.md" \
    '{hook_event_name: "preToolUse", cursor_version: "3.4", tool_name: "Write", tool_input: {file_path: $p, content: "Contexto: algo."}}')"
  [ "$(cursor_permission)" = deny ]
  cursor_decision "$(jq -nc --arg p "$BATS_TEST_TMPDIR/doc.md" \
    '{hook_event_name: "preToolUse", cursor_version: "3.4", tool_name: "Write", tool_input: {file_path: $p, edits: [{old_string: "a", new_string: "Resumo: b"}]}}')"
  [ "$(cursor_permission)" = deny ]
  cursor_decision "$(jq -nc --arg p "$BATS_TEST_TMPDIR/a.py" \
    '{hook_event_name: "preToolUse", cursor_version: "3.4", tool_name: "Write", tool_input: {file_path: $p, content: "Status: x"}}')"
  [ "$(cursor_permission)" = allow ]
}
