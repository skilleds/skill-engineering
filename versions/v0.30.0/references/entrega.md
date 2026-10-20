# Entrega: Templates, Flags, IA Assistida, DoD, Evolução e Índice

> Parte da skill **schematize-engineering**. Continuação de `operacao.md` (numeração de seções **preservada**, §29+): templates, feature flags, uso de IA assistida, Definition of Done, evolução e índice de funcionalidades. Cross-refs por número de seção continuam válidos.

---

## 29. Templates

```
/templates
├── README.md
├── ADR.md
├── TASK.md
├── PR_TEMPLATE.md
├── ISSUE_TEMPLATE.md
├── RUNBOOK.md
├── GRAFO_GLOBAL.md       # grafo global da aplicação — vivo em .schematize/grafos/ (§39)
├── INDEX_GLOBAL.md       # espelho do grafo global no archive (§39)
├── INDEX_FUNCTIONS.md    # espelho do grafo detalhado por serviço (§39)
└── OPENAPI_TEMPLATE.yaml
```

README mínimo: o que é, como rodar, como testar, como deployar, dependências, observabilidade, oncall, runbook.

---

---

## 31. Feature Flags

Obrigatório para features críticas, migrações e rollouts graduais.
Capacidades: rollout por % de tráfego, segmentação por tenant/usuário, kill switch, expiração de flag.
Sugestões: Unleash, OpenFeature, GrowthBook.

---

---

## 34. Uso de IA Assistida

**MUST**
- Código gerado por IA passa pelo mesmo PR review humano que qualquer outro.
- Autor humano é responsável: assina o commit, entende o código, mantém.
- Saídas de IA não substituem ADR.
- **IA opera sob a §37 (anti-padrões vetados) integralmente.** Gerar código que viola um item VETADO é defeito, não estilo — rejeita no review.
- **IA gera o archive (§28) junto com o código**, na mesma entrega.

**MUST NOT / VETADO**
- Colar trecho gerado sem ler.
- Aceitar dependências sugeridas sem verificar nome (typosquatting é real — §37).
- Submeter código que não passa em `make ci`.
- Aceitar "solução rápida" da IA que burla um piso de segurança da §37.

**SHOULD**
- Prompt e contexto relevantes registrados no chat archive quando a decisão for não trivial.
- Verificar licença de snippets longos sugeridos.

### 34.1 Handoff de contexto em sessões longas

> **Dono único: `references/contexto-claude-code.md`** (desta mesma skill). Este §34.1 é o
> **gatilho** — *quando* parar e arquivar —; o *como* (formato dos dois MDs, os hooks, o
> `/compact`, o que entra em cada seção) é lá, e só lá. O `contexto-claude-code.md` chegava a
> **admitir ter dois donos** no próprio cabeçalho; agora não tem: ele é o dono.

Sessões longas de agente degradam quando o contexto enche: o modelo "esquece" decisões e a compactação automática resume de forma lossy. Para não perder estado, o handoff é **proativo e arquivado**, não reativo.

**MUST**
- Definir um **limite de handoff** (tokens) abaixo do teto da janela — cedo o suficiente pra sobrar espaço pra escrever o resumo. Sugestão: ~25% da janela (ex.: 250k numa janela de 1M).
- Ao cruzar o limite, **antes de qualquer compactação**, gerar dois artefatos em `<project>/<project>_archive/context/`:
  - `AAAA-MM-DD-<slug>-context.md` — estado do projeto, decisões tomadas, arquivos tocados, onde parou.
  - `AAAA-MM-DD-<slug>-checklist.md` — **feito vs. em aberto**.
- Só então compactar/limpar o contexto. O handoff é archive obrigatório (§28) — armazenar **sempre** em `<project>/<project>_archive`.
- **Rede de segurança determinística:** um backup do estado é capturado automaticamente antes de toda compactação (manual ou automática), independente de o agente ter lembrado de gerar os MDs acima.

**SHOULD**
- O limite é configurável por ambiente/projeto (ex.: env var), não hardcoded.
- O resumo de contexto preserva o que **você** escolhe (foco na tarefa corrente), não o que a compactação automática adivinha.

> Compactação automática é rede, não plano. Em sessão longa, o handoff arquivado vem antes do teto — quem controla o que sobrevive é você, não o resumo lossy.

---

---

## 35. Definition of Done

Uma task está pronta quando, cumulativamente:

