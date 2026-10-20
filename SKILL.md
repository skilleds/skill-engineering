---
name: schematize-engineering
metadata:
  version: 0.29.0
description: >-
  Base normativa de engenharia, agnóstica. Use ao projetar, revisar ou refatorar software, escolher linguagem do rol (fit + ADR), modelar eventos/banco, ou rodar scan, plan, overdev e archive.
---

# Padrões de Engenharia da Casa (base comum)

Conjunto normativo que rege como software é projetado, construído, testado e operado aqui. Esta é a **base comum, agnóstica de linguagem** — o que se repete em toda a stack. As skills irmãs **especializam** esta base por contexto (linguagem, web, mobile, QA, pentest etc.); o catálogo completo, com o prefixo de comando de cada uma, é o `/schematize-help`. Use esta quando o projeto não é de uma linguagem específica, ou quando quer só os princípios da casa; use a irmã de linguagem quando há stack definida.

**Versão:** skill `schematize-engineering` v0.29.0. Changelog em `CHANGELOG.md`.

## Comandos (Claude Code)

Digite `/eng-help` pra ver todos. Em resumo:

| Comando | O que faz |
|---|---|
| `/schematize-help` | **índice único de TODAS as skills da casa** (lista viva a partir de `~/.claude/skills`): o que cada comando faz |
| `/eng-help` | lista todos os comandos do schematize-engineering |
| `/eng-load` | carrega à força TODO o corpo normativo no contexto e passa a aplicá-lo como regra inegociável |
| `/eng-claude` | cria/atualiza (sobrescreve, com backup) o `CLAUDE.md` da raiz com a versão atual da skill |
| `/eng-cc` | context compact: gera context.md + checklist.md no archive e roda `/compact` |
| `/eng-handoff` | gera o handoff (context.md + checklist.md) **sem** compactar — pra fim de sessão |
| `/eng-review` | roda o gate da DoD/§37 no diff (arquivo >750 bloqueia / >300 úteis flag, função sem doc, índice, macaquices) |
| `/eng-scan` | **varredura ampla** de problemas na base inteira (correção, anti-padrões, pisos, duplicação/morto, testes, concorrência, dados, supply chain, dívida, deriva de índice) — exaustiva, com fan-out; cada achado com `arquivo:linha`+severidade+conserto |
| `/eng-plan` | **planejamento extensivo** plan-first: entender→escopo→spikes→decompor no grafo→risco/rollback→ADR→paralelização→fases; gera o plano no archive, deriva o checklist e **pede aprovação** |
| `/eng-refactor` | **refactor disciplinado**: muda a forma sem mudar o comportamento, rede de testes ANTES (red-first), passos pequenos reversíveis, escopo-diff; gate exige mesma suíte verde + contrato idêntico |
| `/eng-audit` | **auditoria de histórico**: enumera todos os checklists (overdev/QA/handoff/plano/ADR/perguntas) e verifica se foram **sanados** — acha órfãos RED e trava se sobrar item aberto/sem prova |
| `/eng-index` | (re)gera o índice de microfunções (§39) a partir dos doc-comments |
| `/eng-orchestrate` | decompõe a tarefa em mini-tasks independentes e paraleliza com subagents (plan-first) — otimiza tempo sobre tokens; papéis (orquestrador só planeja/revisa) e hierarquia de agentes (principal Opus; haiku/sonnet → Codex Terra → Cursor → opus; visual direto ao Codex) |
| `/eng-overdev` | modo contínuo: força um checklist exaustivo e **não deixa parar** (Stop hook rejeita) até tudo `- [x]` e o gate passar — anti "entreguei micro-função e disse que terminei" |
| `/eng-ops` | audita/scaffolda o `<projeto>_ops` (interface única): fluxo de ambientes, instalação paralela (`nproc`), independência |
| `/eng-iam` | força/audita/scaffolda o IAM (identidade≠email, ≥2 fatores, ReBAC multi-tenant, sessão longa/logout irreversível) como app separado em `auth.<domain>`, ou porta um auth legado |

