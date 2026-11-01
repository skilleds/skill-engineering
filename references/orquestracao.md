# Orquestração & paralelização — tempo do usuário acima de tokens

> **Papéis e motor (§9):** o orquestrador (agent principal, **Claude Opus**) **não desenvolve** — planeja, despacha e revisa; quem executa é o **executor mais barato que resolve**: `haiku` (mecânico) ou `sonnet` (código), com escada **Sonnet → Codex `gpt-5.6-terra` → Cursor → subagent Opus → park**. Visual (UI) vai direto ao Codex (§9.3); imagem nunca pelo Claude: detecta Codex/Gemini e pergunta ao usuário qual usar (§9.7).
>
> Piso de **execução**: quando uma tarefa se divide em partes independentes, o padrão da casa é **decompor em mini-tasks e paralelizar com múltiplos subagents**, não fazer serial. O gargalo que otimizamos é o **relógio do usuário (wall-clock)**, não o orçamento de tokens. Preferimos gastar mais tokens e entregar em minutos a economizar tokens e levar horas. O que é vetado é o oposto: gastar 10× o tempo resolvendo serialmente algo que paralelizava.

## 1. Princípio (o trade-off explícito)

- **Tempo > tokens.** Se há um caminho que custa 5× mais tokens mas entrega em 15 min paralelizando, e outro que economiza tokens mas leva 2 h, **escolha o rápido**. Tokens são baratos; o tempo do usuário não.
- **Isso não é licença pra desperdício.** Paralelizar tem custo fixo (cada agent começa **frio** e re-deriva contexto; depois há o passo de juntar/integrar). Paralelizar trabalho **acoplado** ou **pequeno demais** só adiciona overhead e *gasta* o tempo do usuário. Juízo, não reflexo.

## 2. Regra de decisão (fan-out vs inline)

- **≥ 3 unidades independentes e não-triviais → fan-out** (um subagent por unidade, disparados **em paralelo numa só mensagem**).
- **< 3 unidades, ou trabalho acoplado/sequencial → inline** (faça você mesmo; abrir agents aqui perde).

**"Independente"** = as unidades **não compartilham alvo de escrita** e **não têm ordem obrigatória** entre si. Arquivos distintos, repos distintos, idiomas distintos, tópicos de pesquisa distintos: independentes. Um único arquivo coeso com dependências internas, ou um pipeline `build → deploy`: acoplado.

## 3. Largura do fan-out

- **Default otimizado: 8 subagents por onda.** Cobre a maioria dos casos (8 idiomas, N arquivos, N repos) numa tacada.
- **Teto global: 25** para tarefas extremamente grandes. Acima de 8 unidades, dispare em **ondas de 8** até 25; acima de 25, agrupe unidades por afinidade até caber.
- Cada subtask deve ser **chunky** o bastante pra amortizar o cold-start — se uma "unidade" é um único `Edit`, agrupe várias num só agent.

## 4. Playbook (como decompor bem)

1. **Design/decomposição primeiro (plan-first).** Se o desenho não está fechado, **decida a arquitetura/contrato antes** de abrir agents — senão eles divergem e a integração custa mais do que economizou. Fixe: interfaces, nomes, formato de saída, critério de "pronto".
2. **Particione por independência** (§2). Liste as unidades; confirme que não colidem.
3. **Brief autossuficiente por agent.** O subagent **não vê a conversa** — mande contexto necessário, caminhos absolutos, o contrato a seguir, e o critério de pronto. Um brief pobre gera retrabalho (o pior desperdício de tempo).
4. **Isole escritas.** Se agents tocam o mesmo repo: `isolation: "worktree"` (cada um numa cópia git isolada) **ou** particione por diretório/arquivo com fronteiras que não se cruzam. Nunca deixe dois agents escrevendo o mesmo arquivo.
5. **Orquestrador faz o gather — e revisa, não desenvolve (§9).** Você (o principal) junta os resultados, **revisa cada entrega** (diff + gate), **integra e verifica uma vez** (build/test/publish); o que estiver errado volta ao subagent, não vira código seu. Paralelize também a **verificação** quando ela se divide (curls independentes, suites por serviço).
6. **Continue, não recrie.** Pra iterar num agent que já tem o contexto, use continuação (SendMessage) em vez de abrir outro frio. **A continuação é o 1º passo da correção** (§9.3): falhou no gate, devolve ao mesmo subagent com o erro concreto antes de trocar de modelo.

