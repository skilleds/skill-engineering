---
description: (Re)gera o índice de microfunções (§39) a partir dos doc-comments
argument-hint: "[dir de origem, ex: internal]"
---

Atualize o **grafo de funcionalidades** (§39) — **fonte da verdade** do projeto e base do MAPA (§4). É um **grafo GLOBAL de dois níveis**: o global (por serviço) + o detalhado (por função). Ele **enumera** o sistema; não resume. O **local operacional vivo** é `.schematize/grafos/` (o que o app lê e desenha); o **espelho durável** é `<projeto>/<projeto>_archive/index/`.

## 1. Enumere e CONTE (a verdade do que existe)

Antes de gerar, descubra **todas** as funções do alvo `${ARGUMENTS:-src}` — públicas e privadas, incluindo métodos, handlers, jobs e closures nomeadas. Conte as declarações (use AST/ctags se houver; senão, ripgrep):

- **Go:** `rg -n '^\s*func '`
- **Rust:** `rg -n '^\s*(pub\s+)?(async\s+)?fn '` (inclui métodos em `impl`)
- **TS/JS:** `rg -n '(export\s+)?(async\s+)?function |const\s+\w+\s*=\s*(async\s*)?\(|^\s*\w+\s*\([^)]*\)\s*\{'`
- **Python:** `rg -n '^\s*def '`

Guarde **N = total de funções** por serviço/pasta. É o alvo de completude — e faça para **cada** serviço do sistema, não só o que você tocou.

## 2. Grafo DETALHADO por serviço (uma entrada por função, sem "relevante")

Para **cada** serviço, um arquivo `.schematize/grafos/<servico>.md` — o grafo interno, funções como **nós** e chamadas intra-serviço como **arestas**. Para **cada** função encontrada, uma linha em tabela pipe:
`nome | o quê | de onde vem -> pra onde vai | chama (out) | é chamada por (in) | efeitos | arquivo:linha`.
Cada nó tem **`arquivo:linha`** e uma descrição de **uma linha** (coluna "o quê"). Fonte: `node .claude/skills/schematize-engineering/scripts/build-index.mjs` se existir; senão, extraia dos doc-comments (§3). **Nenhuma** função fica de fora por "não ser relevante".

**Auto-referência de fronteira:** quando uma função produz **saída pra outro serviço B**, marque esse nó como saída — `nome -> <servico-B>` — apontando pro global. É a aresta que **sai do grafo local** e reaparece no `GRAFO_GLOBAL.md`.

## 3. Grafo GLOBAL (a superfície de contratos entre serviços)

`.schematize/grafos/GRAFO_GLOBAL.md`: o grafo da aplicação inteira.
- **Multi-serviço:** **cada microserviço é um nó** mostrando suas **funções principais** (entrypoints/APIs públicas — a superfície de contrato, não todas as funções). As **arestas são os contratos** (saída de dados de A pra B). Enumere **TODOS** os serviços, nenhum de fora.
- **Serviço único:** esse serviço + as **arestas que cruzam a fronteira** dele.
- **Formato das arestas — INEGOCIÁVEL:** ASCII `A -> B (contrato)` (rota/evento/fila/tópico). **NUNCA** a seta unicode `→` — o parser do app lê ASCII e o `→` quebra. Vale no global (`servicoA -> servicoB (contrato)`), no detalhado (`funcaoX -> funcaoY`) e na fronteira (`funcaoX -> <servico-B>`).

## 4. Concilie a COMPLETUDE (gate duro)

- Conte as entradas do grafo detalhado (**M**) e compare com **N**, **por serviço**.
- **Se M < N → FALHE.** Liste, **pelo nome**, as `N - M` funções que ficaram de fora e volte ao passo 2 até `M == N`. Grafo com menos entradas que funções é bug, não resumo — o caso "90 linhas pra 100+ funções" é **reprovado aqui**.
- Se o `build-index.mjs` sair com código 1, há função sem doc-comment (§3): corrija **na origem** (o quê + de onde→pra onde), não no grafo.

## 5. Espelho no archive + MAPA + confirmação

- **Copie** `.schematize/grafos/` pro espelho durável `<projeto>/<projeto>_archive/index/`: `INDEX_GLOBAL.md` (cada repo/serviço com 1 linha, árvore de pastas top-level e o grafo global; nenhum de fora), `INDEX_FUNCTIONS.md` (o detalhado por serviço) e o **`MAPA.md` (o resumo)** — **no archive, nunca no root** (§4, §28).
- A versão **operacional que o app desenha** é a de `.schematize/grafos/`; o archive é o espelho de registro.
- Confirme ao usuário com **números**: `N funções / M entradas / G serviços no grafo`, e que **M == N** em cada serviço. Se não bater, **não terminou**.
