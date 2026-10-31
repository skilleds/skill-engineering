---
description: schematize-engineering — modo desenvolvimento contínuo: Fase 0 primeiro (colhe as decisões acordadas no contexto → carrega o grafo do index → planejamento PESADO → deriva o checklist), depois tickeia item a item e NÃO deixa parar/falar com o usuário até o checklist estar 100% verificado (Stop hook que rejeita parada prematura). Anti "entreguei uma micro-função e disse que terminei".
argument-hint: "<objetivo> | resume | status | stop"
---

Modo **OVERDEV** (`references/overdev.md`): trabalho contínuo até o checklist fechar de
verdade. Usa o Stop hook `overdev-stop.sh`, que **rejeita a parada** enquanto houver item
aberto — o agente só fala com o usuário quando **tudo** estiver `- [x]` e o gate passar.

## Modo `<objetivo>` (iniciar)

**Fase 0 — Fundação (ANTES de tickar; `references/overdev.md` §0).** Nada de laço sem isto:

0.1 **Colha as decisões ACORDADAS no contexto atual** — varra a sessão inteira e extraia o que
   já foi combinado (decisão · motivo · alternativa descartada · origem). Grava em
   `.schematize/overdev/DECISOES.md` (+ espelho no `<projeto>/<projeto>_archive/overdev/`). Trava o que já foi
   fechado; o que ficou ambíguo vira `- [~]` on-hold, não trava a fundação.

0.2 **Carregue o GRAFO do index** — rode/leia `/eng-index` (§39): `MAPA.md` + grafos em
   `<projeto>/<projeto>_archive/index/` (adjacência `A -> B`). Ancore o plano no grafo real (cada item
   aponta nó/`arquivo:linha` e arestas afetadas). Sem index? gerá-lo é o **1º item** do checklist.

0.3 **Planejamento PESADO** → `.schematize/overdev/PLAN.md` (+ archive): escopo (entra/NÃO entra),
   decomposição em itens **verificáveis** e do tamanho de **uma micro-task de executor barato** (cada um: nó do
   grafo + prova + dependências + risco + executor `[haiku]`/`[sonnet]`/`[codex]`/`[cursor]`/`[opus: <motivo>]`),
   **ordem** topológica, **paralelismo** (≥3 independentes → `/eng-orchestrate`), **mapa
   decisão→item**, riscos, DoD (§35) + archive (§28).

0.4 **Derive o CHECKLIST do plano** → `.schematize/overdev/CHECKLIST.md` (+ espelho `OBJETIVO.md`).
   Exaustivo **por contagem**, um item por linha (`- [ ]`), cada um pequeno e com como provar
   (teste/comando/gate) e **tag de executor** (`[sonnet]` default código; `[haiku]` mecânico; `[codex]` visual (UI)/fallback; imagem só após perguntar ao usuário (Codex ou Gemini); `[opus: <motivo>]` só após
   escalada — `orquestracao.md` §9). Se o usuário já tem checklist, **incorpore inteiro, sem resumir**.
   Cubra: implementação, testes, edge cases, erro/loading/vazio, doc-comment + índice/MAPA
   (§39), DoD (§35), archive (§28). Checklist magro = "terminei" precoce.

0.5 **Briefing** — documento coeso (objetivo + decisões + grafo + plano + checklist + riscos) no
   archive; é o que o laço abre (`schematize-overdev-context` → `references/briefing.md`).

**Guard de papéis:** o bloqueio de `Edit`/`Write` do agent principal durante o run é especificação **pendente no CLI** — ver `references/overdev.md` §3 ("Guard de papéis"). Até existir, é disciplina sua: o principal despacha e revisa, não edita.

**Só depois da Fase 0:** (a cada item fechado no laço, faça a varredura de ociosos — `orquestracao.md` §9.6: idle com pendência → reuse; depende de outro → mate + enfileire com gatilho de dependência; terminou → mate.)

1. **Ative o run** com o CLI (motor Rust — ver `references/overdev.md` §7):
   - `schematize overdev start "<objetivo>" [--max N]` — cria `.schematize/overdev/` (`state.json`
     `mode=active`, `iterations`), um `CHECKLIST.md` template e o `.gitignore`. O marcador
     canônico é a pasta **`.schematize/`**; um **`.overdev/` legado** é lido por compat e
     **auto-migrado** para `.schematize/overdev/` no `overdev start`.
   - **Grave os artefatos da Fase 0** em `.schematize/overdev/`: `DECISOES.md` (0.1), `PLAN.md` (0.3) e o
     `CHECKLIST.md` **derivado do plano** (0.4, sobrescreve o template); espelhe `PLAN.md` +
     `OBJETIVO.md` em `<projeto>/<projeto>_archive/overdev/` (registro durável §28).
   - Crie `.schematize/overdev/gate.sh` — verificação de máquina (`/eng-review` + testes + lint).
     `exit!=0` = não terminou, mesmo com caixas marcadas.
   - Sem o binário instalado? use o fallback `assets/hooks/overdev-stop.sh` (Stop-only) e a
     `assets/settings.claude.example.json` — mas o binário é o recomendado (faz o veto de
     pergunta também). Instale: `schematize install`/bootstrap do `schematize-cli`.
