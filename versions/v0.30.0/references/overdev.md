# OVERDEV — desenvolvimento contínuo até o checklist fechar (à prova de parada prematura)

Modo de trabalho **opt-in** (comando `/eng-overdev`) para quando o agente **para cedo
demais** — entrega uma micro-função e diz "tá tudo pronto" com o checklist cheio de item
aberto. O overdev **força um checklist exaustivo e só deixa o agente falar com o usuário
quando o checklist estiver EFETIVAMENTE 100%** (verificado, não auto-declarado).

Roda **só quando você chama** `/eng-overdev`. O hook é **inerte** sem um overdev ativo.

## 0. Fase 0 — Fundação (ANTES do laço): decisões → grafo → plano pesado

> **PONTEIRO.** A Fase 0 foi **extraída** para a skill dedicada **`schematize-overdev-context`**
> (comando `/overdev-context-build`), que a executa passo a passo e produz os artefatos. Este §0
> ficou aqui como **contrato** — o que o laço EXIGE antes de começar —, não como manual. Manter os
> dois manuais era a Classe D da vistoria de 2026-08-21: doutrina que saiu de um lugar e não saiu
> do outro.

**Antes de tickar qualquer item**, o overdev **funda o trabalho**. Pular isto é a causa nº 1 de
plano raso, retrabalho e "reabrir o que já foi combinado". A Fase 0 é **obrigatória** e é a
**primeira coisa** que o run faz — o laço (§2) só começa quando ela fecha.

**O contrato da Fase 0 — os 5 artefatos, e o gate:**

| # | Artefato | O que tem de conter | Onde |
|---|---|---|---|
| 0.1 | `DECISOES.md` | as decisões **já acordadas** no contexto, em ADR-lite: *decisão · motivo · alternativa descartada · origem*. O que ficou ambíguo **não vira decisão**: vira `- [~]` on-hold | `.schematize/overdev/` + espelho no archive |
| 0.2 | grafo carregado | o **MAPA/índice §39** lido (`/eng-index`); cada item do plano aponta o(s) **nó** que toca e as **arestas** afetadas. Sem índice, **gerá-lo é o 1º item** | `<projeto>_archive/index/` |
| 0.3 | `PLAN.md` **pesado** | escopo (entra / **NÃO** entra), decomposição em itens **verificáveis** e do tamanho de **uma micro-task de executor barato** (nó do grafo + **prova** + dependências + risco + executor `[haiku]`/`[sonnet]`/`[codex]`/`[cursor]`/`[opus: <motivo>]`), ordem topológica, paralelismo (≥3 unidades independentes → `/eng-orchestrate`), riscos, DoD (§35) | `.schematize/overdev/` |
| 0.4 | `CHECKLIST.md` | **derivado do plano**, exaustivo por contagem, 1 item por linha, cada um com **como provar**, nas 3 classes `- [ ]` · `- [H ]` · `- [~]`. Itens **dimensionados como micro-task de executor barato** (§2 / `orquestracao.md` §9.2), cada um com a tag de executor `[sonnet]` (default código), `[haiku]` (mecânico), `[codex]` (visual/imagem/fallback), `[cursor]` ou `[opus: <motivo>]` | `.schematize/overdev/` |
| 0.5 | briefing | documento coeso que amarra objetivo + decisões + grafo + plano + checklist + riscos; é o que o overdev abre ao entrar no laço (`schematize-overdev-context` → `references/briefing.md`) | `<projeto>_archive/overdev/` |

**Gate da Fase 0 (linhas 0.1–0.5 da tabela):** só entra no laço (§2) com os cinco prontos. Começar a tickar sem a fundação é a
macaquice que a Fase 0 existe para matar.

**O passo a passo de como produzir cada um** — como varrer a sessão, como ancorar no grafo, como
derivar o checklist por contagem — está na **`schematize-overdev-context`**. Onde este §0 divergir
dela, **ela manda** no *como*; aqui manda o *o quê* (o gate acima).


## 1. O contrato: checklist é o "terminou"
- Nada de "acho que tá bom". O único critério de fim é **todos os itens do checklist
  fechados (`- [x]`) e o gate de verificação passando**.
