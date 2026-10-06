#!/usr/bin/env python3
"""Blocks outgoing prose that breaks the Conduta writing rules (Vale via prose-lint) before it leaves."""
import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

os.environ["PATH"] = ":".join([
    os.path.expanduser("~/.local/share/mise/shims"),
    os.path.expanduser("~/.local/bin"),
    os.environ.get("PATH", "/usr/local/bin:/usr/bin:/bin"),
])

SKIP_MARKER = ".prose-lint-skip"
AGENT_DIRS = {".claude", ".cursor"}
AGENT_FILES = {"CLAUDE.md", "CLAUDE.local.md", "AGENTS.md", "GEMINI.md", "SKILL.md"}
MD_SUFFIXES = {".md", ".markdown"}

PROSE_KEYS = {
    "text", "message", "body", "content", "markdown", "comment", "commentbody",
    "description", "summary", "title", "subject", "payload",
}
PUBLISHING_MCP = [
    (re.compile(r"slack", re.I), re.compile(r"send|post|reply|schedule|canvas", re.I)),
    (re.compile(r"atlassian|jira|confluence", re.I), re.compile(r"^(create|update|edit|add)", re.I)),
    (re.compile(r"gmail", re.I), re.compile(r"^(send|create_draft|update_draft|reply|forward)", re.I)),
    (re.compile(r"claude_docs", re.I), re.compile(r"^(batch|create|update)$", re.I)),
    (re.compile(r"google_drive", re.I), re.compile(r"^(create|update)_file$", re.I)),
    (re.compile(r"notion", re.I), re.compile(r"create|update|append|comment", re.I)),
    (re.compile(r"github", re.I), re.compile(r"comment|review|^(create|update)_(issue|pull_request)$", re.I)),
]

HEREDOC = re.compile(
    r"<<-?[ \t]*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1[^\n]*\n(.*?)\n[ \t]*\2[ \t]*(?=\n|$)", re.S
)
MARKER = re.compile(r"__PROSE_HEREDOC_(\d+)__")
OPERATORS = {";", "&&", "||", "|", "&", "(", ")", ";;", "|&"}
GH_TEXT_FLAGS = {"--body": "body", "-b": "body", "--title": "title", "-t": "title"}
GH_FILE_FLAGS = {"--body-file", "-F"}


def segments(command):
    bodies = []

    def hide(match):
        bodies.append(match.group(3))
        return f" __PROSE_HEREDOC_{len(bodies) - 1}__ "

    flat = HEREDOC.sub(hide, command)
    lexer = shlex.shlex(flat, posix=True, punctuation_chars=";&|()")
    lexer.whitespace_split = True
    try:
        tokens = list(lexer)
    except ValueError:
        return [], bodies

    result, current, piped = [], [], False
    for token in tokens:
        if token in OPERATORS:
            if current:
                result.append((current, piped))
            current, piped = [], token == "|"
        else:
            current.append(token)
    if current:
        result.append((current, piped))
    return result, bodies


def resolve(token, bodies):
    found = [bodies[int(i)] for i in MARKER.findall(token)]
    if found:
        return "\n\n".join(found)
    if "$(" in token or "`" in token:
        return None
    return token


def stdin_text(args, previous, bodies):
    for token in args:
        if MARKER.search(token):
            return resolve(token, bodies)
    if previous and Path(previous[0]).name in {"echo", "printf"}:
        words = [t for t in previous[1:] if not t.startswith("-")]
        resolved = [resolve(t, bodies) for t in words]
        return " ".join(t for t in resolved if t) or None
    return None


def slk_texts(args, previous, bodies):
    if not args or args[0] not in {"send", "queue"}:
        return []
    positional, rest, i = [], args[1:], 0
    while i < len(rest):
        token = rest[i]
        if token == "--":
            positional.extend(rest[i + 1:])
            break
        if token == "--thread":
            i += 2
            continue
        if token.startswith("-") and not MARKER.search(token):
            i += 1
            continue
        positional.append(token)
        i += 1
    if not positional or (args[0] == "queue" and positional[0] in {"list", "approve", "drop"}):
        return []
    text = resolve(" ".join(positional[1:]), bodies) if len(positional) > 1 else None
    text = text or stdin_text(rest, previous, bodies)
    return [(f"slk {args[0]}", text)] if text else []


def gh_texts(args, previous, bodies, cwd):
    if len(args) < 2 or args[0] not in {"pr", "issue"} or args[1] not in {"create", "edit", "comment", "review"}:
        return []
    found, i = [], 2
    while i < len(args):
        token = args[i]
        flag, _, inline = token.partition("=")
        value = inline if inline else (args[i + 1] if i + 1 < len(args) else None)
        step = 1 if inline else 2
        if flag in GH_TEXT_FLAGS and value is not None:
            text = resolve(value, bodies)
            if text:
                found.append((f"gh {args[0]} {args[1]} {GH_TEXT_FLAGS[flag]}", text))
            i += step
            continue
        if flag in GH_FILE_FLAGS and value is not None:
            if value == "-":
                text = stdin_text(args[i + step:], previous, bodies)
            else:
                path = Path(cwd, value) if cwd else Path(value)
                text = path.read_text(encoding="utf-8") if path.is_file() else None
            if text:
                found.append((f"gh {args[0]} {args[1]} body", text))
            i += step
            continue
        i += 1
    return found