## 5. Padrões de fan-out comuns

| Situação | Decomposição |
|---|---|
| N arquivos/módulos independentes a criar/editar | 1 agent por arquivo (ou grupo coeso) |
| Mesma mudança em N repos/serviços | 1 agent por repo (worktree se for o mesmo) |
| Traduzir/portar pra N idiomas/plataformas | 1 agent por idioma/alvo |
| Pesquisar M tópicos/perguntas | 1 agent (Explore) por tópico |
| Suite de testes por serviço/domínio | 1 agent por suite; gather do relatório |
| Auditoria/review de N áreas | 1 agent por área; consolida achados |

## 6. Onde NÃO paralelizar (seja honesto)

- Um **arquivo único coeso** com dependências internas.
- **Desenho ainda indefinido** (agents divergem — faça §4.1 antes).
- **Ordem dura** (`build → deploy`, migração antes de código que a usa).
- Quando o **custo de merge/coordenação > tempo economizado** (2 unidades pequenas).

## 7. Permanência — o MD é o backup, à prova de crash (MUST, proporcional)

**Limiar (checkpoint em MD obrigatório se QUALQUER um):** ≥ 5 unidades · duração estimada > 15 min · qualquer overdev · publicação/efeito irreversível no meio do fan-out. **Abaixo do limiar** basta a **tabela de status no relato final** ao humano (unidades, modelo, rodadas, resultado) — e a regra de retomada (item 4) **não se aplica**: refazer é mais barato que registrar. Checkpoint pulado **acima** do limiar é violação; em dúvida, grave.

Eventos de subagent são efêmeros: chat corrompe, a plataforma trava, uma onda morre no meio. **O estado nunca vive só nos eventos.** A verdade do fan-out mora num **MD de checkpoint** no archive, escrito **antes** de qualquer agent rodar e atualizado a cada onda — assim, se tudo cair, você **retoma lendo o MD**, sem refazer o que já ficou pronto.

1. **Antes de disparar a onda 1** (acima do limiar), grave o plano+checkpoint em **`<projeto>/<projeto>_archive/orchestration/<YYYY-MM-DD-HH-MM-SS>-<tarefa>.md`**: o contrato, a lista de unidades e uma **tabela de status** por unidade — colunas `unidade · status (PENDENTE / EM ANDAMENTO / FEITO / FALHOU / BLOQUEADA (depende de X)) · motor · modelo (ex.: claude/haiku, claude/sonnet, codex/gpt-5.6-terra, cursor/auto, claude/opus) · rodadas de correção · resultado (caminho)` (§9.4).
2. **Cada subagent grava o próprio resultado** num `.md` no archive (não só retorna pelo evento) — `…/orchestration/<tarefa>/<unidade>.md` com o que fez, arquivos tocados e o pronto/erro. Resultado que só existe no evento **não existe**.
3. **A cada onda que fecha**, o orquestrador **atualiza a tabela de status** no MD de checkpoint. O MD é sempre o retrato atual. Em seguida faça a **varredura de ociosos** (§9.6): nenhum agent fica parado esperando.
4. **Retomada:** se a sessão cai, o próximo passo é **ler o checkpoint** e disparar só as unidades `PENDENTE/FALHOU` — nunca recomeçar do zero. Sem retry infinito; unidade que esgota a escada de modelo (§9.3) vira gate humano.

> Isto é o mesmo princípio do handoff (§34.1) e do archive (§28): **MD como memória durável**. Se a resposta a "e se travar agora?" não for "abro o MD e continuo", o fan-out está sem rede.

## 8. Integração com o resto da casa

- **Plan-first, sempre.** Como o Q.A. plan-first (skill **schematize-qa**, `/qa-plan`), a orquestração **planeja a decomposição, mostra o fan-out e o custo, e pede aprovação** antes de disparar as ondas — passo destrutivo só com gate, sem retry infinito, retoma do checkpoint (§7) até concluir. Comando: `/eng-orchestrate`.
- **Archive.** Plano, checkpoint e resultado consolidado entram no archive (§28) — em `<projeto>/<projeto>_archive/orchestration/`, nunca no root — como qualquer entrega.
- **Contexto.** Ondas longas seguem a gestão de contexto (`references/contexto-claude-code.md`): handoff antes de compactar.

