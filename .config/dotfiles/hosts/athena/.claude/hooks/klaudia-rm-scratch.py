#!/usr/bin/env python3
import json
import os
import re
import shlex
import sys

ROOT = "/tmp/claude-1001/-home-hvpaiva-dev-personal-klaudia/"
SEPARATORS = {";", "&&", "||", "|", "&", "\n"}
ASSIGN = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
VAR = re.compile(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?")


def segments(command):
    lexer = shlex.shlex(command.replace("\n", " ; "), posix=True, punctuation_chars=";&|")
    lexer.whitespace_split = True
    current = []
    for token in lexer:
        if token in SEPARATORS:
            if current:
                yield current
            current = []
        else:
            current.append(token)
    if current:
        yield current


def is_recursive_force(flags):
    letters = "".join(f[1:] for f in flags if f.startswith("-") and not f.startswith("--"))
    longs = {f for f in flags if f.startswith("--")}
    recursive = "r" in letters or "R" in letters or "--recursive" in longs
    force = "f" in letters or "--force" in longs
    return recursive and force


def safe_target(raw, env):
    if "`" in raw or "$(" in raw or any(c in raw for c in "*?[]~"):
        return False
    unresolved = False

    def sub(match):
        nonlocal unresolved
        if match.group(1) not in env:
            unresolved = True
            return ""
        return env[match.group(1)]

    value = VAR.sub(sub, raw)
    if unresolved or "$" in value or ".." in value.split("/"):
        return False
    path = os.path.realpath(value)
    return path.startswith(ROOT) and path != ROOT.rstrip("/")


def decide(decision, reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": reason,
        }
    }))


def main():
    data = json.load(sys.stdin)
    if data.get("tool_name") != "Bash":
        return
    command = data.get("tool_input", {}).get("command", "")
    if not re.search(r"\brm\b", command):
        return
    env = {}
    found = False
    try:
        parts = list(segments(command))
    except ValueError:
        decide("ask", "rm in a command the scratch guard cannot parse")
        return
    for tokens in parts:
        while tokens and ASSIGN.match(tokens[0]):
            name, value = ASSIGN.match(tokens[0]).groups()
            if "$" in value or "`" in value:
                env.pop(name, None)
            else:
                env[name] = value
            tokens = tokens[1:]
        starts = [i for i, t in enumerate(tokens) if os.path.basename(t) == "rm"]
        if not starts:
            continue
        args = tokens[starts[0] + 1:]
        flags = [a for a in args if a.startswith("-") and a != "--"]
        targets = [a for a in args if not a.startswith("-")]
        if not is_recursive_force(flags):
            continue
        found = True
        if not targets or not all(safe_target(t, env) for t in targets):
            decide("ask", "rm -rf outside the klaudia scratch under /tmp")
            return
    if found:
        decide("allow", "rm -rf confined to the klaudia scratch under /tmp")


if __name__ == "__main__":
    main()