- **Plan-first:** o objetivo vira um **checklist exaustivo de itens verificáveis** — um
  por linha, cada um pequeno e com um jeito de provar (comando/teste/observação). Se o
  usuário já tem um checklist, ele é **incorporado inteiro** (nunca resumido/aparado).
- Grava em **`.schematize/overdev/CHECKLIST.md`** (control-plane que o hook lê) e espelha em
  **`<projeto>/<projeto>_archive/overdev/OBJETIVO.md`** (registro humano durável — §28).

## 2. O laço (sem parar) — começa DEPOIS da Fase 0
Fechada a fundação (§0), tickeia **item a item**. Enquanto houver item aberto: pega o
**próximo `- [ ]`** → **escreve o brief (micro-task)** → **despacha ao agente do papel adequado** (default subagent `sonnet`) que
implementa **de verdade** → **revisa** (diff + roda o teste/gate do item) → se falhou, **pede a
correção ao mesmo subagent** com o achado concreto → só então marca `- [x]` → repete. Do critério
mais barato ao mais caro.

**Orquestrador não desenvolve; subagent barato executa** (`references/orquestracao.md` §9):
- **Cada item é executado por subagent, nunca pelo principal.** O principal (modelo padrão da
  sessão, o que fala com o humano) só pega o item, escreve o brief, despacha, revisa com gate,
  pede correção e tickeia. Só corrige com a própria mão a exceção estreita da §9.1 (1–2 linhas
  de integração), registrada.
- **Hierarquia de agentes** (`orquestracao.md` §9.3; papéis em `agentes.toml`): mecânico → `haiku`;
  código → `sonnet` → falhou, o **mesmo subagent corrige** (até 2 rodadas) → **Codex
  `gpt-5.6-terra`** → **Cursor** (se instalado) → **subagent `opus`**, com **motivo da escalada**
  registrado → esgotou → `park` + `- [~]` (§4). **Visual (UI/CSS/tema/ícone) vai direto ao Codex;
  imagem nunca pelo Claude: pergunta-se ao usuário qual usar, Codex sugerido (PROIBIDO API de imagem paga).** Codex/Cursor via
  `schematize overdev delegar --papel <p> --brief-stdin --json` (rc 3 → `proximo`).
- Cada item do CHECKLIST carrega a tag de executor: **`[sonnet]`** (default código), `[haiku]`,
  `[codex]`, `[cursor]` ou **`[opus: <motivo>]`**. Escalada e rodadas de correção ficam no checkpoint/archive do overdev
  (`<projeto>_archive/overdev/`, e `orchestration/` quando há fan-out). Unidades independentes (≥3) vão pra **fan-out de subagents**
(`references/orquestracao.md`) — paralelismo acelera, não autoriza fechar item sem prova.

**A cada item fechado, varredura de ociosos** (`references/orquestracao.md` §9.6): agent idle com pendência executável volta ao trabalho; pendência que depende de outro → mata e enfileira com gatilho de dependência; terminou → mata. Nada de subagent parado entre itens.

## 3. Continuidade à prova de parada (o mecanismo)
- **Stop hook `overdev-stop.sh`** (o núcleo): quando o agente tenta encerrar o turno, o
  hook conta os itens abertos (`- [ ]` máquina, `- [H ]` humano e `- [~]` on-hold) e roda o `.schematize/overdev/gate.sh` (se houver). Sobrou item ou o
  gate falhou → **rejeita a parada** e devolve ao agente a lista do que falta. É o que
  impede o "terminei" precoce: encerrar o turno = falar com o usuário, e o hook **bloqueia
  isso** até o checklist fechar.
- **Registro da parada prematura (a "punição"):** toda tentativa de parar com item aberto
  é anexada a `<archive>/overdev/premature-stops.log` (timestamp, ciclo, itens que
  faltavam) e o agente é forçado a continuar.
- **Backstop opcional de crash:** um heartbeat (`/loop` ou cron) que re-invoca
  `/eng-overdev resume` sobrevive a travada/compactação — o Stop hook cobre a sessão viva;
  o cron cobre o "a Anthropic travou". Opcional, ligado a pedido.

