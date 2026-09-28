#!/usr/bin/env bash
set -uo pipefail

payload=$(cat)
[ -n "$(printf '%s' "$payload" | jq -r '.cursor_version // empty')" ] && exit 0
tool=$(printf '%s' "$payload" | jq -r '.tool_name // ""')

deny() {
  jq -nc --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

MSG_MCP='Escrita no Slack pela integracao esta bloqueada: essas mensagens sairiam marcadas como enviadas pelo Claude, que e exatamente o que o usuario nao quer. Leitura continua liberada.

Para enviar de verdade, use o Bash:
  slk send <CANAL_OU_DM_ID> "texto"
  slk send <CANAL_ID> --thread <TS_DA_MENSAGEM_PAI> "texto"

Isso envia pelo Slack web do proprio usuario, aparece como ele e sem badge de app. Os ids (C..., D..., G...) e o ts da thread voce obtem com as ferramentas de leitura do Slack, que continuam liberadas. Id de usuario (U...) nao serve e o slk recusa: para DM, use o id D... da conversa.

Se o comando sair com 3, o envio esta desligado. Nao tente contornar. O caminho normal e enfileirar: `slk queue <ID> "texto"`, que sai com 8, e depois avisar que basta rodar `slk queue approve <n>`. Abrir a trava (`slk lock open`) e a outra opcao, e so o usuario pode. Se a recusa citar um lease ou uma aprovacao em andamento, a trava esta aberta para um comando especifico: enfileirar continua funcionando.'

MSG_BASH='Chamada direta de escrita na API do Slack bloqueada. Use `slk send <ID> [--thread <TS>] "texto"`, que envia como o proprio usuario.'

MSG_PROFILE='Acesso direto ao perfil do navegador do slk bloqueado. Esse perfil e a credencial de sessao do usuario e nao deve ser copiado, movido nem usado fora do comando slk.'

case "$tool" in
  mcp__*[Ss]lack*__* | mcp__*[Ss]LACK*__*)
    op=${tool##*__}
    case "$op" in
      *read_* | *search_* | *list_* | *get_* | *_history | *_info | *_replies | *_members | *_view | *_profile)
        exit 0
        ;;
      *send_message_draft | *add_reaction | *remove_reaction | *create_canvas | *update_canvas)
        exit 0
        ;;
    esac
    deny "$MSG_MCP"
    ;;
  Bash | BashOutput)
    cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
    if printf '%s' "$cmd" | grep -qE 'hooks\.slack\.com|slack\.com/api/(chat\.|files\.upload|files\.completeUpload|files\.getUploadURL|reactions\.add|reactions\.remove|pins\.add|bookmarks\.add|conversations\.(create|invite|kick|archive|rename|setTopic|setPurpose)|admin\.|assistant\.threads\.setStatus)'; then
      deny "$MSG_BASH"
    fi
    if printf '%s' "$cmd" | grep -qE '(cp|rsync|tar|zip|mv|ln|cat|base64|scp)[^|;]*(slk|slack-web-send)/profile|(slk|slack-web-send)/profile[^|;]*(cp|rsync|tar|zip|scp)|user-data-dir=[^ ]*(slk|slack-web-send)'; then
      deny "$MSG_PROFILE"
    fi
    ;;
esac

exit 0
