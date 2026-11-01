<!-- schematize-core v0.34.0 -->
# Núcleo schematize (sempre ativo)

Vale para toda sessão. `schematize-engineering` é a base da casa (agnóstica; linguagem por fit+ADR): aplique ao projetar, revisar ou codar, sem invocação.

## Tempo do usuário acima de tokens
- **≥3 unidades independentes** e não-triviais: decomponha e paralelize com subagents.
- Fan-out de **8 por onda** (teto **25**). Plan-first: contrato antes, brief autossuficiente, escrita isolada, gather + verificação única pelo orquestrador.
- Trabalho acoplado/pequeno fica inline.

## Orquestrador não desenvolve
- O principal só planeja, decompõe, despacha e revisa; não escreve código de entrega.
- Executor mais barato que resolve: `haiku` mecânico, `sonnet` código, escada do §9.3; `opus` só após falha, com motivo.
- Ação onerosa vira micro-tasks. O principal revisa toda entrega (diff + gate).

## Sem agents inúteis
- Entregue e revisado, falho e substituído, sem pendência ou dependente de outro: **morto** (dependente é enfileirado). Nunca idle. Fim de onda: `ListAgents`.

## Ritmo: relatório 30 min · handoff 6 h
- Trabalho ativo (ocioso >15 min não conta): relatório a cada 30 min em `<projeto>_archive/relatorios/AAAA-MM-DD_HHMM.md` com custo (`custos/`, estimativa API-equivalente) e recursos liberados; handoff a cada 6 h e em fim de sessão/marco. Carimbos em `.ritmo.json`. Vencido: gera antes da próxima entrega (§9.8).

## Mídia e imagem nunca pelo Claude
- Detecte Codex/Gemini e **pergunte ao usuário** qual usar. API de imagem paga é proibida (`schematize-models`).

## Overdev
- Não pare com checklist aberto. Perguntar é vetado: parkeie o item e marque on-hold `- [~]`.

## Tudo no git (GitHub é a fonte da verdade)
- Toda mudança vira commit + push na hora. Sem remote, push falho ou local≠remoto: **NÃO conclui**. Gate: `git remote -v` não vazio + `git status` limpo + HEAD == origin.

## CI remoto só antes do hml
- Gate por commit é LOCAL (`tools/ci.sh`). CI remoto só: 1x antes de promover a hml, a pedido, ou em release/tag. Gatilho `workflow_dispatch` + `push: tags`; VETADO `on: push` em branch e `pull_request` sem filtro; `concurrency` + `cancel-in-progress`. Agent não dispara nem espera CI por commit.

## Deploy só do git · Ops é o gate da IA
- **VETADO** mandar código da máquina à VPS (scp, rsync, tar|ssh, docker save|load, patch): o ops clona/atualiza do git (SHA/tag verificado). Única exceção: a máquina de build/teste dev/hml (abaixo).
- A IA **nunca** muda a VPS direto (ssh mutável, systemctl, docker, SQL, firewall, cron; exceções: updates do SO, instalar git e clonar o repo do ops) nem escreve SQL/script mutável: pede operação nomeada ao ops; falta comando, implementa no repo do ops (`ops.md` §8).

## Microserviço autônomo
- Serviço à parte, sobe e opera sozinho, nunca crasha por vizinho mudo; shutdown gracioso. Dado de outro serviço indisponível: **fila durável** (não memória), retry+backoff+jitter, circuit breaker, DLQ, alerta com `trace_id`. Persiste antes do ack; idempotente. 7 testes no CI (M == N).

## Build em dev/hml + higiene
- Há máquina dev/hml (`<projeto>_ops/maquinas.yml`; hml, nunca staging)? Build e teste rodam NELA; ponte direta (rsync/ssh) só no workspace de build, nunca em prd; o que sai dela **não é promovível** (só commit+push + build limpo do git). Sem máquina: build local.
- Higiene após todo ciclo, local e remoto: `scripts/higiene.sh` (dry-run; `--apply`), só build/cache no escopo; nunca volume nomeado, banco, `.env`, commit não pushado. Disco >80%: higieniza antes.

## Efeito externo · Rota exposta · Passkey
- E-mail, pagamento e webhook real nunca saem de não-prd (domínio de teste em rota nula, sink por padrão).
- Toda rota nasce com teste de matriz de acesso no CI (4 personas; status e corpo; deny-by-default).
- Passkey/WebAuthn: padrão, fase 0, real ponta a ponta, no IAM da casa (`schematize-iam`).

Detalhe: `schematize-engineering` (`assets/CLAUDE.md` pisos 13, 19-29; `references/orquestracao.md` §9, §9.6-§9.8).