### Guard de papéis (a implementar no motor `schematize`) — ESPECIFICAÇÃO, PENDENTE NO CLI
> **Não existe ainda.** Hoje "o principal não desenvolve" (`orquestracao.md` §9.1) e "sem frota ociosa" (§9.6) são só texto normativo; esta subseção é o contrato que o CLI deve cumprir.
- **Hook `PreToolUse`** do motor, ativo só com run overdev ativo (`mode=active`): **bloqueia `Edit`/`Write`/`NotebookEdit` vindos do agent principal**. Subagents ficam liberados — o hook distingue pelo contexto do agent (payload do hook). **Exceção declarada:** arquivos de control-plane `.schematize/overdev/*` e o archive do run (`<projeto>/<projeto>_archive/…`).
- **Mensagem de bloqueio acionável:** "Overdev ativo: o agent principal não edita código. Despache ao agente do papel adequado (subagent sonnet por padrão) com o brief (escopo, critério de pronto, onde gravar o resultado)." Cada bloqueio é registrado no archive do run.
- **Hook `SubagentStop`:** registra a conclusão (unidade, modelo, resultado) e injeta o lembrete da varredura de ociosos (`orquestracao.md` §9.6).
- **`schematize overdev status`:** passa a contar as tags de executor (`[haiku]`/`[sonnet]`/`[codex]`/`[cursor]`/`[opus: motivo]`) do CHECKLIST e mostrar a **taxa de escalada** (opus ÷ total); taxa alta = brief ruim ou decomposição grossa, investigar.

## 4. NÃO trave pra perguntar — parkeia e segue (regra central)
A ideia do overdev é **por pra rodar e sair** (comer/dormir/viver). Então, **VETADO parar
pra perguntar com pool bloqueante (`AskUserQuestion`) enquanto em overdev** — o hook
`PreToolUse` (`schematize overdev guard`) **bloqueia** essa chamada. Muita pergunta que
parece "inegociável" pra IA é **inútil** pro humano e só trava o desenvolvimento.

Ao topar uma dúvida (mesmo que pareça bloqueante):
1. **Escreva a pergunta em `./PERGUNTAS-OVERDEV.txt`** (na **base do projeto**) — o usuário
   responde quando voltar.
2. **Marque aquele item como `- [~]` (on-hold)** — `schematize overdev park "<item>"
   "<pergunta>"` faz os dois (registra + marca).
3. **SIGA para os outros itens.** O `- [~]` não impede você de avançar nos demais, mas **conta como aberto** no hook: o run só termina quando ele for resolvido (vira `- [x]`) ou declarado em `.schematize/overdev/BLOCKED` (§4.1).

**Escalar para Opus não é pergunta** (§2): o principal sobe o degrau da escada sozinho, com o motivo
registrado, sem parar nem consultar o humano. Só **esgotou a escada** (Opus falhou 2×) vira `park`.

Assuma um **default razoável e documente-o** em vez de perguntar, sempre que o custo de
errar for reversível. Só parkeia o que for de fato irreversível/ambíguo demais.

## 4.1. Paradas LEGÍTIMAS
- **Concluído:** nenhum item aberto nas três classes (`- [ ]`, `- [H ]` e `- [~]` — tudo `- [x]`)
  **e** o gate passa → o agente pode encerrar e reportar. **`- [~]` NÃO é conclusão** (é o que o
  hook `overdev-stop.sh` faz: conta como aberto).
- **Bloqueado (`BLOCKED`):** sobrou só `- [H ]` (humano) e/ou `- [~]` (pergunta parkeada) sem caminho
  que a máquina resolva → escreva `.schematize/overdev/BLOCKED` listando, item a item, o que
  precisa do usuário e a pergunta (também em `PERGUNTAS-OVERDEV.txt`); o hook então permite parar
  e o usuário vê o que falta. É a saída honesta, não "concluído".
- **Teto de budget** (`--max`, default 200): guardrail anti-loop → encerra e reporta o que
  falta. Não é "desistir cedo", é não girar pra sempre.
- **Sem progresso mensurável (thrashing)** por vários ciclos → post-mortem curto, parkeia os
  itens travados e encerra. Nunca gira à toa.

> O que **não** é parada legítima: dizer "terminei" com item `- [ ]` aberto, ou abrir um
> pool de pergunta. O primeiro o Stop hook rejeita; o segundo o guard veta.