- [ ] Testes passam (unit + integration), cobertura nos mínimos
- [ ] Caminhos críticos com testes explícitos
- [ ] **Teste emulado (`simulated`) executado — 100% das rotas do inventário acessíveis pra quem deve e bloqueadas pra quem não deve; rota fantasma/morta = bloqueio (skill `schematize-qa`)**
- [ ] **Matriz de acesso por rota (piso 20): toda rota do inventário com teste das 4 personas (anônimo, não privilegiado, privilegiado, burlas) afirmando status E corpo, deny-by-default, allowlist de rotas públicas com dono, gate M == N verde (skill `schematize-qa`, `check-route-authz.sh`)**
- [ ] **Pentest de entrada limpo: sem `500`, sem coerção de tipo, sem eco não-escapado, sem vazamento cross-tenant (skill `schematize-pentest`)**
- [ ] Lint, fmt, security scan limpos
- [ ] **Nenhum item da §37 (anti-padrões vetados) presente no diff**
- [ ] **Arquivos ≤ 750 linhas (~500 úteis + ~250 comentário); código útil > 300 linhas (~400 obs) flagueado e registrado como dívida (`padroes-codigo.md`); toda função com doc-comment de contexto — o quê + onde é usada**
- [ ] **Índice de funcionalidades atualizado no mesmo PR — global e microfunções (§39)**
- [ ] Observabilidade implementada (logs, métricas, traces, audit se aplicável)
- [ ] OpenAPI atualizada (se for API)
- [ ] Migration testada com rollback (se houver schema change)
- [ ] **Nenhum efeito externo real fora de `prd` (se o projeto envia e-mail/SMS/push/webhook/cobrança):** provider default = sink, guard deny-by-default no provider (com teste que **vê a recusa**), cap por execução, endereços só no **domínio de teste em rota nula** (`references/efeitos-externos.md`; anti-padrão em `references/anti-padroes.md` §37, item *"Disparar efeito externo REAL a partir de não-produção"*)
- [ ] Documentação atualizada (README, ADR, runbook se aplicável)
- [ ] Smoke tests executados em staging **(com asserção de conteúdo e self-check anti verde-mentiroso — skill `schematize-qa`)**
- [ ] CI verde, code review aprovado
- [ ] **Archive de chat/task gerado e commitado (§28) — gate rígido, não opcional**
- [ ] Feature flag configurada (se aplicável)
- [ ] CODEOWNERS aplicável revisou

> Os itens em negrito são **bloqueantes absolutos**: archive (§28), ausência de macaquice (§37), teste emulado com rota 100% acessível (skill `schematize-qa`), **matriz de acesso por rota verde (M == N)**, **nenhum efeito externo real fora de prd** (`efeitos-externos.md`), e pentest de entrada limpo (skill `schematize-pentest`). Faltando qualquer um, a task **não está pronta** — independente de todo o resto estar verde. Smoke verde não basta: tem que ser smoke que **prova** conteúdo, não só status.

---

---

## 36. Evolução

- Refactors incrementais. Big-bang rewrite exige ADR e plano de rollback.
- Toda migração de runtime/framework tem flag de coexistência.
- DDD e hexagonal podem ser adotados progressivamente — comece pelas bordas e pelos domínios mais complexos.

---

---

## 39. Índice de Funcionalidades — o GRAFO GLOBAL de dois níveis (fonte da verdade viva)

> **Fronteira com a `schematize-docs`.** Este §39 é o **contrato**: onde o índice mora, o modelo de
> dois níveis, o formato que o app consome (arestas em **ASCII**, tabela pipe, `arquivo:linha`) e a
> exigência de **completude** (`M == N`: uma entrada por unidade chamável, nada de resumo). O
> **como** — gerar do código, o gate de CI que trava o merge com índice defasado, e os **diagramas**
> C4/Mermaid versionados — é da **`schematize-docs`** (`references/indice-diagramas.md`, comando
> `/docs-api`). Onde as duas divergirem no *como*, ela manda; no *o quê*, este §39.
>
> *(Achado D3 da vistoria de 2026-08-21: a base nunca declarou a fronteira depois da extração, e as
> duas descrições do mesmo índice passaram a existir lado a lado.)*

O código diz **como** está agora; o índice diz **o que existe, onde mora e como se faz cada coisa** — e é tratado como **fonte da verdade do projeto**, consultado antes de criar algo (pra não duplicar) e atualizado a cada mudança. Índice que apodrece é pior que não ter; por isso ele é gerável/validável e tem gate na DoD.

**MUST — localização: local operacional vivo + espelho durável**
- O grafo tem **dois lugares**, com papéis distintos:
  - **LOCAL OPERACIONAL vivo:** `.schematize/grafos/` no root do projeto (dentro do marcador `.schematize/`, ao lado de `overdev/`). **É o que o app lê e desenha** (painel/tela de grafos, §8 de `overdev.md`). É a versão **operacional** — a fonte que a ferramenta consome.
  - **ESPELHO durável:** `<projeto>/<projeto>_archive/index/` — cópia versionada no archive (§28), para histórico, review de PR e auditoria. Todo update do local **copia pra cá**.
