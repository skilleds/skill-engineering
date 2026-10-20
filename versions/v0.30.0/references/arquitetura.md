# Arquitetura, Camadas, Repositórios e Linguagens

> Parte da skill **schematize-engineering**. As referências cruzadas (§N) apontam para seções do corpo completo — todas presentes no conjunto de references desta skill.

## Índice
- 2. Estrutura de Repositórios
- 3. Linguagens
- 4. Arquitetura
- 5. Estrutura de Pastas
- 6. Complexidade e Tamanho
- 7. Dependências Internas e Shared Libraries
- 8. CQRS e Padrões de Aplicação

---

## 2. Estrutura de Repositórios

**MUST**
- Um repositório = uma aplicação ou um bounded context.
- Comunicação entre serviços via HTTP, gRPC, eventos ou mensageria — nunca via banco compartilhado.
- Cada serviço é dono do seu schema.
- **Nome do repositório:** `<projeto>_<contexto>[_<lang>]` em snake_case minúsculo. `<projeto>` = slug do produto/organização; `<contexto>` = a aplicação/bounded context daquele repo (`api`, `worker`, `front`, `backoffice`, `gateway`…); `_<lang>` é sufixo **opcional** pra desambiguar linguagem (`_rs` Rust, `_go` Go, `_ts` TypeScript). Como um repo = um contexto, o nome espelha isso. Ex.: `loja_api_rs`, `loja_front`, `loja_worker_go`.
- **Independência de runtime (cada serviço é entidade à parte):** todo serviço **sobe e opera sozinho**. A indisponibilidade de qualquer outro serviço **nunca** impede o boot nem derruba este — depender de outro serviço para *iniciar/funcionar* é VETADO (nada de "o `ledger` não sobe se o `core` estiver fora"). Dependente ausente vira **degradação graciosa** (fallback, resposta parcial, enfileira e segue), nunca crash em cascata. Como não perder o dado quando a chamada falha: `references/dados-eventos.md` (§18).
- **`<projeto>_ops` (control plane de desenvolvimento):** todo sistema multi-repo tem um repo **`<projeto>_ops`** — a ferramenta de operação do workspace, rodada por dev/agente e **fora do runtime do produto**. Faz bootstrap/instalação, update, manutenção, troubleshooting e roda os testes unitários/debug **através de todos os repos** (clona, sobe/para, migra, semeia e testa cada serviço). Não é microserviço nem é deployado com o produto; é essencial pra tocar um sistema de múltiplos repositórios. Como toda ferramenta, sobe com **observabilidade integrada** (Grafana/LGTM+, ver `references/observabilidade.md` §16).
- **Contenção no workspace (nunca sair da pasta do projeto):** o **diretório de projeto atual é o workspace**; toda aplicação/repo do sistema nasce e mora **dentro dele**. Vai criar uma aplicação nova? Crie uma **pasta pra ela dentro da pasta atual** (`./<projeto>_<contexto>/`) e trabalhe lá — **nunca** largue arquivos soltos no root pra depois **subir de diretório** (`cd ..`, `../`) e criar os outros repos fora. Num sistema multi-repo os repos são **irmãos dentro do mesmo workspace** (clonados ali pelo `<projeto>_ops`), não espalhados pela máquina. **VETADO** criar/ler/escrever fora do workspace: diretório-pai, `~`, `~/Documents`, `~/Downloads`, `/tmp` do usuário, Área de Trabalho. O agente **não sai da pasta do projeto** — nem pra vasculhar, nem pra criar — a menos que o usuário peça explicitamente.

**VETADO**
- **Aplicação monolítica que acopla múltiplos bounded contexts num só deploy/processo.** Não se cogita "começar monolito e quebrar depois" sem ADR explícito de plano e prazo de quebra. Misturar domínios de negócio "pra entregar rápido" é dívida disfarçada de produtividade.
- **Monólito distribuído** — o pior dos dois mundos: serviços separados fisicamente, mas acoplados por banco compartilhado, shared lib de domínio (§7) ou chamadas síncronas em cascata sem fronteira. Tão proibido quanto o monólito clássico.
- **Big ball of mud** — código sem fronteira de contexto, onde tudo importa tudo.