## 5. Guardrails inegociáveis (o overdev NÃO burla os pisos)
- "Sem parar" ≠ "sem verificar": **cada item fecha só com prova** (teste/gate), nunca por
  marcar `[x]` na fé. Marcar item não-verificado é a mesma macaquice do "terminei" precoce.
- Segurança, testes, archive e DoD **continuam valendo** — velocidade não desliga piso.
- O gate do projeto (`/eng-review`, testes, lint) entra no `.schematize/overdev/gate.sh` sempre que dá.

## 6. Estados do checklist e control-plane
- **Itens:** `- [ ]` aberto (máquina fecha) · `- [H ]` aberto (só humano fecha) · `- [x]` feito
  (verificado) · `- [~]` on-hold (pergunta parkeada: **conta como aberto**; só sai por resposta
  ou por `BLOCKED`, §4.1).
- **Layout operacional** `.schematize/overdev/` no root do projeto (trate como `.git` —
  **gitignore**): `state.json`, `CHECKLIST.md`, `iterations`, `gate.sh`, e (ao fim) `DONE` ou `BLOCKED`. O marcador canônico
  do projeto é a pasta **`.schematize/`** (contém `overdev/` e `grafos/`, §39); o antigo
  **`.overdev/` fica como LEGADO** — o motor Rust lê ambos e **auto-migra** para
  `.schematize/overdev/` no `overdev start`. `./PERGUNTAS-OVERDEV.txt` fica na **base** do
  projeto (é pro usuário ler). Ao encerrar (`schematize overdev stop`), `mode` sai de
  `active` → hooks voltam a ser inertes.

## 7. Motor: o CLI `schematize` (Rust) — não mais `.sh`
O overdev roda pelo binário **`schematize`** (repo `schematizeme/schematize-cli`), que
instala/versiona as skills **e** hospeda o motor:
- `schematize overdev enable` — registra **dois** hooks no `settings.json`: **Stop**
  (`overdev check` — não para até fechar; on-hold não conta) e **PreToolUse** matcher
  `AskUserQuestion` (`overdev guard` — veta o pool de pergunta). Uma vez; **inerte** sem run.
- `schematize overdev start "<objetivo>"` · `status` · `park "<item>" "<pergunta>"` ·
  `hold "<item>"` · `stop`.
- Instalar o CLI: `curl -fsSL .../schematize-cli/releases/latest/download/install.sh | bash`;
  depois `schematize install --all`.

> O hook shell legado (`assets/hooks/overdev-stop.sh`) fica só como **fallback Stop-only**
> onde o binário não está instalado — ele não veta `AskUserQuestion` (só o CLI faz os dois).
> O comando `/eng-overdev` prioriza o binário.

## 8. Contexto da aplicação + painel auxiliar e tela de grafos (fora do CLI/VSCode)
O `schematize` **guarda o contexto da aplicação** e o expõe num **painel auxiliar fora do
CLI/VSCode** — para o humano acompanhar o run enquanto o agente trabalha:
- **Fonte de dados (o control-plane da Fase 0):** `.schematize/overdev/DECISOES.md`,
  `.schematize/overdev/PLAN.md`, `.schematize/overdev/CHECKLIST.md`, `./PERGUNTAS-OVERDEV.txt`
  e o **grafo vivo** (`.schematize/grafos/`, §39). O painel **lê** esses arquivos — não é
  fonte da verdade, é vista.
- **Painel HTML no browser** (`schematize panel` — em construção): decisões, plano, progresso do
  checklist (feitos/abertos/on-hold), perguntas parkeadas e a **tela de grafos** interativa
  (force-directed **estilo Obsidian**), com cada nó **linkado ao `arquivo:linha`** do index.
- **Integração Obsidian** (`schematize graph obsidian` — em construção): exporta o index como
  **vault Obsidian** (markdown + `[[wikilinks]]`), navegável no graph view do Obsidian.
- **Regra:** o painel é **auxiliar e read-mostly** — o juiz do "terminou" continua sendo o
  checklist + gate (§6), não a tela. A tela ajuda a **ver**; o hook é quem **decide**.

> Fluxo completo do overdev: **Fase 0** (decisões → grafo → plano pesado → checklist) → **laço**
> (tick item a item, com prova) → **fim legítimo** (checklist fechado + gate), tudo visível no
> painel e ancorado no grafo do index.
