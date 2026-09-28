#!/usr/bin/env python3
"""
Cria uma issue no Jira (DELIVPLAT) a partir de um JSON de entrada.

Uso:
    python3 create_jira_task.py <caminho_para_input.json>

Formato do JSON de entrada:
{
  "titulo": "Título da tarefa",
  "issue_type_id": "10002",
  "priority_id": "10003",
  "epic_key": "DELIVPLAT-123",        // opcional, null para omitir
  "contexto": "Cenário atual...",
  "impacto": "Problema que causa...",
  "objetivo": "O que será feito...",
  "criterios": ["Critério 1", "Critério 2"],
  "cenarios": ["Validação 1", "Validação 2"],
  "monitoramento": ["Ação 1", "Métrica 1"]
}
"""

import json
import os
import sys
import uuid
import base64
import urllib.request
import urllib.error


def load_config():
    config = {}
    config_path = os.path.expanduser("~/.jira_config")
    with open(config_path) as f:
        for line in f:
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                config[k.strip()] = v.strip()
    return config


def make_headers(email, token):
    auth = base64.b64encode(f"{email}:{token}".encode()).decode()
    return {
        "Authorization": f"Basic {auth}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }


def api_request(url, headers, payload=None, method=None):
    data = json.dumps(payload).encode() if payload else None
    if method is None:
        method = "POST" if data else "GET"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            body = resp.read()
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"ERRO HTTP {e.code}: {body}", file=sys.stderr)
        sys.exit(1)


def task_list(items):
    return {
        "type": "taskList",
        "attrs": {"localId": str(uuid.uuid4())},
        "content": [
            {
                "type": "taskItem",
                "attrs": {"localId": str(uuid.uuid4()), "state": "TODO"},
                "content": [{"type": "text", "text": item}],
            }
            for item in items
        ],
    }


def panel(panel_type, title):
    return {
        "type": "panel",
        "attrs": {"panelType": panel_type},
        "content": [
            {
                "type": "heading",
                "attrs": {"level": 3},
                "content": [{"type": "text", "text": title}],
            }
        ],
    }



def bullet_list_bold(items):
    return {
        "type": "bulletList",
        "content": [
            {
                "type": "listItem",
                "content": [
                    {
                        "type": "paragraph",
                        "content": [
                            {"type": "text", "text": f"{label}{value}"},
                        ],
                    }
                ],
            }
            for label, value in items
        ],
    }


def build_description(data):
    return {
        "type": "doc",
        "version": 1,
        "content": [
            panel("error", "Problema"),
            bullet_list_bold(
                [
                    ("Contexto: ", data["contexto"]),
                    ("Impacto: ", data["impacto"]),
                    ("Objetivo: ", data["objetivo"]),
                ]
            ),
            panel("success", "Definição de pronto"),
            task_list(data["criterios"]),
            panel("note", "Cenários de teste"),
            task_list(data["cenarios"]),
            panel("info", "Monitoramento pós-deploy"),
            task_list(data["monitoramento"]),
        ],
    }


def main():
    if len(sys.argv) != 2:
        print("Uso: python3 create_jira_task.py <input.json>", file=sys.stderr)
        sys.exit(1)

    with open(sys.argv[1]) as f:
        data = json.load(f)

    config = load_config()
    email = config["JIRA_EMAIL"]
    token = config["JIRA_TOKEN"]
    base_url = config["JIRA_BASE_URL"]
    headers = make_headers(email, token)

    payload = {
        "fields": {
            "project": {"key": "DELIVPLAT"},
            "summary": data["titulo"],
            "issuetype": {"id": data["issue_type_id"]},
            "priority": {"id": data["priority_id"]},
            "description": build_description(data),
            "reporter": {"id": "712020:06816111-9484-40a1-b7ce-fb3570c22424"},
        }
    }

    if data.get("epic_key"):
        payload["fields"]["parent"] = {"key": data["epic_key"]}

    result = api_request(f"{base_url}/rest/api/3/issue", headers, payload)
    issue_key = result["key"]
    print(f"Issue criada: {issue_key}")

    transitions = api_request(
        f"{base_url}/rest/api/3/issue/{issue_key}/transitions", headers
    )

    prioritized_id = None
    for t in transitions["transitions"]:
        if t["to"].get("id") == "10020" or "prioritized" in t["name"].lower():
            prioritized_id = t["id"]
            break

    if prioritized_id:
        api_request(
            f"{base_url}/rest/api/3/issue/{issue_key}/transitions",
            headers,
            {"transition": {"id": prioritized_id}},
        )
        print("Status: Prioritized")
    else:
        available = [t["name"] for t in transitions["transitions"]]
        print(f"AVISO: transição para Prioritized não encontrada. Disponíveis: {available}")

    print(f"URL: {base_url}/browse/{issue_key}")


if __name__ == "__main__":
    main()