**SHOULD**
- Evitar mais de um domínio de negócio no mesmo repositório.
- Leitura cross-service por réplica read-only só com ADR e contrato documentado.

**MAY**
- *Modular monolith* (módulos com fronteira de contexto rígida, schema separado, comunicação por interface interna) **somente com ADR** que justifique estágio do produto e contenha o plano de extração. É exceção registrada, não default. Nunca usar como atalho para colar domínios.

> Não existe "MVP monolítico que vira microserviço depois" sem o ADR que prova que o depois tem data. Sem isso, "depois" é "nunca", e "nunca" é um big ball of mud em produção.

---

---

## 3. Linguagens

> Esta base define a **política de linguagem** da casa; o detalhe idiomático de cada uma está na skill irmã — `schematize-go`/`schematize-rust` (backend), `schematize-web` (frontend), `schematize-node` (legado Node).

**Backend — ROL SANCIONADO, escolhido por fit (detalhe e guia completo em `references/linguagens.md`).**

A casa não tem "a linguagem única"; tem o **rol sancionado** e um **guia de fit**. A escolha por serviço é decisão de **ADR** (§27), não de gosto:

| Linguagem | Skill | Fit típico |
|---|---|---|
| **Go** | `schematize-go` | serviços de rede/API, CLIs, tooling; **default pragmático** |
| **Rust** | `schematize-rust` | correção/segurança de memória, perf previsível, componentes sensíveis (auth/cripto/parsing); **default quando errar é caro** |
| **Elixir** | `schematize-elixir` | realtime, alta concorrência tolerante a falha (BEAM/OTP), messaging/streaming |
| **C#** | `schematize-csharp` | ecossistema .NET/enterprise, integração Microsoft, ASP.NET Core/EF |
| **Zig** | `schematize-zig` | baixo nível, perf máxima com memória explícita, embedded, interop com C |
| **Ruby** | `schematize-ruby` | prototipagem rápida, scripts, DX de produto (Rails), legado Ruby |

**Frontend — Node (e só frontend).** **Next.js** principal; **Astro e outros consolidados** permitidos. O server-side do próprio front (route handlers/server actions/BFF) faz parte do frontend (§13.4, §38: segredo só server-side). Isso **não** reabre Node como serviço backend (§3.1).

