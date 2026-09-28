---
name: paas-env
description: "Seta/atualiza uma ENV var numa app do rd-paas via CLI paas-env. Aceita um print do Slack ou uma linha livre. Use quando o usuário pedir para adicionar, setar, mudar ou remover uma variável de ambiente de uma app do PaaS/rd-paas."
argument-hint: "[print do Slack ou: KEY=valor na app <app> [staging|production]]"
allowed-tools:
  - Bash
  - Read
---

<objective>
Setar (criar ou atualizar) uma ENV var de uma app do rd-paas usando o CLI `paas-env`
(`~/.local/bin/paas-env`, Ruby), com o mínimo de input do operador. O operador dá o pedido
(print do Slack, path do Vault, ou uma linha livre) e esta skill extrai `app`, `KEY`, `valor`
e envs, roda o preflight e aplica.
</objective>

<rules>
Regras invioláveis:
- NUNCA inventar valor. Se o valor não veio no pedido, pergunte (ou use prompt oculto do CLI para secrets).
- NUNCA subir a VPN pelo operador. Se `doctor` acusar VPN caída, avise e PARE.
- SEMPRE default = **staging E production** (as duas). Só limita a um único env se O OPERADOR (o usuário desta sessão) disser EXPLICITAMENTE "só staging" / "só production". Um terceiro no pedido (ex.: o requester do Slack mencionar `/production` no path) NÃO limita o escopo — só a instrução explícita do operador limita. Na dúvida, faça as duas.
- Preflight é `--dry-run` e SÓ ele para status/plano. O plano já mostra o status por env (`[CREATE]`, `[UPDATE]`, `[UNCHANGED]`) e se a app está no filtro do bot (2 ou 4 escritas). Não rode `get` para "descobrir se é update" — é redundante. Única exceção: se o dry-run acusar UPDATE, um `get` ANTES de escrever para guardar o valor antigo (revert só existe se capturado antes da escrita). Nada além disso.
- Escrita usa `kv patch` (preserva as outras chaves) com read-back. Nunca sugerir `put`.
</rules>

<input_parsing>
Extraia do pedido, sem perguntar o que já dá para inferir:
- **app**: o nome da PASTA no Vault. No print do Slack costuma vir no path `.../apps/<app>/<env>` (ex.: `productivity/devexp/rd-paas/apps/objects-importer/production` → app `objects-importer`). Pode diferir do nome de exibição.
- **KEY**: nome da env (ex.: `REDIS_URL`).
- **valor**: o valor pedido. Se ausente e não for secret, pergunte; se for secret, use o prompt oculto do CLI.
- **envs**: default ambos. Ver regra acima — o `/production` do path do requester é só onde ele quer, não uma instrução para restringir.

Se faltar app, KEY ou (valor não-secret), pergunte só o que faltou. Não peça mount/path/detalhe de Vault.
</input_parsing>

<procedure>
1. **doctor** — `paas-env doctor`. Se VPN/reachability FAIL, avise o operador para subir a VPN (`! sudo <vpn>`) e PARE. Se auth FAIL, o próprio CLI dispara o `vault login -method=oidc` na hora do set (o operador roda via `!`).

2. **dry-run** — `paas-env set <app> <KEY> -v '<valor>' [--env <env>] --dry-run`.
   Mostre o plano ao operador. Aponte em uma linha:
   - se é CREATE ou UPDATE (UPDATE = a key já existia; vale sinalizar);
   - se são 2 ou 4 escritas (app no `OVERRIDE_FILTER` do bot);
   - o escopo de envs aplicado.
   Se algum env vier `[UNCHANGED]`, diga — o valor pedido já é o atual ali.
   Se vier UPDATE, capture o valor antigo agora (`paas-env get <app> <KEY>`), só para o revert.

3. **aplicar** — `paas-env set <app> <KEY> -v '<valor>' [--env <env>] -y`.
   (`-y` pula o prompt interativo do CLI, que travaria no Bash.) O CLI faz backup do filtro e read-back.

4. **read-back** — mostre o resultado final. O output do próprio set já confirma "written and verified"; se quiser reforçar, `paas-env get <app> <KEY>`.

5. **fechamento** — se foi UPDATE, informe o revert pronto com o valor capturado no passo 2: `paas-env set <app> <KEY> -v '<valor_antigo>'`. Se foi CREATE, não há revert (a key não existia).
</procedure>

<notes>
- Comandos e semântica do CLI: `paas-env <set|get|doctor|list> --help`. Sem `--env` = staging E production.
- Valor pode vir via `-v`, stdin (`echo -n secret | paas-env set app KEY`) ou prompt oculto.
- Escopo do CLI é SÓ apps do PaaS. Para stores fora do rd-paas (ex.: `secret/rdsm/*`), esta skill não serve.
</notes>
