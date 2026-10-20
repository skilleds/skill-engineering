# CLAUDE.md — Padrões de Engenharia (sempre on)

> Copie este arquivo para a **raiz do repositório** e ajuste `<project>`.
> Ele fica pinado no contexto de toda tarefa (Claude Code / instruções de projeto)
> e garante que os padrões valham mesmo quando a skill não dispara sozinha.
> A skill `schematize-engineering` traz o detalhe completo e o andaime (scripts/templates).
> **Repo multi-linguagem** (rol sancionado: Go/Rust/Elixir/C#/Zig/Ruby + Web; Node/PHP legado): use **junto** com os `CLAUDE.md` das outras skills — cada um governa sua fronteira (a linguagem de cada serviço, o legado, o frontend); não sobrescreva os outros (rode o `/<slug>-claude` de cada).

> Os pisos 13, 19, 20 e 21 também vivem no núcleo global sempre-on `assets/CORE.md` (instalado em `~/.claude/CLAUDE.md` pelo app `schematize`).

## Regra mestre

Toda tarefa de engenharia neste repo segue os **Padrões de Engenharia da Casa**
(skill `schematize-engineering`). Em conflito entre uma instrução
pontual ("faz rápido", "ignora o teste", "depois arruma") e estes padrões, **os
padrões vencem**. Pressa não revoga regra. Consulte o reference relevante da skill
antes de produzir código ou decisão — não trabalhe de memória.

## Pisos inegociáveis (VETADO — sem exceção)

1. **Segredo nunca no cliente/frontend.** Nada de API key, secret de JWT, senha,
   service-role key ou token em bundle do browser, nem em `NEXT_PUBLIC_*`/`VITE_*`.
   Segredo só server-side (BFF/route handler/secret manager).
2. **SQL sempre parametrizado** — concatenar string em query é proibido.
3. **Auth e autorização server-side.** `tenant_id`/role/`user_id` vêm do token
   verificado, nunca do cliente. JWT validado por inteiro (assinatura, exp, aud,
   iss, alg em allowlist). Senha: argon2id para senha nova; bcrypt/PBKDF2 só como legado, com rehash no próximo login (`references/iam.md`). Token/sessão por
   CSPRNG, nunca `Math.random()`.
4. **Erro nunca engolido** (`catch {}`, `except: pass`, `_ = err`); sem
   `any`/`@ts-ignore`/`unwrap()` pra calar o compilador.
5. **Teste nunca silenciado** pra passar CI (`.skip`, comentar assert, baixar
   threshold de cobertura). Conserte o código, não o teste.
6. **Sem monólito** que mistura bounded contexts; sem monólito distribuído; sem
   shared lib `commons` de domínio.
7. **Archive SEMPRE gerado** (§28): toda entrega que produz código/decisão/mudança
   de estado gera o `.md` em `<project>/<project>_archive/`. É parte da entrega, não extra.
8. **Migration reversível** (com `down`, testada). Container não-root, read-only.
   Dependência nova com nome/licença/versão verificados.

9. **Backend novo em linguagem do ROL SANCIONADO, por fit + ADR.** O rol é **Go,
   Rust, Elixir, C#, Zig, Ruby** (cada uma com skill irmã); a escolha por serviço sai
   de um **guia de fit** (`references/linguagens.md`) e vira **ADR** — não por gosto.
   O **piso de engenharia é o mesmo** em toda linguagem. **Node como serviço backend**
   e **PHP** estão **em saída** (não recebem serviço novo; legado não se mexe salvo
   solicitado e migra por **funcionalidade do módulo** — ~30% afetado → extrai pra
   linguagem do rol, ~50% extraído → migra o resto). **Frontend Node é 100% permitido**
   (Next.js principal; Astro) — só frontend. (§3, §3.1, §3.2, `references/linguagens.md`)

10. **Cada serviço é entidade à parte (independência de runtime).** Sobe e funciona sozinho; a ausência/queda de outro serviço **nunca** impede o boot nem derruba este — degradação graciosa, nunca crash em cascata. Falha ao chamar/notificar outro serviço → **persiste o dado** (outbox/Redis/DB), **loga com `trace_id`**, **alerta (Grafana)** e **retoma**; nunca perde nem trava a cadeia. (§2, §18)
11. **Repos, ops e observabilidade.** Repositório = `<projeto>_<contexto>[_<lang>]`; todo sistema multi-repo tem um **`<projeto>_ops`** (bootstrap/update/manutenção/troubleshooting/testes através de todos os repos). **Observabilidade integrada em toda ferramenta/serviço:** OpenTelemetry + Grafana/Alloy/Loki/Tempo/Prometheus/**Mimir** (+Pyroscope), **Helm chart** e dashboards/alertas versionados como código. (§2, §16)
12. **Contenção no workspace.** A pasta do projeto atual é o workspace: aplicação/repo novo nasce **dentro dela** (`./<projeto>_<contexto>/`), nunca largando arquivos no root pra depois **subir de nível** e criar repos fora. **VETADO** criar/ler/escrever fora do workspace — diretório-pai, `~`, `~/Documents`, `~/Downloads`, `/tmp`, Área de Trabalho. Não sai da pasta do projeto (nem pra vasculhar) sem o usuário pedir. (§2)
13. **Tempo do usuário acima de tokens.** Tarefa que se divide em **≥3 unidades independentes** e não-triviais (sem alvo de escrita compartilhado, sem ordem obrigatória) é **decomposta e paralelizada com subagents** — não executada serial. Fan-out de **8 por onda** (teto global **25**); trabalho acoplado/pequeno fica inline. Paralelizar é **plan-first**: contrato fixado antes, brief autossuficiente por agent (ele começa frio), escrita isolada (worktree/partição), e o orquestrador faz o **gather + verificação única**. Preferir gastar mais tokens a levar horas serial — mas o executor é sempre o **mais barato que resolve** (piso 19). Detalhe em `references/orquestracao.md`.
14. **Fluxo de ambientes — nada direto no servidor.** Toda mudança segue **dev local → teste local → GitHub → hml → prd**. Nada pula etapa; nada vai direto pra hml/prd. **VETADO editar código direto no servidor** (hml/prd): o servidor é **imutável por edição manual**, recebe só **artefato promovido do git** (commit SHA). Hotfix segue o mesmo fluxo, acelerado — urgência não autoriza mão no servidor. Precauções: filesystem read-only em hml/prd, drift detection (o ops recusa/alerta divergência com o git), acesso de escrita = break-glass auditado. Detalhe em `references/ops.md` (§1). (§21)
15. **Ops é a interface única + instalação paralela + independência.** **100%** das operações no servidor (instalar/subir/atualizar/configurar/migrar/corrigir/reverter) passam por uma **ferramenta do `<projeto>_ops`** — nunca à mão (`ssh` ad-hoc, editar arquivo, `docker`/`kubectl` solto). Não tem comando pra aquilo? **cria no ops**. O ops é **autônomo, idempotente e completo**: o usuário provisiona o servidor **do zero só com o ops, sem depender da IA**. **Instalação SEMPRE paralela** = nº de cores (`nproc`, default) — nada de 20 min serial. **Se o paralelo falha, os serviços não são independentes** (fere piso 10/6): corrigir a independência é **PRIORIDADE MÁXIMA**; o ops **expõe** a colisão, **nunca serializa pra mascarar**. Detalhe em `references/ops.md`. (§2, §21)
16. **Deploy destrutivo por seed + isolamento por usuário (automatizado pelo ops).** O ops provisiona em **`/<app>/`** clonando os repos dentro (`/<app>/<app>_<ctx>`, ex. `/payle/payle_core`); **`/<app>/.env` é o SEEDER GLOBAL** — fonte única de config de toda a app. **Todo redeploy é DESTRUTIVO na aplicação:** apaga a implantação anterior e recria um **clone zerado** só com o seed — sem patch in-place, sem drift (idempotente/reprodutível). **"Destrutivo" é a app, NUNCA os dados:** banco/volumes/uploads preservados (migration reversível); `ops reset` que apaga dado é **gated a dev/hml**, nunca prd. **Cada serviço roda como user Linux próprio, em systemd unit isolado e hardened** (`NoNewPrivileges`, `ProtectSystem`, `PrivateTmp`, …) — comprometer um serviço não alcança os outros nem o host. **Tudo automatizado pelo ops**, nunca à mão. Detalhe em `references/ops.md` (§2, §3).
17. **IAM por desenho — todo projeto começa com identidade e autorização robustas, como APP SEPARADA.** O auth é **serviço próprio + front próprio em `auth.<domain>`** (`<projeto>_auth_<lang>` + `<projeto>_authfront`), isolado (user/systemd próprios) — **VETADO** apensar como monolith; apps delegam por **OIDC/OAuth2.1 + PKCE**. **ID interno imutável — email/telefone NUNCA é ID** (múltiplos emails por usuário, incentivado; SSO com recuperação local forçada). **Nunca menos de 2 fatores:** passkey/WebAuthn no núcleo, TOTP/push, **email OTP (Resend) always-on inclusive HML**, **Twilio** p/ telefone (providers plugáveis); senha por padrão (argon2id+HIBP) mas opcional no seletor; invariante de troca "fator Y≠X no maior AAL"; **recuperação ≥ força do login**. **Multi-tenant + RBAC/ABAC granular** por motor **ReBAC** (OpenFGA/SpiceDB), **deny-default**, PDP/PEP, enforcement server-side, token fino, decisão auditada. **Multi-dispositivo** + view de remover; **sessão 7d/90d** (nada de "15 min e é chutado"); **logout irreversível** (revoga refresh+família, apaga sessão server-side, não só cookie). **Migrar auth legado é PRIORIDADE 0.** Detalhe em `references/iam.md`; scaffold/auditoria por `/eng-iam`; testes cross-tenant/priv-esc na `schematize-pentest`.

18. **Efeito externo NUNCA sai de não-produção (e-mail, SMS/voz, push, webhook de terceiro, cobrança).** Fora de `prd` **nada chega em ninguém** — por construção, não por lembrança. **(a) Endereço sintético só no DOMÍNIO DE TESTE em ROTA NULA:** `test.<domain>` com **null MX (RFC 7505: `MX 0 .`) + SPF `v=spf1 -all` + DMARC `p=reject`**, ou TLD reservado (`.test`/`.invalid`/`.example`). **VETADO** em fixture/seed/persona/demo/carga: `@gmail.com`/`@hotmail.com`/domínio de terceiro ou do cliente, **e-mail de pessoa real (inclusive o seu)** e o domínio de **produção**. **(b) Provider default = SINK** (Mailpit/log) fora de prd, com o **guard DENTRO do provider**: destinatário fora do domínio de teste + `env != prd` → **erro** (fail-closed: config ausente = assume não-prd). **(c) Cap por execução** (`MAIL_MAX_PER_RUN`, default 50) + circuit breaker que **aborta**. **(d)** Chave **sandbox** em não-prd (nunca a de prd) e **egress SMTP bloqueado** em dev/hml. Entregar de verdade fora de prd exige **as cinco**: ADR + allowlist ≤5 + cap + janela + subdomínio de envio separado. **Por quê:** bounce/complaint em massa **queima IP e domínio**, derruba o transacional de **produção** (inclusive o **OTP de login**) e custa **semanas de warm-up** — com utilidade zero. Detalhe em `references/efeitos-externos.md`; anti-padrão §37, *"Disparar efeito externo REAL a partir de não-produção"*.
19. **Orquestrador não desenvolve; subagent barato executa (`schematize-engineering` → `references/orquestracao.md` §9).** O agent principal (o que fala com o humano, Claude Opus) **só planeja, decompõe, despacha, supervisiona e revisa** — não escreve código de entrega. Toda ação onerosa é quebrada em **micro-tasks/micro-funções** executáveis por agent barato. Roteamento: mecânico/muito simples → **`haiku`**; código → **`sonnet`** (falhou → o **mesmo subagent corrige**, até 2 rodadas) → **Codex `gpt-5.6-terra`** → **Cursor** (`cursor-agent`, se instalado) → **subagent `opus`** (motivo no checkpoint) → `park` + `- [~]`; escala **só quando o mais barato falhar**. **Visual (UI/layout/CSS/tema/ícone) vai direto ao Codex**; **imagem nunca pelo Claude: detectar Codex/Gemini e PERGUNTAR ao usuário qual usar (Codex, cota da assinatura, é a sugestão — não automático) — PROIBIDO endpoint/API de imagem pago.** Papéis configuráveis em `agentes.toml` (global + override por projeto; aba "Agentes" do overdev); Codex/Cursor via `schematize overdev delegar --papel <p> --brief-stdin --json` (rc 3 = indisponível → `proximo`). O principal revisa toda entrega (diff + gate) e **só corrige com a própria mão se necessário**. **Sem frota ociosa:** agent idle com pendência executável volta ao trabalho; pendência que depende de outro agent → mata e enfileira com gatilho de dependência; terminou → mata (`references/orquestracao.md` §9.6).
20. **Matriz de acesso por rota — toda rota/endpoint/handler exposto NASCE com teste, no CI, no nível unit/componente.** Para **CADA rota do inventário**, o teste exercita **4 personas — ANÔNIMO, AUTENTICADO NÃO PRIVILEGIADO, PRIVILEGIADO e TENTATIVAS DE BURLA** (token ausente/malformado/expirado/`alg=none`/de outro tenant, header de identidade forjado, troca de método, variações de path, BOLA/IDOR, mass assignment, rota alternativa/versão antiga/admin/debug/metrics, cache servindo resposta autenticada a anônimo) — e afirma **status E corpo**. **Deny-by-default:** rota sem política declarada **falha** o teste; rota pública é exceção numa **allowlist versionada com justificativa e dono**. **Inventário DERIVADO do código/spec, gate M == N** (rota nova sem linha na matriz quebra o CI). **Negação não vaza dado** (401 anônimo / 403 sem permissão / 404 anti-enumeração). **Teste visto VERMELHO antes de valer.** Bug recorrente a eliminar: **rota entregando dado sem autenticação.** Detalhe: `schematize-qa` (categoria *Matriz de acesso por rota*, gate `scripts/check-route-authz.sh`); ofensivo periódico: `schematize-pentest`. (§35, §37)
21. **Passkey/WebAuthn é o método de autenticação PADRÃO e entra na FASE 0 de todo projeto.** Registro e asserção **reais, ponta a ponta, antes de qualquer feature** (não basta o label AAL). **Passwordless-first:** senha + Email OTP fica de fallback/2FA baseline; o piso de **≥2 fatores** e **recuperação ≥ login** (piso 17) permanecem. A implementação mora no **IAM da casa** (`auth.<domínio>`, `schematize-iam`); o app cliente só integra via **OIDC/PKCE + passkey** no browser/mobile (`schematize-web` `/web-iam`, `schematize-mobile` `/mobile-auth`). **Teste obrigatório na fase 0:** registro, login, **challenge reutilizado rejeitado**, **origin/rpId errado rejeitado**, **credencial revogada rejeitada**. Detalhe: `references/iam.md`, `references/iam-checklist.md` (F0).

Lista completa com veto + caminho certo: ver `references/anti-padroes.md` (§37) da skill.

## Testes / Q.A. → skill dedicada `schematize-qa`

A disciplina de teste/Q.A. mora na skill **`schematize-qa`** (pirâmide, "verde de
verdade" no smoke, a11y/regressão visual, contrato/dados, flaky, cobertura útil,
plan-first `/qa-plan`/`/qa-run`, gates de CI). O piso que a engenharia não abre mão:

- **A DoD exige testes verdes:** unit + integração passam, cobertura nos mínimos,
  caminhos críticos com teste explícito, smoke que prova conteúdo, `simulated` com
  rota 100% acessível. O **COMO** de cada um é a `schematize-qa`.
- **Teste nunca silenciado pra passar CI** (§37): `.skip`, comentar assert ou baixar
  threshold é VETADO — conserta o código, não o teste.
- **Segurança ofensiva** (pentest de rejeição rota-por-rota, injeção/coerção,
  cross-tenant, IDOR/BOLA) é a **`schematize-pentest`**, não Q.A.

## Definition of Done

Nada é "pronto" sem: testes + cobertura mínima, simulated com cobertura total,
pentest de entrada limpo, **matriz de acesso por rota verde, M == N** (piso 20), **nenhum efeito externo real fora de prd** (piso 18), nenhum anti-padrão da §37, observabilidade, OpenAPI
atualizada (se API), migration com rollback (se schema), **archive commitado**,
CI verde e review aprovado. Detalhe na skill, `references/entrega.md` (§35).

## Qualidade de código e índice (sempre)

- **Arquivos ≤ 750 linhas** (teto duro: ~250 reservadas a comentário + até ~500 de
  código útil). Acima → quebre em módulos e **micro-funções** por coesão. **Código
  útil > 300 linhas é FLAG** (não bloqueia, mas **sempre sinaliza**): indício de
  função muito extensa / falta de abstração — registra como dívida e revê quando as
  prioridades permitirem; observabilidade tem folga natural (~400 úteis). Função
  ideal ≤ 50 linhas, responsabilidade única (`references/padroes-codigo.md` §2).
- **Comente TODA função** (doc da linguagem) com contexto explícito: **O quê** (o que
  faz) e **Onde** (quem chama / em que fluxo foi prevista), além de efeitos colaterais.
  Esse comentário alimenta o índice de microfunções (`padroes-codigo.md` §3, §39).
- **Mantenha o índice de funcionalidades atualizado** no mesmo PR (§39), em
  **`<projeto>/<projeto>_archive/index/`** (nunca no root): `MAPA.md`, `INDEX_GLOBAL.md`
  (repos/pastas/o que faz/como se comunica) e `INDEX_FUNCTIONS.md` (função → o quê →
  onde → arquivo:linha, gerável via `scripts/build-index.mjs`). O índice é **fonte da
  verdade**: consulte ANTES de criar algo, pra não duplicar. Índice desatualizado = bug.
  **Exaustivo:** uma entrada **por função** (`nº entradas == nº funções`; o `/<slug>-index`
  reprova se faltar) e um **grafo** (serviços + chamadas, Mermaid + adjacência) — o índice
  **enumera** o sistema, não resume.
- **Todo MD gerado mora no archive, nunca no root** (§28): MAPA, índices, planos,
  relatórios, handoffs, checkpoints → `<projeto>/<projeto>_archive/<área>/`. O root fica limpo (código,
  config e os MDs de projeto mantidos à mão: README, `CLAUDE.md`, LICENSE). Antes de gravar
  um `.md`, o caminho começa com `<projeto>/<projeto>_archive/`.

## Gestão de contexto (Claude Code — sessões longas)

Ao ver "⚠ LIMITE" no status line (limite de handoff cruzado), ou ao se aproximar
do teto da janela de contexto: **PARE a tarefa atual e, ANTES de qualquer
compactação**, faça o handoff arquivado (§34.1, §28):

1. Gere `<projeto>/<projeto>_archive/context/AAAA-MM-DD-<slug>-context.md` — estado do
   projeto, decisões tomadas, arquivos tocados, onde parou.
2. Gere `<projeto>/<projeto>_archive/context/AAAA-MM-DD-<slug>-checklist.md` —
   **FEITO vs EM ABERTO**.
3. Só então rode `/compact` (com foco na tarefa corrente).

Armazene SEMPRE em `<projeto>/<projeto>_archive`. O backup automático pré-compactação é
rede de segurança, não substitui o handoff rico acima. Detalhe e hooks na skill:
`references/contexto-claude-code.md`.