def shell_texts(command, cwd):
    found, previous = [], None
    parsed, bodies = segments(command)
    for tokens, piped in parsed:
        program = Path(tokens[0]).name
        before = previous if piped else None
        if program == "slk":
            found += slk_texts(tokens[1:], before, bodies)
        elif program == "gh":
            found += gh_texts(tokens[1:], before, bodies, cwd)
        previous = tokens
    return found


def json_texts(value, key=""):
    if isinstance(value, str):
        if key.lower() in PROSE_KEYS:
            try:
                nested = json.loads(value)
            except (json.JSONDecodeError, ValueError):
                return [value]
            return json_texts(nested) if isinstance(nested, (dict, list)) else [value]
        return []
    if isinstance(value, dict):
        return [t for k, v in value.items() for t in json_texts(v, k)]
    if isinstance(value, list):
        return [t for v in value for t in json_texts(v, key)]
    return []


def is_publishing_mcp(server, operation):
    return any(s.search(server) and o.search(operation) for s, o in PUBLISHING_MCP)


def lintable_md(path):
    p = Path(os.path.expanduser(path))
    if p.suffix.lower() not in MD_SUFFIXES or p.name in AGENT_FILES:
        return False
    if AGENT_DIRS & set(p.parts):
        return False
    return not any((d / SKIP_MARKER).exists() for d in p.absolute().parents)


def file_texts(path, contents):
    if not path or not lintable_md(path):
        return []
    return [(f"arquivo {path}", c) for c in contents if c]


def lint(text):
    result = subprocess.run(["prose-lint"], input=text, capture_output=True, text=True)
    return result.stdout.strip() if result.returncode != 0 else ""


def violations(texts):
    report = []
    for source, text in texts:
        out = lint(text)
        if out:
            report.append(f"[{source}]\n{out}")
    return report


def reason(report):
    return (
        "Texto que vai ser enviado viola a regra de escrita da 00-conduta.mdc (sem travessao, "
        "sem rotulo seguido de dois pontos). Corrija so as ocorrencias abaixo (linha:coluna:regra, "
        "contadas dentro de cada trecho) e tente de novo:\n\n" + "\n\n".join(report)
    )


def claude_texts(payload):
    tool = payload.get("tool_name") or ""
    data = payload.get("tool_input") or {}
    if tool == "Bash":
        return shell_texts(data.get("command") or "", payload.get("cwd"))
    if tool == "Write":
        return file_texts(data.get("file_path"), [data.get("content")])
    if tool == "Edit":
        return file_texts(data.get("file_path"), [data.get("new_string")])
    if tool == "MultiEdit":
        return file_texts(data.get("file_path"), [e.get("new_string") for e in data.get("edits") or []])
    if tool.startswith("mcp__"):
        _, server, operation = (tool.split("__", 2) + ["", ""])[:3]
        if is_publishing_mcp(server, operation):
            return [(tool, t) for t in json_texts(data)]
    return []


def cursor_event(payload):
    event = payload.get("hook_event_name") or ""
    if event:
        return event
    if "mcp_server_name" in payload or isinstance(payload.get("tool_input"), str):
        return "beforeMCPExecution"
    if "command" in payload and "tool_name" not in payload:
        return "beforeShellExecution"
    return "preToolUse"


def cursor_texts(payload):
    event = cursor_event(payload)
    if event == "beforeShellExecution":
        return shell_texts(payload.get("command") or "", payload.get("cwd"))
    if event == "beforeMCPExecution":
        raw = payload.get("tool_input") or "{}"
        try:
            data = json.loads(raw) if isinstance(raw, str) else raw
        except json.JSONDecodeError:
            return []
        server = payload.get("mcp_server_name") or ""
        tool = payload.get("tool_name") or ""
        if is_publishing_mcp(server or tool, tool):
            return [(f"{server}/{tool}", t) for t in json_texts(data)]
        return []
    if event == "preToolUse" and payload.get("tool_name") == "Write":
        data = payload.get("tool_input") or {}
        contents = [data.get("content"), data.get("contents"), data.get("new_string")]
        contents += [e.get("new_string") for e in data.get("edits") or [] if isinstance(e, dict)]
        return file_texts(data.get("file_path") or data.get("path"), contents)
    return []


def claude_reply(report):
    if report:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason(report),
            }
        }))


def cursor_reply(report):
    if report:
        print(json.dumps({
            "permission": "deny",
            "user_message": "prose-send-gate bloqueou o envio: o texto viola a regra de escrita da conduta.",
            "agent_message": reason(report),
        }))
    else:
        print(json.dumps({"permission": "allow"}))


def main():
    native_cursor = "--cursor" in sys.argv[1:]
    try:
        payload = json.load(sys.stdin)
        if native_cursor:
            report = violations(cursor_texts(payload))
        elif payload.get("cursor_version"):
            return
        else:
            report = violations(claude_texts(payload))
    except Exception:
        report = []
    (cursor_reply if native_cursor else claude_reply)(report)


if __name__ == "__main__":
    main()
