#!/usr/bin/env python3
"""Allow `git checkout` only when every checkout in the command runs inside the
klaudia scratch under /tmp. Anything it cannot prove stays with the settings
rule `Bash(git checkout:*)`, which asks. Authorized by Highlander 2026-09-24
('sim e libera') so seats stop stalling when they run ci on an isolated clone;
the shared checkout must keep asking, because a checkout there can discard
another seat's uncommitted work."""
import json
import os
import re
import shlex
import sys

ROOT = "/tmp/claude-1001/-home-hvpaiva-dev-personal-klaudia/"
SEPARATORS = {";", "&&", "||", "|", "&", "\n"}
ASSIGN = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
VAR = re.compile(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?")
UNSAFE_GIT_OPTS = ("--git-dir", "--work-tree")


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


def resolve(raw, env, cwd):
    """An absolute real path, or None when it cannot be known statically."""
    if cwd is None or "`" in raw or "$(" in raw or any(c in raw for c in "*?[]~"):
        return None
    unresolved = False

    def sub(match):
        nonlocal unresolved
        if match.group(1) not in env:
            unresolved = True
            return ""
        return env[match.group(1)]

    value = VAR.sub(sub, raw)
    if unresolved or "$" in value:
        return None
    return os.path.realpath(os.path.join(cwd, value))


def inside_scratch(path):
    return path is not None and path.startswith(ROOT)


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
    mentions = len(re.findall(r"\bcheckout\b", command))
    if mentions == 0:
        return
    cwd = data.get("cwd") or None
    env = {}
    validated = 0
    try:
        parts = list(segments(command))
    except ValueError:
        return
    for tokens in parts:
        while tokens and ASSIGN.match(tokens[0]):
            name, value = ASSIGN.match(tokens[0]).groups()
            if "$" in value or "`" in value:
                env.pop(name, None)
            else:
                env[name] = value
            tokens = tokens[1:]
        if not tokens:
            continue
        # A subshell or group would hide its own cd from this tracker.
        if tokens[0].startswith("(") or tokens[0] in ("{", "pushd", "popd"):
            return
        if tokens[0] == "cd":
            cwd = resolve(tokens[1], env, cwd) if len(tokens) > 1 else None
            continue
        if os.path.basename(tokens[0]) != "git":
            continue
        where = cwd
        i = 1
        while i < len(tokens) and tokens[i].startswith("-"):
            opt = tokens[i]
            if opt.startswith(UNSAFE_GIT_OPTS):
                return
            if opt == "-C" and i + 1 < len(tokens):
                where = resolve(tokens[i + 1], env, where)
                i += 2
                continue
            if opt == "-c" and i + 1 < len(tokens):
                i += 2
                continue
            i += 1
        if i < len(tokens) and tokens[i] == "checkout":
            if not inside_scratch(where):
                return
            validated += 1
    # Every mention of checkout must be one this tracker proved safe; a hidden
    # one (inside $(...), an alias, a string) leaves the decision to the rule.
    if validated and validated == mentions:
        decide("allow", "git checkout confined to the klaudia scratch under /tmp")


if __name__ == "__main__":
    main()
