# Escolha de linguagem — rol sancionado + guia de fit (agnóstico)

> A casa **não tem "a linguagem única"**; tem **o rol sancionado** e um **guia de fit**. A
> engenharia (esta base) é **agnóstica**: os pisos — segurança, testes, archive, DoD, IAM,
> ops, observabilidade — são **os mesmos em toda linguagem**. A linguagem muda o **como**, não
> o **o quê**. Cada linguagem sancionada tem uma **skill irmã** que especializa esta base.

## 1. O rol sancionado

**Backend (serviço novo) — escolha uma, com ADR (§27) justificando o fit:**

| Linguagem | Skill | Sufixo de repo | Prefixo de comando |
|---|---|---|---|
| **Go** | `schematize-go` | `_go` | `/go-*` |
| **Rust** | `schematize-rust` | `_rs` | `/rust-*` |
| **Elixir** | `schematize-elixir` | `_ex` | `/elixir-*` |
| **C#** (.NET) | `schematize-csharp` | `_cs` | **`/cs-*`** (não `csharp-`) |
| **Zig** | `schematize-zig` | `_zig` | `/zig-*` |
| **Ruby** | `schematize-ruby` | `_rb` | `/ruby-*` |

> O prefixo do comando **não se deriva** do nome da skill nem do sufixo de repo: em C# a skill é
> `schematize-csharp`, o sufixo é `_cs` e o comando é `/cs-iam` (não `/csharp-iam`). Nenhuma
> linguagem do rol é "principal" ou "auxiliar": o rol não tem hierarquia.

**Frontend:** **Node** (Next.js principal; Astro e outros consolidados) — governado por
`schematize-web`. É **só frontend** (o server-side do próprio front — route handlers/server
actions/BFF — faz parte do frontend).

## 2. Fora do rol (saída / legado — não reabrem)

- **Node como serviço backend** e **PHP** **não recebem serviço novo.** O que existe é
  **legado**: fica como está até ser tocado, e migra para uma linguagem do rol **por
  funcionalidade do módulo** (~30% afetado → extrai o módulo; ~50% extraído → migra o resto;
  ajuste pontual não porta). Detalhe da saída em `schematize-node` (Node); PHP segue a mesma regra
  — **migra por funcionalidade quando tocado**, sem prazo de "migração sumária". O ganho marginal
  de tooling não reabre a porta.
- **Nova linguagem fora do rol** exige **ADR de exceção** aprovado — não se adota por gosto.

### 2.1 Python — ferramenta, não backend de produto

Python **está na casa e continua** — dados/ML/analytics, automação, scripts de ops, o motor
`simulated` da `schematize-qa`. Isso nunca foi decidido em lugar nenhum, o que é o problema: um uso
implícito é um uso sem piso, e sem piso ele cresce para onde ninguém pretendia.

**A posição, agora explícita:**

- **Python é sancionado como FERRAMENTA:** pipeline de dados, treino/inferência de modelo,
  notebook de exploração (que **não é entregável**), automação e script de apoio. É onde o
  ecossistema não tem par, e trocá-lo por linguagem do rol seria perder biblioteca, não ganhar
  disciplina.