- Deixe claro: a versão que **o app efetivamente desenha** é a de `.schematize/grafos/`; o archive é o espelho de registro.

**MUST — o modelo de dois níveis**
- **`GRAFO_GLOBAL.md`** (em `.schematize/grafos/`) — o **grafo GLOBAL da aplicação**:
  - Numa app **MULTI-SERVIÇO** (umbrella/microserviços): **cada microserviço é um NÓ** que mostra suas **FUNÇÕES PRINCIPAIS** (entrypoints / APIs públicas — não todas as funções, só a superfície de contrato). As **arestas são os CONTRATOS** entre serviços — a **saída de dados** do serviço A para o B. Enumere **TODOS** os serviços — nenhum de fora.
  - Num **serviço único**: traz **esse** serviço + as **arestas que cruzam a fronteira** dele (o que ele chama/notifica por fora e quem o chama de fora).
- **`<servico>.md`** (um arquivo por microserviço, em `.schematize/grafos/`) — o **grafo DETALHADO interno**: as **funções** do serviço como **nós**, as **chamadas intra-serviço** como **arestas**; **cada nó com `arquivo:linha`**. É onde se vê o raio de impacto de qualquer função dentro do serviço.
- **AUTO-REFERÊNCIA DE FRONTEIRA:** quando uma função de A produz **saída pra B**, o grafo local de A **marca esse nó como saída** — `-> <servico-B>` — apontando pro global. É a aresta que **sai do grafo local** e reaparece no `GRAFO_GLOBAL.md` como contrato entre serviços. Assim o detalhado (por-serviço) e o global se costuram: o nó de fronteira no local é a ponta da aresta global.

**MUST — formato (casar com o parser do app — INEGOCIÁVEL)**
- **Arestas SEMPRE em ASCII:** `A -> B (contrato)` — **NUNCA** a seta unicode `→`. Vale no global (`servicoA -> servicoB (contrato)`) e no detalhado (`funcaoX -> funcaoY`) e na marca de fronteira (`funcaoX -> <servico-B>`). O parser do app lê ASCII; um `→` unicode **quebra** a leitura.
- **Funções em tabela pipe:** `nome | o quê | ... | arquivo:linha`. **Cada nó tem uma descrição de UMA linha** — a coluna **"O quê"**.
- Formato **machine-friendly** (markdown com tabelas + adjacência ASCII grepável) — não prosa solta. A adjacência é a fonte pesquisável e diffável.

**MUST — completude (uma entrada por função, sem "relevante")**
- O grafo detalhado por-serviço é **exaustivo**: **uma entrada por unidade chamável** — função, método, handler, hook, closure nomeada, job/consumer — de **cada** serviço/repo do sistema, **pública e privada**. Não existe função "irrelevante": se está no código, está no índice. "Função relevante" **não é filtro** pra pular nada. (O `GRAFO_GLOBAL.md`, por contraste, mostra só as **funções principais** de cada serviço — a superfície de contrato.)
- **Invariante verificável (conte, não confie):** por serviço, `nº de entradas no `<servico>.md` == nº de funções declaradas no código`. O `/<slug>-index` e o CI **contam as declarações** (AST/ctags, ou regex de `func `/`fn `/`def `/`function `/métodos) e **reprovam** se o grafo tiver **menos** entradas que funções encontradas — listando as que faltam **pelo nome**. Grafo com 90 linhas para 100+ funções é **falha dura**, não aviso. O mapa não "resume" o sistema; ele **enumera** o sistema.
- **Cobertura total:** o `GRAFO_GLOBAL.md` lista **cada** microserviço/repo (nenhum de fora); cada microserviço tem seu `<servico>.md` **completo**. Um sistema de N serviços com M funções tem os N serviços no global e as M funções indexadas nos detalhados.

**MUST — superfície de entrada (mapa de endpoints)**
- Toda **porta de entrada** (rota HTTP/gRPC/GraphQL, webhook, consumer de fila, WebSocket, upload, CLI com arg externo) entra no **mapa de endpoints** — **por endpoint**: método+rota, serviço, **auth exigida**, **authz/tenant scope**, **entrada** (cada param: tipo, obrigatório, validação esperada), **saída** (shape+códigos), **erros esperados** e **efeitos** (o que grava/dispara). É a **superfície de ataque** (as arestas de entrada do grafo global) e a **lista de alvos de pentest**. Exaustivo por contagem (`nº linhas == nº rotas`). Detalhe e gerador: `schematize-pentest` (`references/superficie-endpoints.md`, `/pentest-endpoints`).