> Regra de bolso: **se dá pra dividir sem colidir, divida e paralelize — no executor mais barato que resolve (`haiku`/`sonnet`); o orquestrador não desenvolve, revisa.** O usuário paga o relógio, não o token; entre executores que entregam no mesmo tempo, o mais barato vence (§9). Mas paralelizar exige o mesmo rigor de sempre — contrato fixado, escrita isolada, **checkpoint em MD**, verificação única. Fan-out sem plano (ou sem checkpoint durável) é desperdício rápido, não entrega rápida.

## 9. Papéis, motores e escada (custo)

> Piso de **custo**: **orquestrador não desenvolve; subagent barato executa.** A §1 escolhe *paralelizar pelo relógio*; esta seção escolhe *quem executa e com qual modelo*. Vale mesmo para <3 unidades.

### 9.1 Papéis
- **Agent principal (orquestrador)** = o que conversa com o humano. É **Claude Opus** (papel `principal` do `agentes.toml`, §9.3) e **não delega a ele mesmo**. **NÃO desenvolve**: não escreve código de produto, não edita arquivo de entrega, não roda a implementação. Faz só: entender, **planejar/decompor**, escrever o **brief/contrato**, **despachar**, **supervisionar**, **revisar** (ler diff, rodar gate/teste, conferir contra o critério de pronto), **integrar** e falar com o humano.
- **Subagent (executor)** = faz a task. Brief autossuficiente (§4, passo 3), escopo fechado, critério de pronto, grava resultado no archive (§7).
- **Exceção estreita e declarada:** correção **trivial** de integração (1–2 linhas, ex.: conflito de import entre duas entregas) quando despachar custaria mais que fazer — registrada no checkpoint como "correção do orquestrador". Nunca vira hábito; na dúvida, despacha.

### 9.2 Ação onerosa → micro-funções baratas
- **Onerosa** = qualquer task que leria/escreveria muitos arquivos, geraria muito código, varreria a base, ou que um modelo caro levaria vários passos para fechar. Antes de executar, **decompor em micro-tasks** (idealmente = micro-funções da §39: uma função/unidade por task, com assinatura, doc-comment e teste definidos no brief) pequenas o bastante para um **modelo mais barato** acertar de primeira.
- Isto vale **mesmo quando <3 unidades**: a regra de fan-out (§2) decide *paralelizar ou não*; a §9 decide *quem executa* — sempre um subagent. Unidades acopladas rodam **em série** por subagents, não inline no principal.
- **Micro-task boa:** entrada/saída explícitas, arquivos-alvo nomeados, contrato fixado, prova (teste/comando) definida. Se o executor precisa "decidir arquitetura", a task não está micro o bastante — o desenho é do orquestrador.

### 9.3 Hierarquia de agentes: roteamento e escada
**Princípio:** escalar **só quando o mais barato falhar**. Claude é forte em código e fraco em visual.

**Roteamento por tipo de tarefa**
| Tipo | Vai para | Observação |
|---|---|---|
| Muito simples / mecânica (localizar, renomear, editar 1–2 linhas, pesquisa simples) | **Haiku** (papel `trivial`) | mais rápido, ~1/100 do custo do Opus |
| **Código** (padrão de toda micro-task) | **Sonnet** (papel `executor`) → escada abaixo | |
| **Visual** (UI, layout, CSS, tema, ícone, regressão visual) | **Codex `gpt-5.6-terra` direto** (papel `visual`) | não passa pelo Sonnet |
| **Imagem** (gerar/editar) | **nunca pelo Claude**: detectar Codex/Gemini e **PERGUNTAR ao usuário qual usar** (papel `imagem`; Codex, cota da assinatura, é a primeira sugestão, não automática) | **PROIBIDO** endpoint/API de imagem pago (§9.7) |
| 2ª opinião, revisão, testes, docs | Sonnet (papel `complementar`) | |