**MUST**
- Versão exata em uso fica no **anexo volátil** da skill de linguagem — `schematize-go`, `schematize-rust`, `schematize-elixir`, `schematize-csharp`, `schematize-zig`, `schematize-ruby`, `schematize-node` ou `schematize-web` → `references/stack-versoes.md` —, sempre com data de verificação. Nunca no corpo normativo.
- Não misturar linguagens dentro do **mesmo bounded context** sem ADR.
- **Backend novo em linguagem do rol** (Go/Rust/Elixir/C#/Zig/Ruby), **com ADR justificando o fit**. Fora do rol → §3.1 (Node/PHP em saída).
- **O piso de engenharia é o mesmo em todas** — a linguagem muda o "como", não os pisos de segurança/testes/IAM/ops/archive/DoD.

**SHOULD**
- Escolha por **encaixe com o problema** (guia de fit em `references/linguagens.md`); em empate técnico, o **default pragmático (Go)** vence e o ADR registra o porquê.
- Frameworks são bem-vindos; abstrações mágicas não. Critério: consigo entender o stack trace?

### 3.1 Node legado (backend) — migração para uma linguagem do rol

Node como linguagem de **serviço backend** está em saída (fora do rol sancionado). Tudo que existe em Node backend será migrado para **uma linguagem do rol** (`references/linguagens.md`, por fit — em geral Go/Rust), guiado por esforço (não big-bang) e medido **por funcionalidade do módulo**, não por linha.

**Modelo da métrica.** Um módulo tem N funcionalidades (ex.: 10 — cálculo, ABAC, CRUD, etc.). O quanto uma mudança "pesa" é a fração de funcionalidades que ela altera ou cria sobre o total do módulo. Ex.: módulo com 10 funcionalidades — refatorar 2 = 20%; refatorar 3 (ou criar ~4 novas) ≈ 30%.

**MUST**
- **Não mexer no que está feito em Node, a menos que solicitado.** Node backend funcionando fica como está até ser tocado.
- **Gatilho de extração (~30%):** quando uma mudança atingir ~30% das funcionalidades do módulo (alteradas + novas), **não cresça o Node** — extraia essa(s) funcionalidade(s) para um **módulo à parte numa linguagem do rol** (`references/linguagens.md`) e incorpore o comportamento Node nessa nova base.
- **Extração incremental:** conforme se mexe no módulo Node ao longo do tempo, vai-se extraindo aos poucos para Go/Rust.
- **Virada dos 50%:** quando ~50% do módulo já estiver extraído/inutilizado (substituído pela versão Go/Rust), **migra-se os 50% restantes de uma vez** — encerra o módulo Node.
- **Ajuste pontual não porta.** Mudança pequena/localizada (abaixo do gatilho) é feita no próprio Node, sem portabilidade.
- Toda migração registra ADR (§27) e segue o DDD híbrido/coexistência (§4.X, §36): flag de coexistência, sem big-bang.

> Os percentuais (~30% pra extrair, ~50% pra finalizar) são os limiares da casa; ajuste por ADR se um módulo específico exigir. A regra é: parou de ser ajuste pontual, vira extração; passou da metade, termina.

### 3.2 PHP — em saída (sem serviço novo)

PHP não é linguagem do rol: **nenhum código novo em PHP** (VETADO). Projeto PHP existente é legado
e **migra por funcionalidade quando tocado**, para uma linguagem do rol (`schematize-engineering →
references/linguagens.md` §2), com ADR (§27) — as mesmas regras de gatilho (~30%/~50%) de §3.1.

---

---

## 4. Arquitetura

**MUST — todos os projetos**
- Separação explícita de camadas: `domain`, `application`, `infrastructure`, `interface`.
- Inversão de dependência: domínio não conhece infra.
- Domínio não importa frameworks nem ORM.

**SHOULD — projetos com regra de negócio relevante**
- DDD tático (agregados, value objects, eventos de domínio).
- Arquitetura hexagonal (ports & adapters).

**MAY — CRUDs simples**
- Manter as 4 camadas, dispensar táticas DDD pesadas.

### Dependências permitidas

```
interface       → application
application     → domain
infrastructure  → domain, application
```

### Dependências proibidas

```
domain          → qualquer outra camada
domain          → frameworks, ORM, libs de IO
application     → interface
```

### Anti-Corruption Layer

**MUST** em integrações com sistemas externos: adapter dedicado em `infrastructure/external/` que traduz o modelo externo para o modelo de domínio. **Nunca** expor DTOs externos diretamente no domínio.

### 4.X DDD híbrido durante transição

Projetos legados onde código já existe sem separação de camadas **podem** adotar DDD progressivamente em vez de big-bang. Regras:

**MUST**
- Toda nova feature/refactor em código tocado segue o layout completo (`domain/`, `application/`, `infrastructure/`, `interface/`) — não introduzir mais código "flat".
- Ao mover/quebrar arquivo legado, organize já em folders DDD mesmo que internamente alguma classe ainda misture responsabilidades (ex.: service em `application/` ainda chamando SQL direto). Estrutura primeiro, inversão depois.
- Cada PR que toca arquivo híbrido **deve** mover ao menos um pedaço pra direção certa (ex.: extrair entidade pra `domain/`, mover query pra `infrastructure/repositories/`).
- ADR registrando o débito e o plano de remoção: `<projeto>/<projeto>_archive/decisoes/<n>-ddd-migration-<contexto>.md`.

**SHOULD**
- Manter teste de cobertura por camada (**schematize-qa**) durante a transição — domain começa com 0%, sobe a cada PR.
- Linter ou guard test que **rejeita imports proibidos** logo que possível (mesmo que com whitelist de exceções legadas):
  - `domain/` não importa `@nestjs/*`, `pg`, `axios`, `infrastructure/*`, `application/*`, `interface/*`.
  - `application/` não importa `interface/*`.

**MAY**
- Marcar arquivos híbridos com comment `// @ddd-hybrid` pra busca fácil e cleanup priorizado.

---

---

## 5. Estrutura de Pastas

### Node.js

```
src/
├── domain/           # entities, value-objects, services, events, repositories (interfaces)
├── application/      # use-cases, dto, commands, queries
├── infrastructure/   # persistence, messaging, external, observability
├── interface/        # http, grpc, cli
├── shared/
└── config/
tests/
```

### Go

```
cmd/<app-name>/
internal/
├── domain/
├── application/
├── infrastructure/
├── interface/
├── shared/
└── config/
tests/
```

### Rust

```
src/
├── domain/
├── application/
├── infrastructure/
├── interface/
├── shared/
└── config/
tests/
```

---

---

## 6. Complexidade e Tamanho

> **PONTEIRO — o canônico é `references/padroes-codigo.md`.** Esta §6 repetia **integralmente** os
> limites que já estão lá (750/500/300, doc-comment obrigatório, exceções), enquanto a própria
> linha de abertura declarava *"canônico em padroes-codigo.md"*. Trinta e nove linhas dizendo que
> não duplicavam, duplicando — achado do inventário da vistoria de 2026-08-21. Dois textos da mesma
> regra divergem; foi assim que **dois pisos passaram a existir só aqui** (ver abaixo).

O piso de tamanho, micro-funções, doc-comment e as exceções: **`references/padroes-codigo.md`**.

> **Se você chegou aqui por uma citação `§6`, está no lugar certo.** O catálogo cita **§6** como
> apelido de "pisos de código" em ~9 lugares (`check-diff.sh`, `/eng-review`, `/eng-scan`,
> `/eng-refactor`, `SKILL.md`, `CLAUDE.md`, `scan.md`, `refactor.md`) — o número vem da numeração
> histórica e **continua resolvendo aqui**, que é o ponteiro. O conteúdo mora no
> `padroes-codigo.md`. Manter o apelido é deliberado: reescrever as 9 citações trocaria um número
> conhecido por outro sem ganho, e o ponteiro já leva quem seguir a citação ao canônico em um salto.

**O que era exclusivo desta seção e foi PROMOVIDO para o canônico** — porque estava declarado como
*bloqueio de CI* e não existia em lugar nenhum que o CI lê:

- **Complexidade ciclomática > 15** em função de produção → bloqueia.
- **Aninhamento > 4 níveis** → bloqueia.

> Linha de código é proxy ruim para complexidade — a ciclomática é a métrica honesta. Mas arquivo
> gigante e função sem contexto continuam sendo sintoma barato de medir, e por isso os dois
> convivem.


## 7. Dependências Internas e Shared Libraries

**MUST**
- Shared libraries são **mínimas** e com escopo claramente delimitado.
- Permitido como shared: observabilidade, autenticação/auth, primitives de infraestrutura, SDKs internos, logging, configuração.

**MUST NOT**
- Criar `commons` / `core-lib` / `platform-utils` genéricos.
- Compartilhar **lógica de domínio** entre bounded contexts.
- Compartilhar entidades de domínio. Cada contexto modela o seu.

> O caminho mais rápido pra um monólito distribuído é uma shared lib chamada `commons`.

**SHOULD**
- Shared libs versionadas com SemVer próprio.
- Breaking changes em shared lib exigem ADR.

---

---

## 8. CQRS e Padrões de Aplicação

- **Commands**: alteram estado, retornam id ou void.
- **Queries**: nunca alteram estado, otimizadas para leitura, podem usar projeções.
- CQRS **não exige** event sourcing.

---

---