**MUST — atualização e gate**
- Todo PR que **adiciona, remove ou move** funcionalidade atualiza o grafo no mesmo PR (local **e** espelho). Grafo desatualizado **trava o merge** (item da DoD, §35).
- O grafo é **fonte da verdade**: ao planejar uma feature, consulte-o primeiro pra não reimplementar o que já existe (anti-duplicação — liga com DRY semântico, §1).

**SHOULD — geração assistida**
- O grafo detalhado é **gerado por script** que varre os doc-comments padronizados (`padroes-codigo.md` §3) e monta a tabela `nome | o quê | ... | arquivo:linha`. CI compara o commitado com o gerado; divergência aponta grafo ou comentário desatualizado.
- Cada entrada linka pro `arquivo:linha` de origem.
- `GRAFO_GLOBAL.md` revisado em cada mudança arquitetural (junto com o ADR, §27).

**Espelho no archive (`<projeto>/<projeto>_archive/index/`)**
- `INDEX_GLOBAL.md`, `INDEX_FUNCTIONS.md` e `MAPA.md` **seguem existindo** no espelho `<projeto>/<projeto>_archive/index/` — o **`MAPA.md` é o resumo** navegável. São o registro durável para review e auditoria.
- A versão **OPERACIONAL que o app desenha** é a de `.schematize/grafos/` (`GRAFO_GLOBAL.md` + `<servico>.md`); o archive espelha, não substitui.

> O grafo responde "isso já existe? onde? como faço X? o que quebra se eu mexer aqui?" sem precisar reler o código. Se a resposta exige caçar no código, o grafo falhou — ou está desatualizado, e isso é bug.

---

---

## Anexo A — Versões correntes → **nas skills de linguagem, não aqui**

> **Esta tabela foi REMOVIDA.** A `schematize-engineering` é **agnóstica de linguagem**: fixar
> uma versão de Go, de Rust, de PostgreSQL e de Kubernetes na base é (a) escolher por linguagens que
> ela não governa e (b) criar um fato com prazo de validade no arquivo mais citado do catálogo.
> A tabela ainda apontava uma versão de Go e uma de Kubernetes **já fora de suporte** — e estava clonada
> em mais 7 skills, apodrecendo em oito lugares de uma vez.
>
> **Onde está agora:**
>
> | O quê | Onde |
> |---|---|
> | Versão da linguagem e do ferramental dela | `references/stack-versoes.md` da skill do rol (`schematize-go`, `schematize-rust`, `schematize-elixir`, `schematize-csharp`, `schematize-zig`, `schematize-ruby`, `schematize-node`) |
> | Frontend (Node LTS, Next/Astro, React, TS, thresholds de CWV) | `schematize-web` → `references/stack-versoes.md` |
> | Infra (Kubernetes, Postgres, Redis, OpenTelemetry, backends de state) | `schematize-infra` |
>
> **A regra que fica na base, porque não é volátil:** mudança de versão **major** exige **ADR**; e
> rodar em versão **fora de suporte** é violação de cadeia de suprimentos
> (`references/cadeia-suprimentos.md`), não "dívida para depois".

## Anexo B — Glossário Mínimo

- **Bounded Context** — fronteira explícita dentro da qual um modelo de domínio é consistente.
- **Monólito distribuído** — serviços fisicamente separados mas acoplados por banco compartilhado, shared lib de domínio ou cadeia síncrona sem fronteira. O pior dos dois mundos. Proibido (§2).
- **BFF (Backend for Frontend)** — camada server-side que serve um frontend específico e mantém os segredos fora do browser (§38).
- **Outbox Pattern** — gravar evento em tabela no mesmo commit do dado de negócio; publicador assíncrono lê a tabela e publica no broker. Garante consistência sem dual-write.
- **DLQ** — dead letter queue, fila de mensagens que falharam após retries.
- **Anti-Corruption Layer** — adapter que isola seu domínio do modelo externo.
- **SLO** — service level objective, alvo mensurável de qualidade (ex: 99.9% das requests < 300ms em 30 dias).
- **Error Budget** — quanto você pode falhar dentro do SLO antes de freezar features.
- **Blameless Postmortem** — análise de incidente focada em sistema/processo, não em culpa individual.
- **CSPRNG** — gerador pseudoaleatório criptograficamente seguro. Obrigatório para tokens, ids de sessão e segredos (§14).
- **Macaquice** — atalho que parece entregar mais rápido e entrega vulnerabilidade ou dívida. Catalogadas e vetadas na §37.

---
