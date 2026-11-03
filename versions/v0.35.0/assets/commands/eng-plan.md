---
description: schematize-engineering — planejamento extensivo plan-first: entender (decisões acordadas + código/grafo) → objetivo/escopo → pesquisar incógnitas (spikes) → decompor no grafo com deps/ordem topológica → risco+rollback → ADR das decisões estruturais → plano de paralelização → fases+DoD; gera o plano no archive, deriva o checklist e PEDE APROVAÇÃO antes de executar
argument-hint: "<objetivo>"
---

Faça o **planejamento extensivo** (`references/planejamento.md`) de: **${ARGUMENTS:-<objetivo>}**.
Plan-first de verdade — nada de código antes do plano aprovado. (Se o trabalho é trivial/
reversível de 1 arquivo, diga que não precisa de plano extensivo e siga inline.)

## Fases (nesta ordem — `references/planejamento.md` §2)
1. **Entender:** colha as **decisões já acordadas no contexto** (decisão · motivo · alternativa descartada); leia o **código + `MAPA.md`/grafo do índice** (§39) do que será tocado; levante **restrições e requisitos não-funcionais** (perf/segurança/LGPD/SLA/custo). Sobre o que existe, não o que você acha.
2. **Objetivo & escopo:** 1 frase + **o que entra / o que NÃO entra** (explícito) + **critério de sucesso mensurável**.
3. **Pesquisar o desconhecido:** liste as **incógnitas** → cada uma vira **spike time-boxed** ou pergunta. Não planeje sobre suposição não-verificada. Já existe no repo? (consulte o índice, não duplique).
4. **Decompor no grafo:** unidades **verificáveis**, cada uma com **nó(s)/arquivo:linha + arestas**, **prova** (teste/gate), **dependências**. Monte o **grafo de deps** + **ordem topológica** + **caminho crítico**.
5. **Risco:** por unidade/decisão — probabilidade × impacto, **reversibilidade**, **mitigação**, **rollback**. Irreversível ganha cuidado, não pergunta à toa.
6. **Arquitetura & ADR:** decisão que molda estrutura vira **ADR** (`references/operacao.md` §27; template em `assets/ADR.md`): contexto/opções/decisão/consequência. Grave em `<projeto>_archive/decisoes/`.
7. **Paralelização:** ≥3 unidades independentes → **plano de fan-out** (`references/orquestracao.md`): contrato por agente, isolamento, gather único.
8. **Fasear & estimar:** roadmap **F0..Fn** com **DoD por fase** (§35), ordem respeitando as deps.

## Entrega (plan-first)
- Grava o **PLANO** em `<projeto>/<projeto>_archive/plan/<data>-<contexto>.md` (§28) com tudo acima.
- **Deriva o CHECKLIST** (projeção executável, exaustiva por contagem — vira `/eng-overdev` ou execução direta).
- **PEÇA APROVAÇÃO** antes de executar. Aprovado, executa faseado; achado crítico na execução **pausa e replaneja**.

## Gate do plano (`references/planejamento.md` §4)
Escopo com fronteira (in/out) + sucesso mensurável · toda incógnita virou spike/risco · decomposição ancorada no grafo (nó+prova+deps) · riscos com mitigação/rollback · decisões estruturais com ADR · DoD por fase + archive. Sem isso é rascunho, não plano.