- **VETADO para API/serviço de produto NOVO — exatamente como Node.** Serviço novo nasce no rol
  (Go, Rust, Elixir, C#, Zig, Ruby), com ADR de fit. Não é sobre performance nem sobre gosto: é a
  mesma razão que tira o Node backend da mesa — a casa **não quer** manter piso de produção
  (empacotamento, tipos que travam o CI, concorrência, deploy) em mais um ecossistema, e um serviço
  de produto vive dez anos.
- **Serviço de ML que precisa servir modelo** é a exceção esperada, e ela **tem forma**: a
  inferência fica num serviço Python **fino e sem regra de negócio**, atrás de um serviço do rol
  que faz authz, validação e orquestração. O que não pode é o serviço Python virar o backend do
  produto por acumulação — que é como isso acontece de verdade, uma rota de cada vez.
- **O piso comum vale igual** (§4): teste, segredo, observabilidade, DoD, archive, IAM. Ferramenta
  não é sinônimo de terra sem lei — o `run.py` que a casa distribui é Python, e é código de
  produção do catálogo.

### 2.2 Sancionadas fora do rol de backend

Existem linguagens na casa que **não são do rol de backend** e têm piso próprio, cada uma com skill:

| Linguagem | Skill (comando) | Papel |
|---|---|---|
| **C** | `schematize-c` (`/c-*`) | **manutenção defensiva.** Componente novo de sistema nasce em Rust ou Zig; C entra só por ADR de exceção |
| **C++** | `schematize-cpp` (`/cpp-*`) | idem C: manutenção defensiva; componente novo nasce em Rust/Zig, por ADR |
| **Swift** | `schematize-swift` (`/swift-*`) | cliente Apple (iOS/iPadOS/macOS), sob a `schematize-mobile` |
| **Kotlin** | `schematize-kotlin` (`/kotlin-*`) | cliente Android/KMP, sob a `schematize-mobile` |
| **Dart** | `schematize-dart` (`/dart-*`) | cliente Flutter, sob a `schematize-mobile` |
| **Shell** | `schematize-shell` (`/shell-*`) | ferramenta: script de ops/instalador/hook; script é código de produção |
| **Python** | `schematize-python` (`/python-*`) | ferramenta (§2.1): dados/ML, automação — nunca serviço de produto novo |

Nenhuma dessas recebe **serviço backend novo**; o piso comum (§4) vale em todas.

## 3. Guia de fit — quando usar cada (a decisão vira ADR)

Escolha por **encaixe com o problema**, não por preferência; nenhuma linguagem do rol é
"padrão" nem hierarquicamente superior. A decisão vira ADR.

- **Go** — serviços de rede/API concorrentes, CLIs, tooling de infra/ops. Simplicidade,
  deploy de binário estático, concorrência por goroutines/canais.
- **Rust** — correção e **segurança de memória** críticas, performance previsível (sem GC),
  sistemas, componentes sensíveis (auth, cripto, parsing de input hostil), WASM.
- **Elixir** — **realtime e alta concorrência** tolerante a falha (BEAM/OTP), sistemas
  distribuídos, messaging/streaming, presença/pub-sub, soft-realtime. Let-it-crash +
  supervisão.
- **C# (.NET)** — ecossistema **.NET/enterprise**, integração Microsoft, times .NET, cargas
  com ASP.NET Core/EF Core, desktop/Windows quando aplicável.
- **Zig** — **baixo nível e performance máxima** com controle explícito de memória, embedded,
  **interop com C**, artefatos pequenos, tooling de sistema. Sem GC, sem controle de fluxo
  oculto.
- **Ruby** — **prototipagem rápida**, scripts/automação, DX de produto (Rails) onde velocidade
  de iteração pesa mais que throughput; e **manutenção de legado Ruby**.

> Regra de fit: um serviço de auth/cripto pede Rust; um gateway realtime pede Elixir; um
> job de rede simples pede Go; um utilitário de sistema pede Zig; uma integração .NET pede
> C#; um script/protótipo pede Ruby.
>
> **Desempate (a única regra de desempate da casa):** se mais de uma encaixa, vence (1) a que torna
> **mais barato errar menos** — onde errar é caro (cripto, auth, parsing hostil), Rust; depois (2) a
> que o time/produto **já opera** (menos ecossistemas para manter); persistindo o empate, escolha
> a de menor custo operacional e **registre o porquê no ADR**. Skills de linguagem apontam para
> aqui; não reescrevem esta regra.

## 4. O que NÃO muda com a linguagem (o piso é comum)

Independente da escolha, valem **integralmente** os pisos desta base (a linguagem só muda a
implementação):

- **Segurança:** segredo nunca no cliente, SQL/consulta sempre parametrizada, auth server-side,
  validação de input, sem erro engolido (`references/seguranca.md`, `anti-padroes.md`).
- **IAM por desenho** como app separada (`references/iam.md`).
- **Testes de verdade** + cobertura (skill **schematize-qa**) + pentest de rejeição (**schematize-pentest**).
- **Arquitetura/DDD**, bounded contexts, anti-monólito (`references/arquitetura.md`).
- **Ops** (fluxo de ambientes, `<projeto>_ops`, deploy destrutivo por seed), **observabilidade**
  (OTel), **archive + DoD + índice/MAPA** (§28, §35, §39).
- **Clean code** (`references/padroes-codigo.md`) — os limites de arquivo/função valem para
  todas; o "código útil" e o estilo de comentário se adaptam à linguagem na skill irmã.

> A skill de linguagem **especializa** cada um desses para os idiomas, o build, os gerenciadores
> de pacote, o modelo de concorrência e o ecossistema da linguagem — mas **nunca afrouxa o
> piso**. Escolher a linguagem é decisão de ADR; cumprir o piso não é opcional em nenhuma.