2. **Confirme os hooks:** `schematize overdev enable` registra Stop + PreToolUse no
   `settings.json` (uma vez; inerte sem run). `schematize overdev status` mostra o estado.
3. **Entre no laço** (`references/overdev.md` §2) — **só com a Fase 0 fechada** (os 5 artefatos da tabela do §0): próximo
   `- [ ]` → **escreve o brief e despacha ao agente do papel adequado** (default subagent `sonnet`; visual → Codex; o principal NÃO desenvolve) →
   **revisa (diff + roda o gate)** → falhou? **pede correção ao mesmo subagent** (até 2 rodadas →
   re-decompõe → Codex Terra → Cursor → só então `opus`, com motivo registrado) → marca `- [x]` → repete. ≥3 unidades
   independentes → **fan-out** (`/eng-orchestrate`). **Não pare, não anuncie "pronto", não
   entregue micro-função como se fosse o todo.**

## NÃO trave pra perguntar (regra central)
**VETADO usar `AskUserQuestion` (pool bloqueante) em overdev** — o hook `guard` bloqueia.
Topou dúvida? **parkeia e segue**: `schematize overdev park "<item>" "<pergunta>"` (registra
em `./PERGUNTAS-OVERDEV.txt` na base do projeto **e** marca o item como `- [~]` on-hold), e
continua os outros. **Escalar para Opus não é pergunta** — sobe o degrau da escada com motivo
registrado; só **esgotou a escada** vira `park`. Prefira **assumir um default razoável e documentá-lo** a perguntar,
quando o erro for reversível.

## Como TERMINAR (as únicas saídas legítimas)
- **Concluído:** **nenhum item aberto nas TRÊS classes** — nem `- [ ]` (máquina), nem `- [H ]`
  (humano), nem `- [~]` (on-hold) — **e** `.schematize/overdev/gate.sh` passa → `schematize overdev
  stop` e reporte ao usuário: resultado + evidência.
  **`- [~]` NÃO é conclusão.** On-hold cuja pergunta ninguém respondeu é **órfão RED** para a
  `schematize-audit` (`SKILL.md` §"Nenhum checklist criado fica órfão") — e a regra da audit é a
  que vale, porque é ela quem dá o veredito no fim. Sobrando `- [H ]` ou `- [~]`, a saída legítima
  **não é "concluído"**: é **`BLOCKED`** (abaixo), listando os itens humanos e as perguntas
  parkeadas. O Stop hook cobra isso — ele conta as três classes.
- **Bloqueado (`BLOCKED`):** sobra o que **só o usuário** fecha — item `- [H ]`, pergunta `- [~]`
  sem resposta, credencial/decisão irreversível/dependência externa. Escreva
  `.schematize/overdev/BLOCKED` com **o motivo e a pergunta**, item a item, e só então pare. É a
  saída honesta do checklist que não fechou — não confundir com "concluído".
- **Budget/thrashing:** estourou `--max` ou vários ciclos sem progresso → parkeia os itens
  travados, `schematize overdev stop`, post-mortem do que falta. Guardrail, não desistência.

## `resume`
Releia `.schematize/overdev/CHECKLIST.md` + `OBJETIVO.md`, retome do primeiro `- [ ]`. (Use após
crash/compactação; ideal com heartbeat `/loop` ou cron re-chamando `resume`.)

## `status`
Mostre a tabela do checklist (feitos/abertos), `iterations`, `max_iters`, últimas linhas de
`premature-stops.log`. Não altera nada.

## `stop`
Parada manual do usuário: ponha `"mode": "stopped"` no `.schematize/overdev/state.json` (o hook volta a inerte).
Use só quando VOCÊ (usuário) mandar — o agente não se auto-libera por aqui.

> Regra de ouro: no overdev, o **checklist é o juiz**. O agente não decide que terminou —
> o gate decide. Marcar item sem prova é a mesma macaquice do "terminei" precoce.