**Escada de código** (cada degrau só se o anterior falhou):
1. **Sonnet** (`executor`). Falhou → devolve ao **MESMO subagent** (SendMessage, com o erro concreto do gate/review). Até **2 rodadas** de correção.
2. **Codex `gpt-5.6-terra`** (`fallback-1`).
3. **Cursor** (`fallback-cursor`, `cursor-agent`) — **pulado com aviso** se não estiver instalado/logado.
4. **Subagent Opus** (`fallback-2`) — exceção justificada, com o **motivo da escalada** (o que os anteriores não conseguiram) no checkpoint.
5. Esgotou → **`park` + `- [~]`** (no overdev, nunca pergunta bloqueante). Antes de subir de degrau, considere **re-decompor** (task grande demais? brief pobre?).

**Configurável:** a estrutura vive em `agentes.toml` — global em `~/.claude/schematize/agentes.toml`, com override por projeto em `<projeto>/.schematize/overdev/agentes.toml` (o projeto sobrescreve por papel; `escada`/`roteamento` inteiros se presentes) — e na aba **"Agentes"** da GUI do overdev. Ausente → defaults abaixo. Papéis extras do usuário são permitidos.

| Papel | Motor / modelo (default) | Para quê |
|---|---|---|
| `principal` | claude / opus | orquestra: planeja, decompõe, despacha, revisa; **não** gera código de entrega |
| `trivial` | claude / haiku | tarefa muito simples/mecânica |
| `executor` | claude / sonnet | micro-task de código; até 2 rodadas de correção |
| `fallback-1` | codex / gpt-5.6-terra | executor falhou 2 rodadas |
| `fallback-cursor` | cursor / auto | Codex falhou (se `cursor-agent` instalado) |
| `fallback-2` | claude / opus | último recurso (subagent Opus) |
| `visual` | codex / gpt-5.6-terra | UI/layout/CSS/tema/ícone |
| `imagem` | codex / gpt-5.6-terra (sugerido) | só depois de perguntar ao usuário (Codex ou Gemini); cota da assinatura, sem API paga |
| `complementar` | claude / sonnet | 2ª opinião, revisão, testes, docs |

**Como chamar**
- **Claude** (`principal`/`trivial`/`executor`/`fallback-2`/`complementar`): subagent via **Agent tool** com `model: "haiku"|"sonnet"|"opus"` (em workflow, `model: '...'`).
- **Codex/Cursor:** `schematize overdev delegar --papel <p> --brief-stdin --json` (brief no stdin; grava em `.schematize/overdev/delegacoes/`). **rc 3 = indisponível** (motor ausente, sem login ou papel inativo) → não invente: use o `proximo` do JSON (`delegar --listar` mostra papéis e disponibilidade). rc 2 = config inválida; rc 4 = motor falhou (conta como falha do degrau).
- **Fallback sem o overdev instalado:** `codex exec -m gpt-5.6-terra -s workspace-write --json -C <dir> "<brief>"`.
- O principal **revisa** toda entrega, venha do motor que vier (§9.4).

### 9.4 Supervisão e revisão (o principal é o revisor)
- Toda entrega de subagent é **revisada pelo principal** antes de contar como feita: ler o diff, rodar o gate/teste do item, conferir o critério de pronto e os pisos (DoD §35, anti-padrões §37).
- Achou problema → **pede ao subagent que corrija** (com o achado concreto). O principal **só corrige com a própria mão se necessário** (exceção 9.1) — nunca reescreve por preferência.
- O checkpoint (§7) ganha colunas **motor** (`claude`/`codex`/`cursor`), **modelo** e **rodadas de correção** por unidade.

### 9.5 Relação com §1 (tempo > tokens)
Não conflita: paralelizar continua sendo o padrão para o relógio; a §9 escolhe o **executor mais barato que resolve**. Tempo do usuário > tokens; entre dois executores que entregam no mesmo tempo, o mais barato vence.

