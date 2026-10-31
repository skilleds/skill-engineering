---
description: Gera o relatório de ritmo (30 min) em <projeto>_archive/relatorios/ e atualiza .ritmo.json
argument-hint: "[nota opcional]"
---

Gere o **relatório de ritmo** (piso 26, `orquestracao.md` §9.8). Não pergunte nada ao usuário: só faça.

1. Arquivo `<projeto>/<projeto>_archive/relatorios/AAAA-MM-DD_HHMM.md` (hora local agora). Crie a pasta se faltar.
2. Seções curtas (1-3 linhas): **Feito** (commits/SHAs desde o último relatório, `git log`), **Em andamento**, **Bloqueios / on-hold** (`[H ]`, `[~]`), **Próximos passos**, **Agents vivos** (`ListAgents`; encerre os sem pendência, piso 25), **Desvios**. Use $ARGUMENTS como nota.
3. Atualize `<projeto>_archive/.ritmo.json` com `ultimo_relatorio` (ISO-8601 agora); mantenha `ultimo_handoff`. Se 6 h de trabalho ativo desde o último handoff, rode também `/eng-handoff` e atualize `ultimo_handoff`.
4. Commit + push na hora (piso 22). Sem segredo/PII (§16.1).
