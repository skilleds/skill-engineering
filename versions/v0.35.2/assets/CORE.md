<!-- schematize-core v0.35.2 -->
# Núcleo schematize (sempre ativo)

Vale para toda sessão. `schematize-engineering` é a base da casa (agnóstica; linguagem por fit+ADR): aplique ao projetar, revisar ou codar, sem invocação.

## Tempo do usuário acima de tokens
- **≥3 unidades independentes** e não-triviais: decomponha e paralelize com subagents, **8 por onda** (teto **25**). Plan-first: contrato antes, brief autossuficiente, escrita isolada, gather + verificação única. Acoplado/pequeno fica inline.

## Orquestrador não desenvolve
- O principal só planeja, decompõe, despacha e revisa; não escreve código de entrega. Executor mais barato: `haiku` mecânico, `sonnet` código, escada do §9.3; `opus` só após falha, com motivo. Ação onerosa vira micro-tasks; o principal revisa toda entrega.

## Sem agents inúteis · Ritmo
- Entregue, falho, sem pendência ou dependente de outro: **morto**, nunca idle; fim de onda: `ListAgents`.
- Relatório a cada **30 min** e handoff a cada **6 h** de trabalho ativo (ocioso >15 min não conta), em `<projeto>_archive/relatorios/`, com custo; carimbos em `.ritmo.json`. Vencido: gera antes da próxima entrega.

## Mídia, overdev, git
- Imagem nunca pelo Claude: detecte Codex/Gemini e **pergunte** qual usar; API de imagem paga é proibida.
- Overdev: não pare com checklist aberto; perguntar é vetado: parkeie e marque `- [~]`.
- **Tudo no git**: toda mudança vira commit + push na hora. Sem remote, push falho ou local≠remoto: **a demanda NÃO se conclui** (remote não vazio + `git status` limpo + HEAD == origin).

## CI remoto só antes do hml
- Gate por commit é LOCAL (`tools/ci.sh`). Sem check de PR. CI remoto: 1x antes do hml, a pedido ou em tag. Gatilho `workflow_dispatch` + `push: tags` (`hml-*`, `v*`); VETADO `pull_request` (qualquer filtro), `push` em branch, `workflow_run`, cron sem justificativa; `concurrency` + `cancel-in-progress`, `paths-ignore`. Agent não dispara nem espera CI por commit.

## Deploy só do git · Ops é o gate da IA
- **VETADO** mandar código à VPS (scp, rsync, tar|ssh, docker save|load, git bundle, patch): o ops clona do git (SHA/tag verificado). Única exceção: máquina de build dev/hml (abaixo).
- A IA **nunca** muda a VPS direto (ssh mutável, systemctl, docker, SQL, firewall, cron; exceções: updates do SO, git, clone do repo do ops) nem escreve SQL/script: pede operação nomeada ao ops (`ssh vps "ops <op>"`); falta comando, implementa no repo do ops. O ops tem allowlist, dry-run, rate-limit, log append-only, kill-switch (`ops.md` §8).

## Microserviço autônomo
- Sobe e opera sozinho, nunca crasha por vizinho mudo; shutdown gracioso. Dado indisponível: **fila durável** (não memória), retry+backoff+jitter, circuit breaker, DLQ, alerta com `trace_id`. Persiste antes do ack; idempotente. 7 testes no CI (M == N).

## Build em dev/hml + higiene
- Máquina dev/hml (`<projeto>_ops/maquinas.yml`)? Build e teste rodam NELA; ponte direta só no workspace de build, nunca prd; o que sai dela **não é promovível** (só commit+push + build limpo do git).
- Higiene após todo ciclo: `scripts/higiene.sh` (dry-run; `--apply`); nunca volume nomeado, banco, `.env`, commit não pushado. Disco >80%: higieniza antes.

## Efeito externo · Rota exposta · Passkey
- E-mail, SMS, push, pagamento e webhook real nunca saem de não-prd (domínio de teste em rota nula, sink por padrão, cap por execução).
- Toda rota nasce com teste de matriz de acesso no CI (4 personas; status e corpo; deny-by-default).
- Passkey/WebAuthn: padrão, fase 0, real ponta a ponta, no IAM da casa (`schematize-iam`).

Detalhe: `schematize-engineering` (`assets/CLAUDE.md` pisos 13, 18-29; `references/orquestracao.md` §9, §9.6-§9.8).