### 9.6 Sem frota ociosa (ciclo de vida do subagent)
- **Agent parado é custo:** polui a tela do humano e segura recurso (RAM/slots do governador de concorrência). O orquestrador **não mantém vários subagents idle ao mesmo tempo**.
- **Varredura de ociosos** — a cada onda que fecha, a cada notificação de conclusão e antes de despachar a próxima onda, o orquestrador lista os agents (no Claude Code: `ListAgents`) e classifica cada idle:
  1. **Tem pendência executável agora** → **põe pra trabalhar** (SendMessage com a próxima micro-task/correção; aproveita o contexto quente, §4 passo 6).
  2. **Pendência depende de outro agent/unidade ainda não pronta** → **mata o agent** (`TaskStop`) e **enfileira a task** no checkpoint (§7) com **gatilho de dependência** explícito (`depende_de: <unidade>` / status `BLOQUEADA`); quando a dependência fechar, **abre um agent novo** (do papel/motor adequado) com o brief. Nunca deixar agent vivo "esperando" outro.
  3. **Terminou** (entrega revisada e aceita, nada mais pra ele) → **mata** (`TaskStop`). O resultado já está no archive (§7); o agent não é memória.
- **Só é agent do orquestrador o que ELE abriu.** Sessões interativas do humano ou de outros projetos não são tocadas.
- O checkpoint (§7) ganha o status **`BLOQUEADA (depende de X)`** além de PENDENTE/EM ANDAMENTO/FEITO/FALHOU.
- No overdev, a varredura roda a cada item fechado no laço; nada de subagent parado entre itens.
- **Inventário de agents vivos (piso 25)** — ao fim de **cada onda/gather**, antes de despachar a próxima, o orquestrador lista os agents (`ListAgents`) e registra no checkpoint (§7) uma linha por agent vivo: `agent · papel · pendência executável · gatilho`. Quem não tem pendência executável **é encerrado na hora** (`TaskStop`). O relatório de 30 min (§9.8) repete essa lista.
- **Critérios de DESCARTE** (qualquer um basta): (a) **entregou e foi revisado** — diff + gate aceitos; (b) **falhou e foi substituído** — a escada (§9.3) subiu ou a unidade foi reatribuída; o agent velho não fica "de reserva"; (c) **sem pendência** — nada mais a pedir; (d) **depende de outro** — mata e enfileira com `depende_de`. **Nunca** manter agent idle "por precaução": contexto quente não justifica custo de slot/RAM; se precisar de novo, abre-se outro com brief completo (o estado está no archive).
- Conclusão da demanda com agent vivo sem pendência é violação (anti-padrão 55).

### 9.7 Mídia nunca pelo Claude; subagents de OUTROS modelos (-> `schematize-models`)
- **Piso:** imagem, visual gerado e mídia **nunca** saem de modelo Claude — a qualidade do visual
  gerado pelo Claude é inversamente proporcional à do código dele (sai ruim). Sempre: detectar Codex/Gemini
  disponíveis, **perguntar ao usuário** qual usar (o papel `imagem` do §9.3 — Codex, cota da assinatura — é a opção sugerida; API de imagem paga segue proibida), gerar, salvar em arquivo. Nenhum disponível: dizer
  sem rodeio e oferecer instalar/autenticar Codex ou Gemini, banco de imagem com licença comercial ou
  asset do cliente.
- **Roteamento multi-modelo** (Codex, Gemini, Cursor CLI como subagents): Claude fica com código,
  revisão, refactor, arquitetura e orquestração (peso máximo); outro modelo só por mídia, segunda
  opinião, vantagem documentada com fonte ou pedido do usuário. A escada `sonnet` -> `opus` desta
  seção cobre subagents **Claude**; o outro lado, os pesos, o contrato de delegação e a regra
  "saída externa é não confiável até o Claude validar" vivem na skill **`schematize-models`**
  (`/models-route`, `/models-delegate`, `/models-review`, `/models-image`).

### 9.8 Ritmo de registro — relatório a cada 30 min, handoff a cada 6 h (piso 26)
Registro frequente é o que torna a evolução **auditável** e a retomada **barata**. Duas marcas, contadas em tempo de **trabalho ativo** (relógio de parede entre a 1ª ação e agora, **descontando ociosidade > 15 min** — pausa maior que 15 min não conta).

