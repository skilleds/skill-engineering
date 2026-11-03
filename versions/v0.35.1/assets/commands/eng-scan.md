---
description: schematize-engineering — varredura ampla de problemas na base (correção, anti-padrões §37, pisos de código (`references/padroes-codigo.md`), duplicação/morto, testes, concorrência/recurso, dados/API, supply chain, dívida, deriva de índice), exaustiva por inventário, com fan-out; cada achado com arquivo:linha + severidade + piso + conserto
argument-hint: "[dir ou repo, ex: internal]"
---

Rode o **scan de problemas** (`references/scan.md`) do alvo `${ARGUMENTS:-.}` — a varredura
**ampla** da base: não é o gate do diff (`/eng-review`) nem o pentest de segurança
(`schematize-pentest`), é o inventário de **tudo que está errado** no código inteiro.

## 1. Escopo & inventário
Enumere e **conte** arquivos/funções por serviço no alvo (base do índice §39). Cobertura é a meta — classe aplicável sem varredura é cobertura faltante, não "sem problema".

## 2. Varra por classe (checklist de cobertura — `references/scan.md` §2)
Correção · anti-padrões (§37) · pisos de código (`padroes-codigo.md` §1–§3: >750 bloqueia, >300 úteis flag, função >50, sem doc-comment) · duplicação & código morto · testes (caminho crítico sem teste, guarda que não guarda, teste não coletado, **rota sem matriz de acesso / M ≠ N — piso 20**) · concorrência/recurso (race, cancelamento ausente, N+1, leak, retry sem backoff) · dados/API (validação ausente, migration sem down, contrato defasado, vazamento cross-tenant/PII) · supply chain (superfície: CVE, versão frouxa) · dívida (TODO/FIXME/HACK) · deriva de índice/MAPA (§39).

## 3. Paralelize (tempo > tokens)
≥3 áreas/classes independentes → **fan-out de subagents** (`references/orquestracao.md`): uma classe/área por agente, brief autossuficiente, **contrato de saída fixo**. O orquestrador faz gather + dedupe + **verificação única**.

## 4. Suspeito ≠ achado
**Verifique** cada suspeito antes de reportar (leia o código em volta, confirme o efeito). Pattern-match é suspeito; achado tem prova. Falso positivo queima o relatório.

## 5. Saída (machine-readable + archive)
Cada achado = `{classe, arquivo:linha, severidade (bloqueia/alta/média/baixa/info), descrição, piso violado, conserto, veredito}`. Grava em `<projeto>/<projeto>_archive/scan/<data>.md` (+ JSON pro CI). **Bloqueia** = viola piso/DoD (§35), não fecha.

## 6. Fecha o loop
Achados `bloqueia`/`alta` → **`/eng-plan`** (planejar o conserto) → **`/eng-refactor`**/fix com rede → **checklist** (candidato a `/eng-overdev`) → **`/eng-audit`** confere que sanou de verdade. Todo achado consertado vira **reteste** (não regride). Só dentro do escopo pedido.
