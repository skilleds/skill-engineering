# Planejamento extensivo — plan-first de verdade, antes de construir

> A disciplina de **planejar pesado** antes de tocar em código, para trabalho não-trivial.
> É o plan-first levado ao limite: entender → pesquisar o desconhecido → decompor no grafo
> real → medir risco → decidir arquitetura (ADR) → fasear → **aprovar** → só então executar.
> O `/eng-overdev` usa isto na sua Fase 0; o `/eng-orchestrate` usa o plano pra paralelizar.
> Um plano raso é a causa nº 1 de retrabalho — este reference existe pra matá-la.

## 1. Quando planejar extensivo (e quando não)

- **Sim:** feature/serviço novo, mudança que cruza módulos/serviços, migração, refactor
  grande, qualquer coisa que toque auth/dados/dinheiro, ou tarefa com **≥3 unidades** ou
  incerteza real. Se erra caro ou é irreversível, planeja.
- **Não (inline):** ajuste pontual, bug óbvio, tarefa de 1 arquivo reversível. Planejar o
  trivial é burocracia — o piso é proporcional ao risco.

## 2. As fases do plano (nesta ordem)

**2.1 Entender.** Colha as **decisões já acordadas no contexto** (o que foi combinado, por
quê, alternativa descartada — é o artefato **0.1** da Fase 0, `overdev.md` §0); leia o **código, o `MAPA.md` e o
grafo do índice** (§39) do que será tocado; levante **restrições e requisitos não-funcionais**
(perf, segurança, LGPD, SLA, custo). Não planeje sobre o que você acha que existe — sobre o
que existe.

**2.2 Objetivo & escopo.** Uma frase de objetivo; **o que entra e o que NÃO entra**
(explícito — escopo sem fronteira vira scope creep); **critério de sucesso mensurável**.

**2.3 Pesquisar o desconhecido (spikes).** Liste as **incógnitas** (não sei se a lib X faz Y,
não sei o custo de Z). Cada uma vira **spike time-boxed** ou uma pergunta. **Não planeje em
cima de suposição não-verificada** — marque como risco até resolver. Prior art: já existe no
repo? (consulte o índice antes de criar — não duplique.)

**2.4 Decompor no grafo.** Quebre em **unidades verificáveis**, cada uma com: **nó(s) do
grafo** que toca (`arquivo:linha`/serviço) e arestas afetadas, **prova** (teste/gate),
**dependências** (o que vem antes). Monte o **grafo de dependências** e a **ordem topológica**;
identifique o **caminho crítico**.

**2.5 Risco.** Por unidade/decisão: **probabilidade × impacto**, **reversibilidade**,
**mitigação** e **rollback**. O irreversível ganha cuidado extra (atraso cancelável, gate
humano), não uma pergunta bloqueante à toa.

**2.6 Arquitetura & ADR.** Decisão que molda a estrutura (escolha de padrão, limite de
serviço, contrato, store) vira **ADR** (`references/operacao.md` §27; template em `assets/ADR.md`): contexto, opções, decisão,
consequência. Decisão sem ADR é decisão que se perde.

**2.7 Paralelização.** ≥3 unidades independentes (sem alvo de escrita comum, sem ordem
obrigatória) → **plano de fan-out** (`orquestracao.md`): contrato por agente, isolamento
(worktree/partição), gather único. O acoplado/pequeno fica serial.

**2.8 Fasear & estimar.** Roadmap **F0..Fn** com marcos; **DoD por fase** (§35); a ordem
respeita as dependências (2.4). Estimativa grosseira por fase (esforço/risco), não precisão
falsa.

## 3. Entrega do plano (plan-first — nada roda sem aprovação)

- Grava o **PLANO** em `<projeto>/<projeto>_archive/plan/<data>-<contexto>.md` (§28): objetivo/escopo,
  incógnitas+spikes, decomposição (com nó+prova+deps), grafo de dependências, riscos+rollback,
  ADRs abertos, plano de paralelização, fases+DoD.
- **O plano gera o CHECKLIST** — projeção executável, exaustiva por contagem (vira
  `/eng-overdev` ou execução direta).
- **Pede aprovação** antes de executar (como o `/qa-plan` da `schematize-qa`). Aprovado, executa faseado; **achado
  crítico durante a execução pausa e replaneja**, não improvisa.

## 4. Gate do plano (quando o plano está "pronto pra executar")

- Escopo tem **fronteira explícita** (in/out) e **critério de sucesso mensurável**.
- **Toda incógnita** virou spike/risco — nenhuma suposição não-verificada sustentando o plano.
- Decomposição **ancorada no grafo** (cada unidade aponta nó + prova + dependências); ordem topológica definida.
- Riscos com **mitigação e rollback**; decisões estruturais com **ADR**.
- **DoD por fase** e **archive** presentes. Sem isso, é rascunho, não plano.

> Regra de bolso: **planejar é barato; retrabalhar é caro.** O plano extensivo não é
> cerimônia — é o mapa que faz a execução (inclusive a paralela e a do overdev) andar reto,
> ancorada no código real e nas decisões já fechadas.
