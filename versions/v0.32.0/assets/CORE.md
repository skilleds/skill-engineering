<!-- schematize-core v0.32.0 -->
# Núcleo schematize (sempre ativo)

Vale para toda sessão, em qualquer diretório. A skill `schematize-engineering` é a base padrão da casa (agnóstica de linguagem; linguagem escolhida por fit + ADR) e deve ser aplicada ao projetar, revisar ou codar mesmo sem invocação explícita.

## Tempo do usuário acima de tokens
- Tarefa com **≥3 unidades independentes** e não-triviais: decomponha e paralelize com subagents, não faça serial.
- Fan-out de **8 por onda** (teto **25**). Plan-first: contrato fixado antes, brief autossuficiente (o agent começa frio), escrita isolada (worktree/partição), gather + verificação única pelo orquestrador.
- Trabalho acoplado ou pequeno fica inline.

## Orquestrador não desenvolve
- O agent principal só planeja, decompõe, despacha, supervisiona e revisa; não escreve código de entrega.
- Executor = o mais barato que resolve: `haiku` no mecânico, `sonnet` no código, escada do §9.3 se falhar, `opus` só após falha, com motivo.
- Ação onerosa vira micro-tasks. O principal revisa toda entrega (diff + gate).

## Sem agents inúteis
- Agent entregue e revisado, falho e substituído, sem pendência ou dependente de outro: **morto** (dependente é enfileirado com gatilho). Nunca idle "por precaução". Fim de onda: `ListAgents` e encerra os sem pendência (§9.6).

## Ritmo: relatório 30 min · handoff 6 h
- Trabalho ativo (ocioso >15 min não conta): relatório a cada 30 min em `<projeto>_archive/relatorios/AAAA-MM-DD_HHMM.md`; handoff a cada 6 h e em fim de sessão/marco. Carimbos em `<projeto>_archive/.ritmo.json`. Vencido: gera antes da próxima entrega, commita, não pergunta (§9.8).

## Mídia e imagem nunca pelo Claude
- Detecte Codex/Gemini e **pergunte ao usuário** qual usar. API de imagem paga é proibida. Detalhe: skill `schematize-models`.

## Overdev
- Não pare com checklist aberto. Perguntar ao usuário é vetado: parkeie o item e marque on-hold `- [~]`.

## Tudo no git (GitHub é a fonte da verdade)
- Toda mudança vira commit + push na hora. Todo código/config/IaC/doc em remote acessível (GitHub/GitLab). Sem remote, push falho ou local≠remoto: **NÃO conclui** — crie/peça o repo e dê push. Gate: `git remote -v` não vazio + `git status` limpo + HEAD == origin.

## Deploy só do git
- **VETADO** mandar código da máquina à VPS (scp, rsync, tar|ssh, docker save|load, bundle, editar remoto, colar patch). O ops, na VPS, clona/atualiza do git (fetch + checkout de SHA/tag verificado): só isso é deploy.

## Ops é o gate da IA
- A IA **nunca** muda a VPS direto (ssh mutável, arquivo, systemctl, docker, SQL, firewall, cron). Exceções: updates automáticos do SO; instalar git e afins + clonar o repo do ops. Depois, só fala com o ops.
- Nunca escreve SQL/script/comando mutável: pede operação nomeada e tipada. Falta comando? Implementa no repo do ops, via git. Detalhe: `ops.md` §8.

## Efeito externo
- E-mail, pagamento e webhook real nunca saem de ambiente não-prd (domínio de teste em rota nula, sink por default).

## Rota exposta
- Toda rota nasce com teste de matriz de acesso no CI (anônimo, não privilegiado, privilegiado, burlas; status e corpo; deny-by-default, M == N).

## Passkey na fase 0
- Passkey/WebAuthn é o método padrão e entra na fase 0, real ponta a ponta; mora no IAM da casa (`schematize-iam`).

Detalhe: skill `schematize-engineering` (`assets/CLAUDE.md` pisos 13, 19-26; `references/orquestracao.md` §9, §9.6, §9.7, §9.8).