**Relatório (30 min).** Arquivo curto `<projeto>/<projeto>_archive/relatorios/AAAA-MM-DD_HHMM.md` (hora local do início do relatório). Seções fixas, 1-3 linhas cada:
1. **Feito** — commits/SHAs desde o último relatório;
2. **Em andamento** — item do checklist, agent responsável, % ou próximo gate;
3. **Bloqueios / on-hold** — `[H ]` e `[~]` com motivo;
4. **Próximos passos** — 1 a 3 ações concretas;
5. **Agents vivos** — saída do inventário do §9.6 (ou "nenhum");
6. **Desvios** — o que fugiu do plano/pisos e por quê.
7. **Custo** — trecho do período (desde o último relatório) e o acumulado do projeto: total em US$ e tokens, por modelo e por task, lidos de `<projeto>_archive/custos/custos.json` após `schematize cost sync && schematize cost report`. Sempre com a ressalva **"estimativa API-equivalente; confira o /usage"**. Sem o app instalado: registre "custo indisponível (app sem `cost`)" como desvio, não invente número.
8. **Higiene e recursos** (piso 29) — disco antes/depois (`df`, local e na máquina dev/hml de build, se houver), o que a `scripts/higiene.sh` liberou (itens e bytes, do `.higiene.log`) e, quando houve máquina de build, o que foi enviado por ponte e o que rodou lá. Sem ciclo de build no período: "sem build". Não invente número: cole o resumo do script.
Sem segredo/PII (§16.1). Objetivo: um humano lê a pasta `relatorios/` e reconstrói a linha do tempo.

**Handoff (6 h + eventos).** Mesmo conteúdo do `/eng-handoff` (§34.1): `context.md` + `checklist.md` (em `context/AAAA-MM-DD-<slug>-*`) no archive, completos o bastante para uma sessão **nova** retomar **só com eles**. Gatilhos: (a) 6 h de trabalho ativo desde `ultimo_handoff`; (b) **todo fim de sessão**, fechamento de marco e antes de `/compact`.

**Custos (contabilidade).** O archive tem `<projeto>_archive/custos/` produzido pelo app (`schematize cost sync|report|show|tag|untag|pricing`; contrato v1 em `schematize_app_archive/contratos/custos-v1.md`, no archive do app):
- `ledger.jsonl` — append-only, 1 linha por resposta deduplicada (`message.id`): `{ts, dia, semana_iso, sessao, agente, modelo, task, in, out, cache_w, cache_r, usd}`; idempotente.
- `custos.json` (máquina) e o relatório humano `custos` em markdown — derivados do ledger: total, por modelo, dia, semana ISO, task, sessão e agente, em US$ e tokens.
- `pricing.toml` (opcional, override do projeto), `tasks.jsonl` (tags `cost tag`/`untag`, append-only), `.cursor.json` (offset por transcript).
Fonte: transcripts do Claude Code (`~/.claude/projects/<slug>/*.jsonl` e `subagents/`). Task = tag explícita, senão item ativo do checklist do overdev, senão `sem-task`. É **estimativa API-equivalente** (assinatura pode cobrar diferente; confira o `/usage`); modelo sem preço = custo `null` + aviso. Tudo versionado no git na hora, junto do relatório.

**Carimbo `<projeto>_archive/.ritmo.json`:** `{"ultimo_relatorio":"2026-10-31T14:30:00-03:00","ultimo_handoff":"2026-10-31T09:00:00-03:00"}` (ISO-8601). Atualizado **na mesma operação** que gera o relatório/handoff e commitado junto. O gate compara os dois carimbos com o relógio de parede (`--agora`), então vale **durante sessão ativa**; pausas > 15 min são descontadas pelo agente ao decidir se a marca venceu.

**Quem gera:** o **agente que está trabalhando** (o orquestrador, no modo orquestrado); subagent não gera relatório do projeto. **Quando:** passou da marca → gera **ANTES da próxima ação de entrega** (commit de código, deploy, nova onda). Não pergunta ao usuário (overdev veda); relatório/handoff entram no git na hora (piso 22). Comandos: `/eng-report` (relatório) e `/eng-handoff`.

**Ao retomar sessão:** ler `.ritmo.json`; se `ultimo_relatorio` > 30 min ou `ultimo_handoff` > 6 h (conta só trabalho ativo: a pausa entre sessões não conta; mas sessão anterior que terminou sem handoff é desvio a registrar) → gerar o que está vencido **antes** de agir, registrando em Desvios a lacuna. Sem `.ritmo.json` → criar com o relatório inicial e anotar o desvio. Gate: `scripts/check-ritmo.sh <archive>` (opcional no CI; `--agora` para teste).
