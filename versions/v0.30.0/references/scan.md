# Scan de problemas — varredura ampla da base (achar tudo que está errado)

> A **varredura proativa** da casa: dado um repo/serviço, encontra **todas as classes de
> problema** — não só segurança (isso é `schematize-pentest`), não só o diff (isso é
> `/eng-review`). O scan olha o **código inteiro** e produz um inventário de achados
> triados, cada um com `arquivo:linha`, classe, severidade, o **piso** que viola e o
> **conserto**. É o passo que alimenta o `/eng-plan` (planejar o conserto), o
> `/eng-refactor` (consertar com rede) e o `/eng-audit` (conferir que fechou).

## 1. Princípio — exaustivo por inventário, não por amostra

Como o índice (§39): **conte o que existe e varra tudo**, não "olhe onde parece ruim".
Um scan que só acha o óbvio é teatro. Enumere arquivos/funções/módulos (por serviço) e
passe cada classe de problema por cima — o alvo de completude é **cobertura**, não sorte.

**Suspeito ≠ achado** (a disciplina do pentest vale aqui): um pattern-match é **suspeito**;
vira **achado** só com verificação (leu o código em volta, confirmou o efeito). Falso
positivo custa a credibilidade do relatório — reporte o confirmado; o resto vai como
"verificar", não como problema.

## 2. Classes que o scan cobre (checklist de cobertura)

Marque cada classe como **coberta / N/A / achados** — classe aplicável sem varredura é
cobertura faltante, não "sem problema":

- **Correção:** bug lógico, off-by-one, condição invertida, `null`/`nil` não tratado, caminho de erro ausente, retorno ignorado, estado não inicializado.
- **Anti-padrões (§37):** segredo no cliente, SQL concatenado, auth no client, `tenant_id` do body, JWT sem validar, `Math.random` pra token, catch que engole erro (`catch{}`/`except:pass`/`_ = err`), `any`/`@ts-ignore`/`unwrap()` pra calar o compilador, teste silenciado. (Cruza `anti-padroes.md`.)
- **Pisos de código (`references/padroes-codigo.md` §1–§3):** arquivo >750 linhas (bloqueia), >300 úteis (flag), função >50 linhas, uma-função-por-arquivo violada, função sem doc-comment, god object.
- **Duplicação & morto:** código copiado (mesmo bloco em N lugares), função/rota/branch morta, import/dep não usada, flag/config obsoleta.
- **Testes:** caminho crítico sem teste, cobertura abaixo do piso, **guarda que não guarda** (teste verde que nunca reprovou o caso ruim — cruza **schematize-qa**, red-first), teste que o runner não coleta (glob de include), smoke sem self-check.
- **Concorrência/recurso:** race/TOCTOU, lock faltando, `AbortController`/cancelamento ausente onde a resposta obsoleta vence, N+1, leak (conexão/arquivo/goroutine/handle não fechado), retry sem backoff.
- **Dados/API:** validação de entrada ausente (coerção/`500` por input hostil), migration sem `down`, contrato/OpenAPI defasado, resposta que vaza campo cross-tenant/PII.
- **Supply chain (superfície):** dep com CVE conhecido, versão frouxa (`latest`/range), imagem base velha, lockfile ausente — **reporta**, aprofunda em `cadeia-suprimentos.md`.
- **Dívida sinalizada:** `TODO`/`FIXME`/`HACK`/`XXG`/`@deprecated` sem issue/prazo; comentário que mente sobre o código.
- **Deriva de doc/índice (§39):** `MAPA.md`/`INDEX_*` divergente do código real (função no código sem entrada, ou entrada sem função).

> Segurança em profundidade (injeção rota-a-rota, IDOR, authz, IA/LLM) é da
> `schematize-pentest` — o scan **sinaliza** a superfície e delega o aprofundamento.

## 3. Como rodar (`/eng-scan`)

1. **Escopo & inventário:** alvo (`${dir}` ou repo inteiro); enumere e conte arquivos/funções por serviço (base do índice, §39).
2. **Paralelize (tempo > tokens):** ≥3 áreas independentes → **fan-out de subagents** (`orquestracao.md`), uma classe/área por agente, com brief autossuficiente e **contrato de saída fixo**. Cada agente varre e devolve achados estruturados; o orquestrador faz o **gather + dedupe + verificação única**.
3. **Verifique cada suspeito** (§1) antes de promover a achado — leia o código em volta, confirme o efeito/oráculo.
4. **Triagem e saída machine-readable:** cada achado = `{classe, arquivo:linha, severidade (bloqueia/alta/média/baixa/info), descrição, piso violado, conserto sugerido, veredito(confirmado/suspeito)}`. Grava em `<projeto>/<projeto>_archive/scan/<data>.md` (+ JSON pro CI, se houver).

## 4. Severidade & o que cada nível dispara

- **Bloqueia:** viola piso inegociável (segredo no cliente, SQLi, auth no client, erro engolido em caminho crítico, teste silenciado) ou quebra correção. Não fecha DoD (§35).
- **Alta:** bug provável, race, leak, cobertura ausente em caminho crítico, dep com CVE alto.
- **Média/Baixa:** smell, duplicação, arquivo/função acima do piso, dívida sinalizada.
- **Info:** hardening, sugestão de clareza.

## 5. Gate & fluxo (o scan não morre no relatório)

- **Todo achado mapeia um piso/reference** (rastreável pro conserto), como no pentest.
- **O scan alimenta o loop:** `bloqueia`/`alta` viram **plano** (`/eng-plan`) e **refactor/fix** com rede (`/eng-refactor`); tudo entra num **checklist** (candidato a `/eng-overdev`).
- **Vira reteste:** o achado consertado ganha um teste que impede a regressão (cruza **schematize-qa**).
- **Fecha no audit:** o `/eng-audit` confere depois que os itens do scan foram **de fato** sanados (não só marcados).
- **Archive obrigatório** (§28): o relatório de scan mora em `<projeto>/<projeto>_archive/scan/`, nunca no root.

> Regra de bolso: o scan **fotografa a dívida inteira** de uma vez, com prova e conserto —
> pra você decidir o que pagar, não pra assustar. Achado sem `arquivo:linha` e sem conserto
> não é achado; é palpite.