Os comandos ficam em `assets/commands/` e são instalados em `.claude/commands/`.

## Como usar esta skill

1. Identifique o domínio da tarefa e **leia o(s) reference(s) relevante(s)** antes de produzir código ou decisão. Não trabalhe de memória — os detalhes (versões, limites, convenções) estão nos arquivos.
2. **Sempre** aplique os pisos inegociáveis abaixo, independente do reference carregado.
3. Ao terminar, valide contra a Definition of Done (`references/entrega.md`, §35) e **gere o archive** (§28, `references/operacao.md`).

Mapa de references — leia o que casa com a tarefa:

| Tarefa | Reference |
|---|---|
| **Limites de código (arquivo ≤750: ~500 úteis + ~250 comentário; flag >300 úteis), uma função/arquivo, comentários, MAPA** | `references/padroes-codigo.md` |
| **Escolha de linguagem — rol sancionado (Go/Rust/Elixir/C#/Zig/Ruby) + guia de fit por problema; Node-backend/PHP em saída; o piso é o mesmo em todas** | `references/linguagens.md` |
| Arquitetura, camadas, DDD, repositórios, anti-monólito, shared libs, CQRS | `references/arquitetura.md` |
| Eventos/mensageria, banco, cache, APIs, resiliência, jobs | `references/dados-eventos.md` |
| Segurança, auth, JWT, multi-tenancy, LGPD, **frontend/segredos** | `references/seguranca.md` |
| **Cadeia de suprimentos: lockfile, SBOM, scan que trava, imagem mínima/pinada/assinada, SLSA, segredo no build** | `references/cadeia-suprimentos.md` |
| **Testes / Q.A. — MOVIDO pra skill dedicada `schematize-qa`** (pirâmide, "verde de verdade", a11y/visual, contrato/dados, flaky, cobertura, plan-first). A engineering mantém só o piso "a DoD exige testes verdes" — o COMO é lá | `references/testes.md` (ponteiro) → skill `schematize-qa` |
| Observabilidade, healthchecks, performance, FinOps | `references/observabilidade.md` |
| Config, deploy/K8s, git/PR, ownership, runbooks/incidentes, ADR, **archive** (§20–28) | `references/operacao.md` |
| **Ops (control plane): fluxo dev→local→github→hml→prd (nada direto no servidor), ops como interface única (100%, autônomo), instalação paralela=`nproc`, independência=invariante** | `references/ops.md` |
| **IAM (identidade+autorização): auth como app separada (`auth.<domain>`), ID≠email, ≥2 fatores/passkey/Resend/Twilio, ReBAC multi-tenant, sessão longa/logout irreversível, migração de legado** | `references/iam.md` |
| **EFEITOS EXTERNOS fora de prd (e-mail/SMS/push/webhook/pagamento): sink por default, domínio de teste em ROTA NULA (null MX + SPF `-all` + DMARC reject), guard deny-by-default no provider, cap por execução, 4 camadas** | `references/efeitos-externos.md` |
| Templates, feature flags, IA assistida, DoD, evolução, índice de funcionalidades (§29+) | `references/entrega.md` |
| Filosofia, aplicação universal e a lista completa de anti-padrões vetados | `references/anti-padroes.md` |
| **Orquestração & paralelização: decompor em mini-tasks e paralelizar com subagents (tempo > tokens), fan-out 8/teto 25, isolamento, gather; papéis (orquestrador não desenvolve) + hierarquia de agentes (principal Opus; haiku/sonnet → Codex Terra → Cursor → opus; visual direto ao Codex) (§9)** | `references/orquestracao.md` |
| **OVERDEV — desenvolvimento contínuo até o checklist fechar (Stop hook rejeita parada prematura; só termina 100% verificado)** | `references/overdev.md` |
| **SCAN de problemas — varredura ampla da base (todas as classes: correção, §37, pisos de código, duplicação/morto, testes, concorrência, dados, supply chain, dívida, deriva de índice), exaustiva + fan-out, achado com arquivo:linha+conserto** | `references/scan.md` |
| **PLANEJAMENTO extensivo — plan-first: entender→escopo→spikes→decompor no grafo→risco→ADR→paralelizar→fases; plano no archive, deriva checklist, pede aprovação** | `references/planejamento.md` |
| **REFACTOR disciplinado — muda a forma sem mudar o comportamento; rede de testes ANTES (red-first), passos pequenos, escopo-diff, catálogo seguro, gate de contrato idêntico** | `references/refactor.md` |
| **AUDITORIA de histórico — todo checklist criado foi sanado? enumera overdev/QA/handoff/plano/ADR/perguntas, acha órfãos RED, gera saneamento, trava se sobrar** | `references/auditoria.md` |
| Gestão de contexto em sessões longas no Claude Code (handoff, hooks) | `references/contexto-claude-code.md` |

## Pisos inegociáveis (VETADO — sem ADR de exceção)

Estes nunca são violados, nem "pra funcionar", nem "pra ir mais rápido". A lista completa com veto + caminho certo está em `references/anti-padroes.md` (§37). Os que mais aparecem em código gerado às pressas:

- **Segredo nunca no cliente.** Nada de API key, secret de JWT, senha de banco ou token em bundle do browser nem em `NEXT_PUBLIC_*`/`VITE_*`; só server-side. Detalhe em `references/seguranca.md`.
- **SQL sempre parametrizado.** Concatenar string em query é injeção esperando acontecer.
- **Auth e autorização server-side.** `tenant_id`/role/`user_id` vêm do token verificado, nunca do cliente. Validação no front é UX, não controle.
- **JWT validado por inteiro** (assinatura, exp, aud, iss, alg em allowlist). Senha: argon2id para senha nova; bcrypt/PBKDF2 só como legado, com rehash no próximo login (`references/iam.md`). Token/id de sessão por CSPRNG, nunca `Math.random()`.
- **Erro nunca engolido** (`catch {}`, `except: pass`, `_ = err`); sem `any`/`@ts-ignore`/`unwrap()` pra calar o compilador.
- **Teste nunca silenciado** pra passar CI (`.skip`, comentar assert, baixar threshold). Conserta o código, não o teste.
- **Sem monólito que mistura bounded contexts**, sem monólito distribuído, sem shared lib `commons` de domínio (`references/arquitetura.md`).
- **Archive SEMPRE gerado.** Toda entrega que produz código/decisão/mudança de estado gera o `.md` de archive (§28); pular é violação direta. Templates em `assets/`.
- **Migration reversível** (com `down`, testada com rollback). Container não-root, read-only. Dependência nova com nome/licença/versão verificados.
- **Pisos de código:** arquivo ≤ 750 linhas (flag em > 300 úteis), uma função por arquivo, toda função com doc-comment, `MAPA.md` e índice de microfunções no archive, todo MD gerado no archive e nunca no root. Detalhe em `references/padroes-codigo.md` e `references/operacao.md` (§28, §39).
- **Backend novo no rol sancionado (Go, Rust, Elixir, C#, Zig, Ruby), por fit + ADR**, sem hierarquia entre elas; frontend é Node (só front); Node-backend e PHP estão em saída (sem serviço novo; legado migra por funcionalidade quando tocado). Piso igual em toda linguagem. Escolha, desempate e linguagens fora do rol: `references/linguagens.md`; saída: `references/arquitetura.md` (§3).
- **Tempo do usuário acima de tokens.** Tarefa com ≥3 unidades independentes e não-triviais é decomposta e paralelizada com subagents (fan-out 8/onda, teto 25), plan-first; trabalho acoplado ou pequeno é inline. Detalhe em `references/orquestracao.md`.
- **Orquestrador não desenvolve; subagent barato executa.** O principal só planeja, despacha, supervisiona e revisa; principal = Claude Opus; executor mais barato que resolve (`haiku` mecânico, `sonnet` código → Codex `gpt-5.6-terra` → Cursor → subagent `opus` com motivo → `park`); visual direto ao Codex; imagem nunca pelo Claude (pergunta ao usuário qual usar, Codex sugerido; API de imagem paga proibida); papéis em `agentes.toml`; sem frota ociosa. Detalhe em `references/orquestracao.md` (§9, §9.6).
- **Mídia nunca pelo Claude; roteamento multi-modelo -> `schematize-models`.** Imagem/visual gerado só por Codex ou Gemini (o usuário escolhe; nenhum disponível: dizer sem rodeio); Claude fica com o código. Detalhe em `references/orquestracao.md` §9.7.
- **Fluxo de ambientes e ops.** dev local → teste local → GitHub → hml → prd; VETADO editar direto no servidor; 100% das operações pelo `<projeto>_ops`, instalação paralela (`nproc`), independência dos serviços como invariante. Detalhe em `references/ops.md`.
- **Deploy destrutivo por seed + um user Linux por serviço.** Redeploy recria a app a partir do seed (`/<app>/.env`) preservando os dados; cada serviço em systemd hardened. Detalhe em `references/ops.md` (§2–§3).
- **IAM por desenho.** Auth como app SEPARADA (`auth.<domain>`), ID imutável (email nunca é ID), ≥2 fatores, ReBAC multi-tenant deny-default, sessão longa e logout irreversível; migrar auth legado é prioridade 0. Detalhe em `references/iam.md`; scaffold/auditoria por `/eng-iam`.
- **Efeito externo NUNCA sai de não-produção.** E-mail, SMS, push, webhook e cobrança não acontecem de verdade fora de `prd`: endereço sintético só no domínio de teste em rota nula, provider default é o sink com guard fail-closed, cap por execução, chave sandbox. Regra completa, exceção (ADR + allowlist ≤5 + cap + janela + subdomínio) e o porquê em `references/efeitos-externos.md`; anti-padrão espelho: §37, *"Disparar efeito externo REAL a partir de não-produção"*.
- **UX de massa: prever o usuário leigo.** Software pro público nunca quebra nem culpa o usuário (root/sudo, PATH mínimo, sem toolchain, fechar no meio): se adapta e conserta sozinho, erro acionável e sem culpa. Detalhe em `references/anti-padroes.md`, §37, *"Culpar o usuário / exigir que ele saiba de internals / quebrar por invocação não-prevista"*.

> Regra de bolso: se a justificativa começa com "só pra funcionar", "depois eu arrumo" ou "é mais rápido assim" e o resultado mexe em segredo, auth, dado ou registro — é um anti-padrão vetado. Pare e faça certo.

## Testes / Q.A. — MOVIDO pra skill dedicada `schematize-qa`

A disciplina de teste/Q.A. da casa **saiu desta skill** e virou a skill dedicada **`schematize-qa`**
(pirâmide unit→componente→integração→e2e, "verde de verdade" no smoke, a11y/regressão visual,
contrato/dados, flaky, cobertura útil, plan-first `/qa-plan`/`/qa-run`, gates de CI). Detalhe em
`references/testes.md` (ponteiro) e na própria `schematize-qa`.

A engineering mantém **só o piso mínimo**, delegando o COMO pra lá:

- **A Definition of Done exige testes verdes** (§35, `references/entrega.md`): unit + integração passam,
  cobertura nos mínimos, caminhos críticos com teste explícito, smoke que prova conteúdo, `simulated`
  com rota 100% acessível. *Como* fazer cada um é a `schematize-qa`.
- **Teste nunca silenciado pra passar CI** (§37): `.skip`, comentar assert ou baixar threshold é VETADO.
- **Refactor exige rede de testes ANTES** (red-first, `references/refactor.md`).

> **Segurança ofensiva** (pentest de rejeição rota-por-rota, injeção/coerção, IDOR/BOLA, cross-tenant,
> hardening, red-team) é a **`schematize-pentest`** — não é Q.A. **Auditoria de histórico** (checklists
> sanados?) é a **`schematize-audit`**.

## Andaime pronto (scripts e templates)

Não escreva do zero o que já está bundlado:

- **Andaime de TESTE movido** → skill **`schematize-qa`** (`scripts/`): `lib.sh` (helpers), `test-skeleton.sh` (esqueleto de `tests/<mode>/<name>.sh`), `smoke-selfcheck.sh` (meta-teste anti "verde mentiroso"), `simulated/run.py` (engine rotas × personas × injections). Não estão mais aqui — use os da `schematize-qa`.
- `scripts/check-external-effects.sh` — **gate do piso de efeito externo** (§37, *"Disparar efeito externo REAL a partir de não-produção"*): trava se achar endereço de caixa real (`@gmail.com` etc.) em test/seed/fixture/persona, credencial de provedor de envio em `.env` de não-prd que não seja sandbox, envio sem cap por execução, ou (com `TEST_MAIL_DOMAIN` + `dig`) domínio de teste **sem null MX**. Já plugado no `assets/ci/github-actions-ci.yml`.
- `scripts/hooks/context-monitor.mjs` + `scripts/hooks/precompact-backup.mjs` — gestão de contexto no Claude Code: detectam o limite de handoff (default 250k) e fazem backup automático em `<projeto>/<projeto>_archive` antes da compactação. Ver `references/contexto-claude-code.md` e `assets/settings.claude.example.json`.
- `assets/ADR.md`, `assets/TASK.md`, `assets/CHAT_ARCHIVE.md`, `assets/PR_TEMPLATE.md`, `assets/RUNBOOK.md` — templates. ADR/TASK/CHAT_ARCHIVE cumprem §27/§28.
- `assets/GRAFO_GLOBAL.md` + `assets/INDEX_GLOBAL.md` + `assets/INDEX_FUNCTIONS.md` + `scripts/build-index.mjs` — grafo de funcionalidades (§39), **grafo GLOBAL de dois níveis**: o global (serviços como nós com funções principais, contratos como arestas ASCII `A -> B`) é mantido à mão; o detalhado por-serviço (funções como nós) é **gerado** dos doc-comments (§6) pelo `build-index.mjs`, que sai 1 se achar função sem contexto (trava CI). **Local operacional vivo:** `.schematize/grafos/` (o que o app desenha); **espelho durável:** `<projeto>/<projeto>_archive/index/`.
- `assets/CORE.md` — **núcleo sempre-on** da casa (≤4 KB, marcador `<!-- schematize-core vX.Y.Z -->`): condensa os pisos 13 e 19 (paralelizar, orquestrador não desenvolve) e os 20 e 21 (matriz de acesso por rota; passkey na fase 0), mídia fora do Claude, overdev, GitHub como fonte da verdade e efeito externo. Instalado globalmente pelo app `schematize` em `~/.claude/CLAUDE.md` (entre marcadores) e injetado via hook SessionStart. Guarda: `scripts/core-md.test.sh`.
- `assets/CLAUDE.md` — arquivo "sempre on" pra colocar na **raiz do repositório**: garante que estes padrões fiquem pinados no contexto de toda tarefa, não só quando a skill dispara. Copie e ajuste `<project>`.
- `assets/commands/eng-cc.md` — comando `/eng-cc` (context compact) pro Claude Code: gera `context.md` + `checklist.md` em `<projeto>/<projeto>_archive` e compacta. Copie para `.claude/commands/eng-cc.md`. Ver `references/contexto-claude-code.md`.

## Aplicação sempre-on

Esta skill é puxada quando a tarefa casa com a descrição. Para garantir que os padrões valham em **toda** interação do repo (e não só nas que disparam a skill), copie `assets/CLAUDE.md` para a raiz do projeto. Os dois mecanismos se complementam: o `CLAUDE.md` pina o resumo e aponta pra cá; a skill entrega o detalhe e o andaime.
