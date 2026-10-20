# Changelog — schematize-engineering

Todas as mudanças relevantes deste pacote, no formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
com versionamento [SemVer](https://semver.org/lang/pt-BR/).
## [0.30.0] — 2026-10-20
### Adicionado
- Pisos **20** (matriz de acesso por rota) e **21** (passkey na fase 0) em `assets/CLAUDE.md`; dois bullets no `CORE.md` (marcador v0.30.0).
- Passkey na fase 0 e suas 5 provas como pré-condição do GATE F0 (`iam.md`, `iam-checklist.md`); herdado `iam-desenho` atualizado e sincronizado nas skills filhas.
- DoD (`entrega.md`) e anti-padrões "20b. Rota sem matriz de acesso" e "47a. Passkey adiada"; `eng-iam`, `eng-review` e `eng-scan` atualizados.
- Porquê: rota sem authn e login sem passkey eram falhas recorrentes.


## [0.29.0] — 2026-10-15
Skill só carrega sob demanda; em máquina nova o agente ignorava a orquestração com subagents. Nasce o núcleo sempre-on.

### Adicionado
- `assets/CORE.md`: núcleo curto (≤4 KB) que o app `schematize` instala no `~/.claude/CLAUDE.md` global (entre marcadores) e injeta via hook SessionStart; condensa pisos 13/19 e `orquestracao.md` §9/§9.6/§9.7, mídia, overdev, GitHub como fonte da verdade e efeito externo. Marcador `<!-- schematize-core vX.Y.Z -->` para o app detectar desatualização.
- `scripts/core-md.test.sh`: falha se o CORE.md passar de 4096 bytes/60 linhas ou o marcador divergir de `VERSION`.
- `SKILL.md` e `assets/CLAUDE.md` apontam para o CORE.md.

### Mantido (piso inalterado)
- Todos os pisos e referências: nenhuma regra nova, apenas condensação das existentes.

## [0.28.1] — 2026-10-14
O catálogo passou a 46 skills com a entrada de `schematize-bots`.

### Alterado
- `assets/commands/schematize-help.md`: 46 skills; entram `schematize-bots` e os comandos `/bot-*`.

## [0.28.0] — 2026-10-14
O catálogo passou a 45 skills e 8 delas tomaram assuntos que a base detalhava; a base mantém o piso e aponta a dona.

### Alterado
- `assets/commands/schematize-help.md`: 45 skills (entram skill-dev, git, incident, iam, api, postgres, analytics, payments, cada uma na seção do seu domínio).
- Ponteiros em vez de duplicação: `iam.md` e `iam-checklist.md` -> `schematize-iam`; contrato de API/webhook em `dados-eventos.md` e `anti-padroes.md` -> `schematize-api`; cobrança em `efeitos-externos.md` -> `schematize-payments`; incidente/postmortem em `operacao.md` e `ops.md` -> `schematize-incident`; Conventional Commits em `operacao.md` -> `schematize-git`.
- `/eng-iam` cita `/iam-audit` e `/iam-review`.
- description reduzida a 190 caracteres (orçamento de descriptions do catálogo estourou com 45 skills).

### Adicionado
- Testes com vermelho plantado para `scripts/archive-secret-scan.sh`, `scripts/check-diff.sh` e `scripts/build-zip.sh` (o gate de `schematize-skill-dev` cobra teste em todo script).

### Corrigido (achado pelos testes novos)
- `archive-secret-scan.sh`: a regra de `password=` usava `[^ \n"']`; em ERE o `\n` dentro de colchete é a letra `n`, então senha com `n` passava em branco. Agora `[^ "']`.
- `check-diff.sh`: CORS `*` não pegava `Set("Access-Control-Allow-Origin", "*")` (faltava a vírgula na classe); base inexistente (ex.: `origin/main` ausente no CI) dava OK com diff vazio e agora bloqueia.

## [0.27.1] — 2026-10-14
A skill nova `schematize-models` precisa ter um ponto de entrada na base.

### Adicionado
- **`references/orquestracao.md` §9.7** e 1 linha no `SKILL.md`: piso "mídia nunca pelo Claude" (imagem/visual gerado só por Codex ou Gemini, escolhido pelo usuário; nenhum disponível: dizer sem rodeio e oferecer alternativas) e ponteiro de roteamento multi-modelo para `schematize-models` (Claude fica com o código; outro modelo só por mídia, segunda opinião, vantagem documentada ou pedido do usuário).

### Alterado
- Description reduzida (≤235 chars) para caber no orçamento de listagem de skills (soma ≤8300); mesmo território, fronteiras com as irmãs preservadas.
- `references/observabilidade.md` §16 e §17 viram **ponteiros** para a nova skill `schematize-observability` (dona do tema: padrão OpenTelemetry, cardinalidade, amostragem, burn-rate, stack, ambientes), preservando os headings §16.1 a §16.6, §17, §30 e §33 (outras skills os citam) e os pisos da base; §16.6 ganha "auditoria não é log de debug".

### Alterado
- Fontes herdadas (`assets/herdados/`) alteradas; os blocos nas derivadas seguem por `tools/sync-herdados.mjs`:
- **Regra de imagem (decisão do usuário, vale sobre a v0.27.0):** imagem nunca pelo Claude; detectar Codex/Gemini e SEMPRE perguntar ao usuário qual usar, com Codex como primeira sugestão e não como automático. Ajustados `orquestracao.md` (cabeçalho, §9.3 tabela de roteamento e de papéis), `overdev.md`, `eng-overdev.md`, `eng-orchestrate.md`, `SKILL.md`, `assets/CLAUDE.md` e os herdados `orquestracao.md`/`precedencia.md`, coerentes com o §9.7.
- `schematize-overdev delegar` -> `schematize overdev delegar` (era o comando do app, lido pelo lint como skill irmã inexistente) na fonte herdada e em `orquestracao.md`/`overdev.md`/`eng-orchestrate.md`.
- `assets/herdados/precedencia.md`: nova variante **`dominio`** (skills de domínio/ferramenta herdam os pisos da base; seus comandos cobrem o domínio) — a `foraRol` dizia "cobrem só o piso da linguagem".
- `SKILL.md`: linha `**Versão:**` corrigida para v0.27.0 (ficou em v0.26.0).
- `/schematize-help`: catálogo passa a 37 skills (design, models, seo-writing, docker, terraform, observability nos grupos certos).

## [0.27.0] — 2026-10-14
Hierarquia de agentes (ADR-0024): o orquestrador continua sem desenvolver, mas a escada deixa de ser só `sonnet → opus` e passa a roteamento por tipo de tarefa, com Codex e Cursor como motores de fallback.

### Alterado
- **`references/orquestracao.md` §9** (e `herdados/orquestracao.md`, `CLAUDE.md` item 19, `precedencia.md`, `SKILL.md`, `overdev.md`, `eng-overdev.md`, `eng-orchestrate.md`): principal = **Claude Opus** (só orquestra); mecânico → **Haiku** (~1/100 do custo do Opus); código → **Sonnet** (até 2 rodadas pelo mesmo subagent) → **Codex `gpt-5.6-terra`** → **Cursor** (`cursor-agent`, se instalado) → **subagent Opus** (motivo no checkpoint) → `park`/`- [~]`; escala só quando o mais barato falhar.
- **Visual** (UI/layout/CSS/tema/ícone) vai **direto ao Codex**; **imagem** é pedida ao Codex Terra (cota da assinatura) — **API/endpoint de imagem pago PROIBIDO**.
- Checkpoint (§7/§9.4) ganha a coluna **motor** além de **modelo**; tags de executor do overdev: `[haiku]`/`[sonnet]`/`[codex]`/`[cursor]`/`[opus: <motivo>]`.

### Adicionado
- §9.3: tabela de roteamento, tabela de papéis default (`principal`, `trivial`, `executor`, `fallback-1`, `fallback-cursor`, `fallback-2`, `visual`, `imagem`, `complementar`), configuração em `agentes.toml` (global `~/.claude/schematize/agentes.toml` + override por projeto) e na aba "Agentes" do overdev, e como chamar: Agent tool com `model`; `schematize-overdev delegar --papel <p> --brief-stdin --json` (rc 3 = indisponível → `proximo`); sem overdev: `codex exec -m gpt-5.6-terra -s workspace-write --json -C <dir> "<brief>"`.
- **Release automatizado**: `.github/workflows/release.yml` (tag `v*` -> guarda `tag == v$(cat VERSION)` -> `scripts/build-zip.sh` -> `gh release create` com `skill-engineering.zip`; actions pinadas por SHA) e `scripts/build-zip.sh` (zip determinístico, topo `schematize-engineering/`, sem `.git`/`.github`/`versions`/`install.sh`/`README.md`).

## [0.26.0] — 2026-10-14
Saneamento de coerência (vistoria de 2026-10-14): o texto do overdev contradizia o hook, havia hash de senha e rol de linguagens com regras divergentes entre arquivos, e o `SKILL.md` repetia ~300 palavras por piso que já moram nas references.

### Corrigido
- **`references/overdev.md` §3/§4/§4.1/§6 e `eng-overdev.md`**: `- [~]` **conta como aberto** (é o que `overdev-stop.sh` faz); sobrando só `[H ]`/`[~]` sem caminho, a saída é `.schematize/overdev/BLOCKED`. Fase 0 passa a listar **cinco** artefatos (0.5 briefing), igual à `schematize-overdev-context`.
- **Hash de senha** (`SKILL.md`, `seguranca.md`, `anti-padroes.md`, `assets/CLAUDE.md`): argon2id para senha nova; bcrypt/PBKDF2 só legado com rehash — coerente com `iam.md`.
- **PHP** (`arquitetura.md` §3.2): migra por funcionalidade quando tocado (`linguagens.md` §2), sem "migração sumária".
- **Referências**: "pisos §6" (§6 é Complexidade) apontam para `padroes-codigo.md`; ADR-0005/0006 trocados pela regra; allowlist do root alinhada ao `docs-gate`; handoff `AAAA-MM-DD-<slug>-context.md` (convenção do archive); comandos `check-diff.sh`/`build-index.mjs` com o caminho instalado.
- **CI** (`assets/ci`): `trivy-action@master` pinado por SHA (v0.36.0) e gitleaks por SHA (v2.3.9).

### Adicionado
- **`linguagens.md`**: coluna "Prefixo de comando" no rol; **§2.2 "Sancionadas fora do rol de backend"** (C/C++, Swift/Kotlin/Dart, Shell/Python); regra de desempate única, sem "padrão da casa".
- **`/schematize-help`** reescrito: catálogo das 31 skills agrupado, lista viva via `ls ~/.claude/skills`.
- `SKILL.md`: `/eng-load` e `/eng-claude` na tabela de comandos.

### Alterado
- **`SKILL.md`**: pisos reduzidos a 1–3 linhas com ponteiro à reference (a regra mora lá; nenhuma removida); descrição ≤ 350 caracteres; irmãs apontam para `/schematize-help`; citações a "item 48/49" viram §37 por título.
- **Description** reduzida (~270 chars) para caber no orçamento de listagem (soma das 31 skills ≤ 8500; o Claude Code corta a listagem acima disso).
- **CI:** actions de terceiros pinadas por SHA completo com comentário `# vX.Y.Z` (mesma major em uso; supply chain), mesmo SHA em todas as skills.
- Fontes canônicas dos herdados parametrizados em `assets/herdados/` (`precedencia`, `fluxo-ambientes`, `deploy-destrutivo`, `efeito-externo`, `iam-desenho`, `arquivos/contexto-claude-code.md`) e manifesto `tools/herdados-arquivos.json` (catálogo); `references/contexto-claude-code.md` agora é gerado do template. Step-up (senha + Email OTP = 2FA baseline) vira regra comum do IAM das skills de backend.

## [0.25.0] — 2026-09-30
Ajuste de aplicabilidade: o checkpoint em MD antes de toda onda era pesado demais para tarefas pequenas e vinha sendo pulado na prática (2 rodadas de 6 e 2 agents); regra que não se cumpre vira ruído. Também: a descrição do frontmatter estava no teto de 1024 e enumerava pisos em vez de gatilhos; e os papéis do overdev eram só texto, sem enforcement.

### Adicionado
- **`assets/herdados/orquestracao.md`** — fonte única do piso de orquestração herdado pelas 19 derivadas (variantes `longo`/`curto`/`bullet`), sincronizada por `tools/sync-herdados.mjs` do catálogo (checado no CI). Mudar a regra agora é editar este arquivo e rodar o sync.
- **`references/overdev.md` §3 — "Guard de papéis (a implementar no motor `schematize`)"**: especificação (marcada PENDENTE no CLI) de hook `PreToolUse` que bloqueia `Edit`/`Write`/`NotebookEdit` do agent principal em run ativo (exceção: `.schematize/overdev/*` e archive), hook `SubagentStop`, e taxa de escalada `[sonnet]`/`[opus]` no `schematize overdev status`. Ponteiro em **`eng-overdev.md`**.

### Alterado
- **`SKILL.md`**: descrição reescrita (≤ 850 caracteres), focada em gatilhos e escopo; pisos reduzidos a uma frase.
- **`references/orquestracao.md` §7** e **`eng-orchestrate.md`**: checkpoint em MD **proporcional** — obrigatório com ≥ 5 unidades, OU > 15 min estimados, OU qualquer overdev, OU publicação/efeito irreversível no meio; abaixo, tabela de status no relato final e regra de retomada não se aplica.

### Mantido (piso inalterado)
- Orquestrador não desenvolve; sonnet default, opus só após escada; fan-out 8/onda, teto 25; sem frota ociosa; tempo do usuário > tokens; pisos de segurança/archive/efeito externo.

## [0.24.0] — 2026-09-30
Regra nova (pedido do dono): agents idle poluem a tela e seguram recurso — o orquestrador não mantém frota ociosa; idle com pendência volta a trabalhar, dependente de outro agent é morto e enfileirado com gatilho, concluído é morto.

### Adicionado
- **`references/orquestracao.md` §9.6 — "Sem frota ociosa (ciclo de vida do subagent)"** (varredura de ociosos em 3 casos); §7 ganha o status `BLOQUEADA (depende de X)` e a varredura a cada onda que fecha.
- **`references/overdev.md`** §2: varredura de ociosos a cada item fechado.
- **`assets/commands/eng-orchestrate.md`** e **`eng-overdev.md`**: linha da varredura.
- **`assets/CLAUDE.md` piso 19** e bullet correspondente no **`SKILL.md`**: frase-resumo "Sem frota ociosa".

### Mantido (piso inalterado)
- Tempo do usuário > tokens; fan-out 8 por onda / teto 25; checkpoint em MD; escada sonnet→opus; orquestrador não desenvolve. A §9.6 só governa o ciclo de vida dos agents, não *quando* paralelizar.

## [0.23.0] — 2026-09-30
Regra nova (pedido do dono, por **custo**): o orquestrador em modelo padrão **não desenvolve**; ação onerosa vira micro-tasks baratas; **Sonnet é o default** dos subagents e **Opus só após falha**.

### Adicionado
- **`references/orquestracao.md` §9 — "Papéis e escada de modelo (custo)"** (9.1 papéis, 9.2 ação onerosa → micro-funções, 9.3 escada sonnet→opus, 9.4 supervisão e revisão, 9.5 relação com tempo > tokens); blockquote inicial, §4.5, §4.6, §7 (tabela de status ganha colunas **modelo** e **rodadas de correção**) e "Regra de bolso" ajustados.
- **`references/overdev.md`** §0 (item 0.3/0.4 dimensionado como micro-task de Sonnet, tag `[sonnet]`/`[opus: <motivo>]`), §2 (cada item por subagent; principal escreve brief, revisa, pede correção) e §4 (escalar para Opus não é pergunta; esgotou Opus → `park`).
- **`assets/commands/eng-overdev.md`** (passos 0.3/0.4 e "Entre no laço") e **`eng-orchestrate.md`** (executor/modelo por unidade, escada de correção, principal só revisa).
- **`assets/CLAUDE.md` piso 19** — *Orquestrador não desenvolve; subagent barato executa*; piso 13 remete a ele.
- **`SKILL.md`**: bullet nos pisos, linhas de `/eng-orchestrate` e de `orquestracao.md`, `description`.

### Mantido (piso inalterado)
- **Tempo do usuário > tokens** continua; fan-out **8 por onda / teto 25**; **checkpoint em MD** à prova de crash. A §9 escolhe *quem executa* (o mais barato que resolve); não muda *quando paralelizar*.

## [0.22.0] — 2026-08-21
Saneamento do catálogo conforme a vistoria de 2026-08-21.

### Adicionado
- **`references/iam.md` §5.1 — "As três regras do motor que ninguém escreve"**: **outbox transacional** na escrita de tupla ReBAC (com os dois desastres simétricos nomeados: o convite que existe no banco e não no motor, e a remoção que saiu do banco e **ficou** no motor — privilégio que sobrevive à revogação), **PDP fail-closed** (motor fora do ar = deny; é o que separa indisponibilidade de brecha) e **denylist de `jti` como consulta obrigatória** em todo caminho que aceita token — *um só caminho que pula anula o logout inteiro, e é sempre o que ninguém lembrou: o WebSocket, o job*.
- **§6 — refresh opaco, CSPRNG, hasheado no store**, com comparação em tempo constante; **§9 — comparação em tempo constante na negação deceptiva** (*se ela responde mais rápido porque pulou a verificação, o tempo entrega o acerto e a técnica vira o oráculo que existe para negar*); **CSPRNG obrigatório** como transversal; e ***"framework de auth pronto ≠ IAM da casa"*** antes da §7.
- **`references/linguagens.md` §2.1 — Python**: sancionado como **ferramenta** (dados/ML, automação, ferramental) e **VETADO para API/serviço de produto novo**, exatamente como Node, com a forma da exceção (servir modelo atrás de um serviço do rol).

### Mudado
- `assets/hooks/overdev-stop.sh` — conta as **três classes** do checklist, lê `state.json` como canônico (`state` KEY=VALUE por compat) e **falha ruidosamente** quando há CHECKLIST sem estado. Ganhou `# strict-ok:` explicando por que ele **não pode** ter `set -e`: abortar vira "hook não decidiu", que o harness trata como **permitir a parada** — ou seja, desligaria a trava do overdev em silêncio.
- `references/arquitetura.md` §6 passou a dizer que **`§6` é o apelido de "pisos de código"** nos ~9 lugares que o citam, e que manter o apelido é deliberado.

## [0.21.0] — 2026-08-20
Piso novo (travado pelo Lucas, com ADR): efeito externo NUNCA sai de não-produção. Origem: um laço de teste disparou **>5.000 e-mails reais** para endereços sintéticos — hard bounce/spam trap em massa, reputação de IP e domínio queimada, custo real, utilidade zero. ADR-0004 no archive.
### Adicionado
- **`references/efeitos-externos.md` (novo, canônico):** efeito externo (e-mail, SMS/voz, push, webhook de terceiro, cobrança) **não acontece de verdade fora de `prd`** — por construção, não por lembrança. Cobre: o **domínio de teste em ROTA NULA** (`test.<domain>` com **null MX (RFC 7505) + SPF `-all` + DMARC `p=reject`**; TLDs reservados RFC 2606/6761 como alternativa) e a tabela do que é VETADO como destinatário (caixa real, domínio de terceiro/cliente, e-mail de pessoa real **inclusive o próprio**, domínio de produção); **sink por default com guard fail-closed DENTRO do provider** (destinatário externo + `env != prd` → **erro**, config ausente ⇒ assume não-prd) + pseudocódigo do guard; **cap por execução** (`MAIL_MAX_PER_RUN`) com circuit breaker que aborta; as **4 camadas** de defesa (DNS · aplicação · rede/segredo · provedor); extensão a SMS/push/webhook/PSP/tool de agente; a **exceção com as 5 condições** (ADR + allowlist ≤5 + cap + janela + subdomínio separado); **runbook de contenção** pós-incidente (parar, revogar chave, medir bounce/complaint, warm-up); e a DoD do tema.
- **Piso inegociável "Efeito externo NUNCA sai de não-produção" (SKILL.md)** + linha no mapa de references.
- **Anti-padrão espelho §37 item 49 (`references/anti-padroes.md`), nova subseção "Efeitos externos fora de produção":** disparar efeito externo real a partir de não-produção — endereço de caixa real em fixture/seed, provedor real por default em dev/hml, chave de prd no seed de não-prd, envio sem teto por execução.
- **Item BLOQUEANTE na Definition of Done (§35, `references/entrega.md`):** nenhum efeito externo real fora de `prd` (provider sink, guard com teste que vê a recusa, cap, domínio em rota nula).
- **`scripts/check-external-effects.sh` (novo gate determinístico):** trava se achar endereço de caixa real (`@gmail.com` e ~20 outros) em test/seed/fixture/persona, credencial de provedor de envio não-sandbox em `.env` de ambiente não-produtivo, envio sem cap declarado, ou (com `TEST_MAIL_DOMAIN` + `dig`) domínio de teste **sem null MX**/sem SPF `-all`. Plugado no `assets/ci/github-actions-ci.yml`.
- **`assets/CLAUDE.md`: piso 18** (sempre-on na raiz do repo) + o item na DoD do arquivo.
### Mudado
- **`references/iam.md` §3:** "Email OTP always-on" ganha o contrapeso explícito — **ligado ≠ entregando para fora**: em `prd` entrega de verdade (sem chave, o serviço recusa subir); **fora de `prd` o provider default é o SINK** e o guard recusa destinatário externo — o fluxo de OTP é exercido lendo o código do sink. É o fluxo que mais amplifica envio (1 conta de teste = 1 e-mail).
- **`references/iam.md`** (checklist da DoD) e **`references/iam-checklist.md`** (F0): item novo de sink/guard/cap com prova (`dig MX` devolvendo `0 .`, teste que espera a recusa em `env=hml`, seed sem chave de produção).
- **`description` (frontmatter):** cita o novo piso junto dos demais.

## [0.20.1] — 2026-08-19
### Adicionado
- Integração com a GUI via `gui.json` (botão Q.A. na aba do projeto).

## [0.20.0] — 2026-08-18
Piso novo (travado pelo Lucas): UX de massa — prever o usuário leigo ("prever macacos").
### Adicionado
- **Piso inegociável "UX de massa — prever o usuário leigo" (SKILL.md):** software pro público não pode quebrar nem CULPAR o usuário por como ele invocou/usou. Todo caminho que um usuário ingênuo pode tomar (rodar como root/su/sudo, PATH mínimo, sem toolchain, ordem "errada", fechar no meio, dir com nome inesperado) é PREVISTO e tratado com graça — o software **se adapta/conserta sozinho**, não avisa "você fez errado". Edge case que um leigo atinge = **BUG do software, não erro do usuário** (produto de massa: usuário insatisfeito = menos receita). Regras: (a) nunca exija saber de internals (rustup/PATH/sudo/root/git); (b) detecte e faça o certo automaticamente (root → descobre o usuário real e instala pra ele, nunca em `/root`); (c) precisa de privilégio → eleva sozinho; (d) falta toolchain/dependência → instala/configura; (e) erro acionável e sem culpa ("faço X pra você" > "você fez errado"). Vale pra TODO software user-facing da casa (instaladores, CLIs, GUIs, onboarding).
- **Anti-padrão espelho §37 item 48 (`references/anti-padroes.md`), nova subseção "UX de massa":** culpar o usuário / exigir que ele saiba de internals / quebrar por invocação não-prevista (ex.: rodar como root e instalar em `/root`, PATH mínimo, toolchain ausente, dir/ordem/fechamento inesperado).
### Mudado
- **`description` (frontmatter do SKILL.md)** cita o novo piso de UX de massa junto dos demais pisos.

## [0.19.0] — 2026-08-18
Correção da §28: o diretório do archive passa a ter o NOME DO PROJETO.
### Mudado
- **§28 (archive) — o dir do archive ganha o nome do projeto:** de `<projeto>/_archive/` para **`<projeto>/<projeto>_archive/`** — continua DENTRO do projeto, mas o diretório do archive agora tem o NOME DO PROJETO (`<projeto>_archive`), não mais um `_archive/` nu. Motivo: sem o nome, quem não separa por team acabaria misturando os archives de projetos diferentes. Propagado a todo o corpo (SKILL/references/commands/assets/CI).
- **§28.0 — nota nova:** o `<projeto>` é o NOME DO PROJETO = o prefixo comum dos microserviços (convenção `<projeto>_<microservice>`), garantindo que o archive nunca se confunde com o de outro projeto.

## [0.18.0] — 2026-08-18
Archive muda de convenção: sai de irmão do projeto e vira parte de DENTRO do projeto, como repo git próprio e privado.
### Mudado
- **§28 (archive) — nova localização:** o archive deixa de ser `<projeto>_archive/` (irmão do projeto, um nível acima) e passa a ser **`<projeto>/_archive/`** — DENTRO do diretório do projeto, **irmão dos diretórios dos microserviços**. Tudo fica dentro do projeto, sempre. Propagado a todo o corpo (SKILL/references/commands/assets/scripts/CI).
- **§28 — nova natureza:** o `_archive/` agora é um **repositório git PRÓPRIO, PRIVADO e obrigatório** (como os repos dos microserviços), cuja função é a **evolução do projeto DOCUMENTADA** — `git init` + remote privado dedicado + versionado por marco (commit a cada decisão/plano/handoff/fechamento; o `git log` conta a evolução). Fica explícito: `_archive/` = durável, NÃO gitignored; `.schematize/` = operacional volátil, gitignored.
- §28.0 referencia a skill **schematize-archive** (`/archive-init`, `/archive-todos`) como a execução detalhada da disciplina.

## [0.17.0] — 2026-08-18
IAM restritivo — o "só está pronto quando está pronto" + correção da contradição do muro pré-login.
### Adicionado
- **`references/iam-checklist.md`**: checklist EXAUSTIVO de IAM por fase (F0→F6), cada item com "como provar"; fases são portões; conclusão só com todo item provado + `GATE F6` (pentest) verde.
### Mudado
- **`/eng-iam` virou RESTRITIVO**: deriva o checklist exaustivo em `.schematize/overdev/CHECKLIST.md` e roda sob o overdev (Stop-hook trava com item aberto); gate do pentest é condição de conclusão, não sugestão.
- **Corrigida a contradição normativa GRAVE**: o `/eng-iam` mandava "2º fator forte obrigatório antes do acesso pleno" e "força 2º fator no 1º login" — o exato **muro pré-login / deadlock de bootstrap** que o `iam.md` VETA. Agora: senha+Email OTP = 2FA baseline; fator forte é nudge + step-up just-in-time, nunca muro. (mesma correção propagada às skills de linguagem).
- `references/iam.md`: o checklist-resumo aponta pro exaustivo `iam-checklist.md`.

## [0.16.0] — 2026-08-18
Layout operacional do projeto muda de `.overdev/` para **`.schematize/`** (com `overdev/` e `grafos/`) e a §39 vira um **grafo GLOBAL de dois níveis**.

### Mudado
- **Migração `.overdev/` → `.schematize/overdev/`** em todo texto normativo (SKILL/references/commands/assets): o **marcador canônico do projeto** passa a ser a pasta **`.schematize/`**; o **`.overdev/` legado ainda é aceito por compat** — o motor Rust lê ambos e **auto-migra** no `overdev start`. O espelho durável no archive segue `<projeto>_archive/overdev/` (inalterado). Atingiu `references/{overdev,auditoria}.md`, `assets/commands/{eng-overdev,eng-audit}.md`, `assets/settings.claude.example.json`.
- **Hook `assets/hooks/overdev-stop.sh` lê ambos os layouts:** resolve `SD=.schematize/overdev` se existir, senão `.overdev` legado, senão `.schematize/overdev`; todo o resto deriva de `$SD` (mensagens `$SD/DONE`/`$SD/BLOCKED` inclusive).
- **§39 (`references/entrega.md`) reescrita — grafo GLOBAL de dois níveis**, vivo em **`.schematize/grafos/`** (o que o app lê/desenha), espelhado em `<projeto>_archive/index/`:
  - **`GRAFO_GLOBAL.md`** — global da aplicação: cada microserviço é um **nó** com suas **funções principais** (entrypoints/APIs públicas); arestas = **contratos** entre serviços (saída de A pra B); enumera **todos** os serviços (num serviço único, ele + arestas de fronteira).
  - **`<servico>.md`** (um por serviço) — grafo **detalhado interno**: funções como nós, chamadas intra-serviço como arestas, cada nó com `arquivo:linha`.
  - **Auto-referência de fronteira:** função de A que produz saída pra B marca o nó `-> <servico-B>` no grafo local (a aresta que sai pro global).
  - **Formato inegociável (parser do app):** arestas SEMPRE em ASCII `A -> B (contrato)`, **nunca** a seta unicode `→`; funções em tabela pipe `nome | o quê | ... | arquivo:linha`, cada nó com descrição de uma linha.
- **`assets/commands/eng-index.md`** alinhado ao modelo (gera `GRAFO_GLOBAL.md` + `<servico>.md` em `.schematize/grafos/`, ASCII, espelho no archive).
- **Templates coerentes:** novo `assets/GRAFO_GLOBAL.md`; `assets/{INDEX_GLOBAL,INDEX_FUNCTIONS,MAPA}.md` marcados como **espelho** do vivo em `.schematize/grafos/` (o `MAPA.md` é o resumo), arestas em ASCII.

## [0.15.1] — 2026-08-18

### Removido (extraído para `schematize-qa`)
- **Testes / Q.A. viraram skill dedicada `schematize-qa`.** As references `testes.md` (§22.1–§22.3) e
  `testes-execucao.md` (§22.4–§23: padrão de script, seeds, CI, Q.A. plan-first §22.9, Makefile de
  teste) e o comando **`/eng-qa`** saíram desta skill. No lugar: `references/testes.md` virou um
  **ponteiro curto** pra `schematize-qa` e a engenharia mantém só o **piso mínimo** ("a DoD exige
  testes verdes" — §35; "teste nunca silenciado" — §37; "refactor com rede de testes ANTES").
- **Andaime de teste movido** (`scripts/lib.sh`, `test-skeleton.sh`, `smoke-selfcheck.sh`,
  `simulated/run.py`) → `schematize-qa/scripts/`.
- **Cross-refs repontadas:** teste/cobertura/smoke/`simulated` → `schematize-qa`; hardening/pentest/
  injeção/coerção/cross-tenant (antigas §22.3/§22.8) → `schematize-pentest`. Atingiu `SKILL.md`,
  `assets/CLAUDE.md`, `references/{entrega,ops,refactor,anti-padroes,scan,orquestracao,linguagens,
  seguranca,arquitetura}.md`, `assets/{PR_TEMPLATE.md,ci/github-actions-ci.yml}`, e os comandos
  `eng-help`/`eng-load`/`eng-ops`/`schematize-help`.

## [0.15.0] — 2026-08-15
Base mais **agnóstica de linguagem** — de "backend só Go/Rust" para um **ROL SANCIONADO + guia de fit**, abrindo espaço para as skills irmãs de Elixir/C#/Zig/Ruby.

### Mudado (política)
- **`references/linguagens.md` (novo)** — a escolha de linguagem vira reference própria da base agnóstica: **rol sancionado = Go, Rust, Elixir, C#, Zig, Ruby** (cada uma com skill irmã), escolhido por um **guia de fit** por problema e registrado em **ADR**; **Node-backend e PHP em saída** (não recebem serviço novo; legado migra por funcionalidade do módulo pra uma linguagem do rol). Frontend = Node (só frontend). **O piso de engenharia é o mesmo em toda linguagem** — ela muda o "como", não o "o quê".
- **`SKILL.md`, `references/arquitetura.md` §3/§3.1/§3.2, `references/anti-padroes.md` #31, `assets/CLAUDE.md`** reescritos: "backend novo só em Go ou Rust" → "backend novo em linguagem do rol, por fit + ADR". A saída de Node-backend/PHP e a regra dos 30%/50% permanecem, agora apontando pra "uma linguagem do rol". `/eng-load` carrega `linguagens.md`.

### Contexto
Primeira leva da expansão multi-linguagem: as skills `schematize-elixir`, `schematize-csharp`, `schematize-zig` e `schematize-ruby` especializam esta base agnóstica (como go/rust/node já faziam), cada uma posicionada no guia de fit.

## [0.14.0] — 2026-08-15
Quatro disciplinas de fluxo — **scan de problemas**, **planejamento extensivo**, **refactor disciplinado** e **auditoria de histórico** — que formam o loop *achar → planejar → consertar → conferir*.

### Adicionado
- **`references/scan.md` + `/eng-scan`** — varredura **ampla** da base inteira (não é o gate do diff nem o pentest): correção, anti-padrões §37, pisos §6, duplicação/código morto, buracos de teste (guarda que não guarda, teste não coletado), concorrência/recurso (race, cancelamento, N+1, leak), dados/API, superfície de supply chain, dívida (TODO/FIXME) e deriva de índice §39. Exaustivo por inventário, **fan-out** de subagents, **suspeito≠achado** (verifica antes de reportar), saída machine-readable no archive com `arquivo:linha`+severidade+piso+conserto.
- **`references/planejamento.md` + `/eng-plan`** — **planejamento extensivo** plan-first: entender (decisões acordadas + código/grafo do índice) → escopo (in/out + sucesso mensurável) → **spikes** das incógnitas → decompor no grafo (nó+prova+deps, ordem topológica, caminho crítico) → risco+rollback → **ADR** das decisões estruturais → plano de paralelização → fases+DoD. Gera o plano no archive, deriva o checklist e **pede aprovação** antes de executar.
- **`references/refactor.md` + `/eng-refactor`** — **refactor disciplinado**: muda a forma **sem mudar o comportamento observável**, com **rede de testes ANTES** (red-first/characterization — a guarda vista no vermelho), **passos pequenos e reversíveis** (verde entre cada), **escopo-diff** (regra do escoteiro), catálogo de refactors seguros (extract/rename/inline/DTO/polimorfismo/inversão de dependência/dedupe/strangler-fig). Gate: mesma suíte verde + contrato idêntico + índice/MAPA atualizado, sem anti-padrão novo.
- **`references/auditoria.md` + `/eng-audit`** — **auditoria de histórico**: enumera **todos** os checklists/promessas do projeto (overdev `CHECKLIST.md`/`OBJETIVO.md`/`premature-stops.log`/`PERGUNTAS`, Q.A., handoffs, planos, ADRs `proposed`) e verifica se cada item foi **sanado** — acha **órfãos RED** (aberto nunca fechado, on-hold sem resposta, ADR órfão) e faz spot-check dos `- [x]` (feito sem prova **volta a aberto**). Gera checklist de saneamento e **trava se sobrar** órfão. Fecha o loop do overdev/scan.
- **Wiring:** SKILL.md (tabela de comandos + mapa de references + descrição), `/eng-help`, `/eng-load`, `/schematize-help` e README atualizados.

## [0.13.0] — 2026-08-15
OVERDEV com **Fase 0 — Fundação**: colher decisões acordadas → carregar o grafo do index → planejamento PESADO → só então tickar. (1ª leva; painel/grafo Obsidian no CLI vêm em seguida.)

### Adicionado
- **`references/overdev.md` §0 — Fase 0 (Fundação), obrigatória ANTES do laço:** (0.1) **colher as decisões ACORDADAS no contexto atual** → `.overdev/DECISOES.md` (ADR-lite: decisão · motivo · alternativa descartada · origem), travando o que já foi fechado; (0.2) **carregar o grafo do index** (`/eng-index` §39: MAPA + adjacência `A -> B`) e ancorar cada item a nó/`arquivo:linha`+arestas; (0.3) **planejamento PESADO** → `.overdev/PLAN.md` (escopo, decomposição verificável com nó+prova+dependências, ordem topológica, paralelismo, mapa decisão→item, riscos, DoD); (0.4) **derivar o CHECKLIST do plano** (exaustivo por contagem). O laço (§2) só começa com a Fase 0 fechada.
- **`references/overdev.md` §8 — contexto da app + painel/grafo (fora do CLI/VSCode):** o `schematize` guarda o contexto e o expõe num **painel HTML no browser** + **tela de grafos estilo Obsidian** (nós linkados a `arquivo:linha`) + **export Obsidian** do index (`[[wikilinks]]`), lendo `.overdev/*` e o grafo do index. Painel é **auxiliar read-mostly** — o juiz do "terminou" segue sendo checklist+gate. (Comandos `schematize panel`/`graph obsidian` em construção — próxima leva.)
- **`/eng-overdev`** front-carrega a Fase 0 (0.1–0.4) no fluxo de início, antes de ativar o run e entrar no laço; descrição atualizada.

## [0.12.0] — 2026-08-15
Correção de desenho no IAM — **senha + Email OTP já é 2FA baseline** (fim do muro pré-login) + **risk engine adaptativo robusto**.

### Mudado (correção de piso)
- **`references/iam.md` §3/§4/§7 + roadmap + checklist; anti-padrão #47 reescrito:** senha + Email OTP passa a **contar como 2FA baseline** desde o cadastro — a conta nasce segura e **o acesso NUNCA é bloqueado por falta de fator forte**. Fator forte (app/passkey) vira **nudge + just-in-time** (step-up na 1ª ação sensível), nunca muro pré-login — resolve o **círculo infinito na raiz** (não só com a "rampa" da v0.11.0). O que falta **degrada o sensível**, não bloqueia o baseline.

### Adicionado
- **Autenticação adaptativa por risco (robusta)** (`references/iam.md` §9): log de sessões/tentativas + **score de risco** (IP/ASN, device novo, geovelocidade, velocity, honeypot); **escalonamento 2FA→3FA** sob risco (senha → email → app/chave); **negação deceptiva/tarpit** (falso negativo sob suspeita — resposta idêntica ao erro real, estado "próxima passa" curto e escopado, soma-se ao 3FA, nunca trava o legítimo); **honeypot** (isca → sinal forte de hostil); notificação de login suspeito com "não fui eu".

## [0.11.0] — 2026-08-15
Lições de um incidente real de auth/onboarding — **alcançabilidade de estado** e **guarda provada no vermelho**.

### Adicionado
- **Alcançabilidade / anti-deadlock de bootstrap** (`references/iam.md` §4 + checklist; anti-padrão #47 em `references/anti-padroes.md`): toda exigência obrigatória (enrolar 2º fator, verificar) tem que ter **rampa self-service alcançável a partir do estado zero** — o fallback always-on (Email OTP) dá a sessão de baixo AAL para enrolar o fator forte; a saída **nunca** exige o que falta (link para página que pede sessão a quem não tem) nem terceiriza o que é do dono (admin enrolar o autenticador alheio); **prova por estado** (nenhum estado de conta sem transição de saída). Origem: N contas presas sem TOTP porque a única porta pedia o que elas não tinham.
- **Guarda provada no vermelho + test discovery** (`references/testes.md` §22; anti-padrão #20a): todo teste/guarda tem que ser **visto FALHAR** quando o invariante quebra (red-first) — verde que nunca reprovou o caso ruim (a asserção casa com o vizinho/array/regex errado) não guarda; o runner tem que **COLETAR** o teste (globs de `include` cobrem `.test.tsx`/`_test.go`), suíte que rodou 0 testes novos é falso-verde.

## [0.10.0] — 2026-07-11
Overdev pelo CLI `schematize` (Rust) — parkear pergunta em vez de travar; on-hold; veto a AskUserQuestion.

### Alterado
- **Motor do overdev agora é o binário `schematize` (Rust, repo `schematizeme/schematize-cli`)**, não mais o `.sh` (que fica só como fallback Stop-only). `schematize overdev enable` registra **dois** hooks: **Stop** (`overdev check` — não para até o checklist fechar; item on-hold não bloqueia) e **PreToolUse** matcher `AskUserQuestion` (`overdev guard` — **veta o pool bloqueante de perguntas**).
- **Regra central nova:** em overdev, **VETADO parar pra perguntar**. Topou dúvida → **parkeia** (`schematize overdev park "<item>" "<pergunta>"`: registra em `./PERGUNTAS-OVERDEV.txt` na base do projeto **e** marca o item como `- [~]` on-hold) e **segue**. On-hold não bloqueia o fim do run; as perguntas ficam pro usuário ler quando voltar. Preferir default razoável documentado a perguntar.
- **Terceiro estado de checklist `- [~]` (on-hold)** além de `- [ ]`/`- [x]`. Corrige a causa do bug reportado ("na instalação não constava os .sh / overdev não funcionava"): o `install.sh` copiava o hook mas não o ativava no settings — agora `schematize overdev enable` faz o wiring de forma robusta.
- `references/overdev.md` §4/§6/§7 e `/eng-overdev` reescritos pro modelo CLI + parkear.

## [0.9.1] — 2026-07-11
Fix no hook do OVERDEV.

### Corrigido
- `assets/hooks/overdev-stop.sh`: contagem de itens abertos quebrava quando o checklist estava 100% fechado (`grep -c` imprime 0 e sai 1 → `|| echo 0` gerava `"0\n0"` e erro de sintaxe, impedindo a parada legítima). Agora conta certo e libera a parada com o checklist completo (e ainda bloqueia se o `gate.sh` falhar). Coberto por smoke-test dos 4 cenários (inerte / item aberto / tudo fechado / gate falho).

## [0.9.0] — 2026-07-11
Modo OVERDEV — desenvolvimento contínuo até o checklist fechar (anti-parada-prematura).

### Adicionado
- **`references/overdev.md` + comando `/eng-overdev` + hook `assets/hooks/overdev-stop.sh`:** modo opt-in que resolve o agente que **para cedo demais** ("entreguei uma micro-função e disse que terminei"). Força um **checklist exaustivo e verificável** (`.overdev/CHECKLIST.md`, espelhado em `<projeto>_archive/overdev/OBJETIVO.md`) e um **Stop hook que REJEITA a parada** enquanto houver `- [ ]` aberto ou o `.overdev/gate.sh` falhar — o agente só fala com o usuário quando tudo está `- [x]` e verificado. Tentativa de parar prematura é registrada em `premature-stops.log` (a "punição") e o agente é forçado a continuar. **Paradas legítimas:** concluído (cria `.overdev/DONE`), bloqueio real que exige o usuário (`.overdev/BLOCKED` com motivo+pergunta), teto de budget (`max_iters`, default 200, guardrail anti-loop) ou thrashing. **Opt-in e inerte** fora de um run (o hook sai em microssegundos sem `.overdev/state` ativo); ativação por registro `Stop` no `settings.json` (`assets/settings.claude.example.json` atualizado). Não burla pisos: item só fecha com prova. Escopo: schematize-engineering.
- `SKILL.md` (comando + reference), `/eng-help`, `/eng-load` atualizados.

## [0.8.0] — 2026-07-11
IAM por desenho — identidade + autorização robustas, auth como app separada.

### Adicionado
- **`references/iam.md`** — piso de IAM da casa: **auth é app SEPARADA** (`auth.<domain>`, serviço + front próprios, isolados; nunca monolith; apps delegam por OIDC/OAuth2.1 + PKCE). **ID interno imutável — email/telefone nunca é ID** (N emails por usuário, incentivado; SSO com recuperação local forçada; nudge de email secundário com detecção de provedor + tooltip). **≥2 fatores sempre** (AAL/NIST 800-63B): **passkey/WebAuthn no núcleo**, TOTP/push, **email OTP Resend always-on inclusive HML**, **Twilio** p/ telefone (providers plugáveis); senha por padrão (argon2id+HIBP) mas opcional no seletor; invariante de troca "fator Y≠X no maior AAL"; **recuperação ≥ força do login**. **Multi-tenant RBAC/ABAC granular via ReBAC** (OpenFGA/SpiceDB): deny-default, PDP/PEP, enforcement server-side, token fino, decisão auditada. **Multi-dispositivo** + view de remover; **sessão 7d/90d** (fim do "15 min e é chutado"); **logout irreversível**. **Migração de auth legado = prioridade 0** (strangler-fig). Rotina agressiva de testes cross-tenant/priv-esc (schematize-pentest).
- **Comando `/eng-iam`** (plan-first): força/audita/scaffolda o IAM num projeto (bootstrap) ou porta um auth legado (migrate).
- **Piso 17** no `CLAUDE.md`; bullet + linha na tabela de references do `SKILL.md`; anti-padrões **43–46** (auth monolith; email como ID / 1 fator; authz hand-rolled/no cliente; logout que só apaga cookie); `/eng-load` carrega `iam.md`; `/eng-help` lista `/eng-iam`.

## [0.7.0] — 2026-07-11
Limite de arquivo em camadas — teto de 750 (≤500 úteis + ~250 comentário) + flag em >300 úteis.

### Alterado
- **`references/padroes-codigo.md` §1/§2:** o limite rígido de **300 linhas/arquivo** vira regra **em camadas**. **Teto DURO: 750 linhas** (das quais **~250 reservadas a comentário/doc** e **até ~500 de código útil**) — acima bloqueia. **FLAG (não bloqueia, mas SEMPRE sinaliza) em > 300 linhas de código útil:** indício de que a função está **muito extensa** / **precisa de mais abstração** — registra como dívida e **revê quando as prioridades forem resolvidas**. **Observabilidade tem folga natural (~400 úteis).** Função com >300 úteis dispara o mesmo flag; "uma função por arquivo" mantida.
- **`scripts/check-diff.sh`:** o gate de tamanho passa a contar **código útil** (exclui comentário/branco): `total > 750` **bloqueia**, `útil > 500` **bloqueia**, `útil > 300` (ou `> 400` em arquivo de observabilidade) **flagueia** (`warn`, não trava).
- Propagado no piso do `CLAUDE.md`, `SKILL.md`, `references/entrega.md` (DoD), `references/arquitetura.md` (§6) e comandos `/eng-load` `/eng-help` `/eng-review`.

## [0.6.0] — 2026-07-06
Deploy destrutivo por seed + isolamento por usuário (control plane `<projeto>_ops`).

### Adicionado
- **`references/ops.md` §2 — layout, seed e redeploy destrutivo:** o ops provisiona em **`/<app>/`** clonando os repos dentro (`/<app>/<app>_<ctx>`); **`/<app>/.env` é o seeder global** (fonte única de config). **Todo redeploy é destrutivo na aplicação** — apaga a anterior e recria um clone zerado só com o seed (idempotente, sem drift). **"Destrutivo" é a app, nunca os dados:** banco/volumes preservados (migration reversível); `ops reset` de dados gated a dev/hml, nunca prd.
- **`references/ops.md` §3 — isolamento por usuário:** um **user Linux dedicado + systemd unit hardened por serviço** (`NoNewPrivileges`/`ProtectSystem`/`PrivateTmp`/…); blast radius mínimo (comprometer um serviço não alcança os outros nem o host). Tudo automatizado pelo ops.
- Piso **16** no `CLAUDE.md`; bullet no SKILL.md; anti-padrões **39–42** (patch in-place/redeploy fora do seed; config fora do seed/repos fora de `/<app>/`; apagar dados no destrutivo; serviços sem isolamento de user). `/eng-ops` audita layout/seed/isolamento.

### Corrigido
- `ops.md` §7: referência de comando normalizada para `/<slug>-ops` (era `/eng-ops` fixo, que ficava incorreto nas cópias das skills de linguagem).

## [0.5.0] — 2026-07-05
Control plane `<projeto>_ops`: fluxo de ambientes, ops como interface única, instalação paralela, independência invariante.

### Adicionado
- **`references/ops.md`**: (1) **fluxo de promoção fixo** `dev local → teste local → GitHub → hml → prd`, **nada direto no servidor** — editar código em hml/prd é VETADO (servidor imutável por edição manual; drift detection, filesystem read-only, break-glass auditado); (2) **ops é a interface única** — 100% de install/update/correção/config passa por comando do `<projeto>_ops`, que é autônomo/idempotente/completo (usuário provisiona o servidor do zero sem a IA); (3) **instalação sempre paralela** = `nproc`; (4) **independência é invariante** — falha no paralelo = serviços não independentes → corrigir é prioridade máxima; ops expõe a colisão, nunca serializa pra mascarar.
- **Comando `/eng-ops`** (plan-first): audita/scaffolda o ops, verifica fluxo de ambientes, paralelização e independência.
- Pisos **14 e 15** no `CLAUDE.md` sempre-on; pisos no SKILL.md; anti-padrões **35–38** (editar no servidor, pular pra hml/prd, operar fora do ops, instalar serial, serializar pra mascarar dependência); `operacao.md` §21 estendido; `/eng-load` carrega `ops.md`.

## [0.4.0] — 2026-07-05
Índice único de comandos entre skills.

### Adicionado
- **Comando `/schematize-help`**: o "help dos helps" — varre os comandos instalados (projeto + global) de **todas** as skills da casa (go/rust/web/node/eng/pentest), lê a `description:` de cada um e apresenta um índice agrupado por skill, com legenda do catálogo e como instalar skills faltantes. `/eng-help` passa a apontar pra ele.

## [0.3.0] — 2026-07-05
Permanência (MD como backup à prova de crash) e **todo MD gerado no archive, root limpo**.

### Adicionado
- **§28.0 (`references/operacao.md`): layout canônico do archive** — todo `.md` gerado (MAPA, índices, planos, relatórios, handoffs, checkpoints) mora em `<projeto>_archive/<área>/`, **NUNCA no root**. Subpastas: `index/`, `context/`, `orchestration/`, `pentest/`, `chat/`, `task/`. Root fica limpo (só código, config e MDs de projeto à mão).
- **Permanência da orquestração (`references/orquestracao.md` §7):** o MD de checkpoint é gravado **antes** de disparar a onda 1, com tabela de status por unidade; cada subagent grava o próprio resultado no archive; retomada por leitura do checkpoint (não recomeça do zero). Comando `/eng-orchestrate` atualizado.

### Corrigido
- **MAPA/índice saíam no root.** Agora `MAPA.md`, `INDEX_GLOBAL.md`, `INDEX_FUNCTIONS.md` vão para **`<projeto>_archive/index/`** (`padroes-codigo.md` §4, `assets/MAPA.md`, `/eng-index`, `build-index.mjs` (uso), `CLAUDE.md`, `SKILL.md`).

## [0.2.0] — 2026-07-04
Orquestração & paralelização como piso — **tempo do usuário acima de tokens**.

### Adicionado
- **`references/orquestracao.md`**: quando a tarefa se divide em ≥3 unidades independentes, decompor em mini-tasks e **paralelizar com subagents** em vez de serial; fan-out de **8 por onda** (teto global **25**); regra fan-out-vs-inline; independência (sem alvo de escrita compartilhado, sem ordem obrigatória); brief autossuficiente (agent começa frio); isolamento de escrita (worktree/partição); gather + verificação única pelo orquestrador; onde **não** paralelizar; plan-first.
- **Comando `/eng-orchestrate`**: planeja a decomposição/fan-out, fixa o contrato, mostra o plano e pede aprovação antes de disparar as ondas.
- Piso 13 no `CLAUDE.md` sempre-on e piso correspondente no SKILL.md; `/eng-load` e `/eng-help` atualizados.

## [0.1.0] — 2026-07-03
Primeira release — a **base comum de engenharia** da casa, agnóstica de linguagem, extraída do corpo normativo compartilhado entre `schematize-go`/`rust`/`web`/`node`.

### Adicionado
- Corpo normativo language-agnostic: arquitetura/DDD, estrutura de repositórios + `<projeto>_ops` + contenção no workspace, **padrões de código** (≤300 linhas, doc-comment com fluxo de dado, **MAPA+grafo+índice exaustivo por contagem**), segurança (segredo server-side, SQL parametrizado, authz), dados/eventos + independência de runtime, cadeia de suprimentos, observabilidade (LGTM+), operação/entrega/DoD/**archive** e anti-padrões (§37).
- Comandos `/eng-help`, `/eng-load`, `/eng-claude`, `/eng-index`, `/eng-review`, `/eng-qa`, `/eng-cc`, `/eng-handoff`; `CLAUDE.md` sempre-on.
- Referência ao **mapa de endpoints** (`schematize-pentest`) na superfície de entrada do índice.

> As skills de linguagem (`schematize-go`/`rust`/`web`/`node`) especializam esta base; use esta quando o projeto não é de uma linguagem específica.
