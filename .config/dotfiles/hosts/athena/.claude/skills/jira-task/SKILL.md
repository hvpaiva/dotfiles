---
name: jira-task
description: "Cria uma task no Jira (DELIVPLAT) com template padrão e formatação ADF, coletando todas as informações necessárias via conversa."
argument-hint: "[descrição inicial da tarefa]"
allowed-tools:
  - Bash
  - Read
---

<objective>
Guiar o usuário passo a passo para coletar todas as informações necessárias para criar uma task no Jira (projeto DELIVPLAT), depois criá-la via API com o template padrão de descrição e transicioná-la para o status "Prioritized".

**Regras invioláveis:**
- NUNCA inventar, inferir ou assumir qualquer valor que o usuário não informou explicitamente
- NUNCA preencher um placeholder do template sem ter o valor real do usuário
- SEMPRE perguntar quando qualquer informação obrigatória estiver faltando ou ambígua
- Perguntar uma seção por vez — não sobrecarregar o usuário com tudo de uma vez
- Se invocado sem argumentos ou com informação insuficiente, começar coletando as informações desde o início
</objective>

<jira_metadata>
Credenciais: source ~/.jira_config
Reporter (sempre fixo): accountId = 712020:06816111-9484-40a1-b7ce-fb3570c22424 (Highlander Paiva)
Assignee: sempre vazio (unassigned)
Projeto: DELIVPLAT
Status após criação: sempre transicionar para "Prioritized"
Sprint: não usar — o time não tem sprint

Tipos de issue e IDs:
- Tarefa: 10002
- Bug: 10004
- História: 10006
- Tech Debt: 10005
- Operation: 10012
- Incident: 10013
- Research: 10024
- Design: 10015

Prioridades e IDs:
- Médio: 10003
- Alto: 10004
- Crítica: 10001
- Low: 4
- Expedite: 10000
</jira_metadata>

<context>
$ARGUMENTS
</context>

<process>

## Fase 1: Entender a tarefa

**Se $ARGUMENTS estiver vazio ou insuficiente**, abrir com uma única pergunta aberta:

> "Me conta sobre a tarefa — o que precisa ser feito, qual o problema e por que é importante?"

**Se $ARGUMENTS já trouxer contexto**, usar como ponto de partida — não repetir o que já foi explicado.

### Regra central: derive primeiro, pergunte só o que falta

A partir do que o usuário descreveu, extrair o máximo possível **sem perguntar**:
- **Título**: sintetizar em uma frase curta com base na descrição
- **Contexto / Impacto / Objetivo**: extrair diretamente do texto quando claro
- **Tipo**: inferir quando óbvio ("bug" → Bug, "investigar/pesquisar" → Research, "implementar/criar" → Tarefa) — só perguntar se genuinamente ambíguo
- **Prioridade**: inferir se mencionada ("urgente" → Alto, "crítico" → Crítica) — caso contrário assumir Médio sem perguntar, o usuário ajusta no preview
- **Critérios de entrega / Cenários de teste / Monitoramento**: derivar do contexto quando possível — só perguntar o que ficou vago ou ausente

**O único campo que sempre precisa ser perguntado é o épico pai** — pois requer escolha de uma lista. Buscar e exibir os épicos junto com qualquer outra dúvida restante, tudo em uma única mensagem:

```bash
source ~/.jira_config
AUTH=$(echo -n "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64 -w 0)
curl -s -H "Authorization: Basic ${AUTH}" -H "Accept: application/json" \
  "https://rdstation.atlassian.net/rest/api/3/search?jql=project%3DDELIVPLAT%20AND%20issuetype%3DEpico%20AND%20statusCategory%20not%20in%20(Done)&fields=summary,key&maxResults=50" | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
for i, issue in enumerate(data.get('issues', []), 1):
    print(f\"{i}. [{issue['key']}] {issue['fields']['summary']}\")
"
```

Se o usuário disser "nenhum" / "sem épico" / "none", não preencher o campo parent.

**Consolidar todas as dúvidas em no máximo uma mensagem.** Se não houver nenhuma além do épico, perguntar só o épico. Nunca fazer múltiplas rodadas de perguntas isoladas.

O preview (Fase 2) serve como validação final — o usuário pode corrigir qualquer campo lá, então não é necessário confirmar cada inferência antes.

---

## Fase 2: Preview para validação

Após coletar TODAS as informações, exibir um resumo completo formatado para o usuário revisar ANTES de criar qualquer coisa no Jira:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PREVIEW DA TASK — revise antes de confirmar
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Título:    <titulo>
Tipo:      <tipo>
Prioridade: <prioridade>
Épico pai: <chave do épico> — <título do épico> (ou "Nenhum")

─── 🔴 Problema ───────────────────────────────
  Contexto:  <contexto>
  Impacto:   <impacto>
  Objetivo:  <objetivo>

─── 🟢 Definição de pronto ────────────────────
  [ ] <critério 1>
  [ ] <critério 2>
  ...

─── 🟣 Cenários de teste ──────────────────────
  [ ] <cenário 1>
  [ ] <cenário 2>
  ...

─── 🔵 Monitoramento pós-deploy ───────────────
  [ ] <ação 1>
  [ ] <ação 2>
  ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Criar essa task no Jira? (sim / não / editar <campo>)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Aguardar resposta do usuário:
- **"sim"** → prosseguir para Fase 3
- **"não"** → encerrar sem criar nada
- **"editar <campo>"** → perguntar o novo valor daquele campo, atualizar o preview e mostrar novamente antes de prosseguir

---

## Fase 3: Criar a issue

Somente após confirmação explícita ("sim"):

1. Montar o JSON de entrada com os valores coletados e salvar em `/tmp/jira_task_input.json`:

```json
{
  "titulo": "<titulo>",
  "issue_type_id": "<id do tipo>",
  "priority_id": "<id da prioridade>",
  "epic_key": "<DELIVPLAT-XXX ou null>",
  "contexto": "<contexto>",
  "impacto": "<impacto>",
  "objetivo": "<objetivo>",
  "criterios": ["<critério 1>", "<critério 2>"],
  "cenarios": ["<cenário 1>", "<cenário 2>"],
  "monitoramento": ["<ação 1>", "<métrica 1>"]
}
```

2. Executar o script fixo:

```bash
python3 ~/.claude/skills/jira-task/create_jira_task.py /tmp/jira_task_input.json
```

3. Exibir para o usuário a saída do script:
- Chave da issue criada (ex: DELIVPLAT-XXXX)
- Confirmação do status Prioritized
- Link direto para a issue no Jira

</process>

<notes>
- Credenciais em ~/.jira_config — sempre fazer `source` antes de qualquer chamada Bash
- Reporter sempre fixo: Highlander Paiva (accountId: 712020:06816111-9484-40a1-b7ce-fb3570c22424)
- Assignee sempre vazio
- Sprint: não preencher — o time não usa
- Os taskItems do ADF precisam de UUIDs únicos — gerar com uuid.uuid4() a cada execução
- O status padrão de criação no Jira não é Prioritized — sempre transicionar após criar
- Se a transição falhar, avisar o usuário em vez de silenciar o erro
</notes>
