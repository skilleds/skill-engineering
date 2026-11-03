---
description: Gera o relatório de ritmo (30 min) em <projeto>_archive/relatorios/ e atualiza .ritmo.json
argument-hint: "[nota opcional]"
---

Gere o **relatório de ritmo** (piso 26, `orquestracao.md` §9.8). Não pergunte nada ao usuário: só faça.

1. Arquivo `<projeto>/<projeto>_archive/relatorios/AAAA-MM-DD_HHMM.md` (hora local agora). Crie a pasta se faltar.
2. Seções curtas (1-3 linhas; inclua **Custo**: trecho do período e acumulado de `<projeto>_archive/custos/custos.json` após `schematize cost sync && schematize cost report`, "estimativa API-equivalente; confira o /usage"): **Feito** (commits/SHAs desde o último relatório, `git log`), **Em andamento**, **Bloqueios / on-hold** (`[H ]`, `[~]`), **Próximos passos**, **Agents vivos** (`ListAgents`; encerre os sem pendência, piso 25), **Desvios**, **Higiene e recursos** (piso 29: disco antes/depois, o que `scripts/higiene.sh` liberou e, havendo máquina dev/hml, o que foi enviado/rodado nela; rode a higiene se houve build e ainda não foi feita). Use $ARGUMENTS como nota.
3. Atualize `<projeto>_archive/.ritmo.json` com `ultimo_relatorio` (ISO-8601 agora); mantenha `ultimo_handoff`. Se 6 h de trabalho ativo desde o último handoff, rode também `/eng-handoff` e atualize `ultimo_handoff`.
4. Commit + push na hora (piso 22). Sem segredo/PII (§16.1).
