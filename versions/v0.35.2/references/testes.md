# Testes / Q.A. → skill dedicada `schematize-qa`

> **Movido.** A disciplina de testes/Q.A. da casa foi **extraída** desta skill para a skill dedicada
> **`schematize-qa`**. O que antes vivia aqui (a antiga seção 22 desta skill: test kit, "verde de verdade", categorias de
> teste, cobertura, smoke, unit agressivo, mutation, Q.A. plan-first, Makefile de teste) e em
> a antiga reference *testes-execucao* agora mora lá, junto com o conteúdo novo (pirâmide, teste de comportamento,
> a11y, regressão visual, contrato/dados, flaky).

## O que a `schematize-engineering` mantém (piso mínimo)

Só o **piso** que a base não abre mão, delegando o **COMO** pra `schematize-qa`:

- **A Definition of Done exige testes verdes** (`entrega.md` §35): testes passam (unit + integração),
  cobertura nos mínimos, caminhos críticos com teste explícito, smoke que prova conteúdo, e nenhum item
  da §37 no diff. *Como* escrever/rodar/medir cada um desses é a `schematize-qa`.
- **Teste nunca silenciado pra passar CI** (`anti-padroes.md` §37): `.skip`, comentar assert ou baixar
  threshold é VETADO. Conserta o código, não o teste.
- **Refactor exige rede de testes ANTES** (`refactor.md`): red-first/characterization; a mesma suíte
  verde antes e depois. A técnica de teste é a `schematize-qa`.

## Resiliência do microserviço: fila + testes (piso 28)

Cada microserviço é à parte e funciona sozinho (pisos 10 e 28; `arquitetura.md` §2; `dados-eventos.md` §18). A casa **não delega** esta parte à `schematize-qa`: o gate de resiliência é da base.

**Desenho mínimo.** Dado que depende de outro serviço que não responde entra numa **fila durável** (outbox/inbox em DB ou Redis com persistência; memória NÃO vale). Consumidor: lê, **processa e persiste, só então confirma** (ack depois do commit); chave de idempotência por mensagem; retry com backoff exponencial + jitter e teto de tentativas; circuit breaker por dependência; após N falhas vai para a **DLQ** (com alerta e `trace_id`); o relay da fila nunca bloqueia o caminho de requisição. Boot não consulta vizinho como pré-condição; shutdown (SIGTERM) para de aceitar, drena o em voo, persiste o estado e sai.

**Os 7 testes unitários obrigatórios por serviço** (pseudocódigo agnóstico; use dublês de dependência e um store real ou fake **durável**, nunca uma lista em memória que o teste reinicia):

```
test boot_sem_dependencias:                      # 1
  dep.todas = INDISPONIVEL
  svc = iniciar()
  afirma svc.vivo e svc.saude == OK              # sobe com todos os vizinhos mortos

test dependencia_indisponivel_<dep>:             # 2 (um por dependência declarada)
  para modo em [TIMEOUT, HTTP_5XX, CONEXAO_RECUSADA]:
    dep[<dep>].modo = modo
    svc.processar(item)
    afirma fila.contem(item) e svc.vivo e svc.saude == OK
    afirma alerta.emitido com trace_id

test restart_fila_cheia:                         # 3
  fila.enfileirar(1000 itens com chaves unicas); svc.parar(); svc = iniciar()
  dep.volta()
  esperar fila.vazia
  afirma dep.recebidos == 1000 sem duplicata e sem falta

test reentrega_idempotente:                      # 4
  m = mensagem(chave="k1"); svc.receber(m); svc.receber(m)
  afirma efeito.aplicado_vezes("k1") == 1

test dlq_envenenada:                             # 5
  fila.enfileirar(veneno, normal1, normal2)
  afirma normal1 e normal2 processados            # fila nao trava
  afirma dlq.contem(veneno) apos N tentativas, tentativas == N

test shutdown_gracioso:                          # 6
  iniciar processamento lento de item; svc.sigterm()
  afirma item concluido OU devolvido a fila; nada perdido; svc.saiu_limpo

test crash_entre_persistir_e_confirmar:          # 7
  injetar_falha(apos="persistir", antes="ack"); svc.receber(m) -> crash
  svc = reiniciar()
  afirma store.contem(m) e (m reentregue nao duplica efeito)
```

**Matriz de resiliência (M == N).** Cada serviço declara as dependências em `resilience.yml`:

```yaml
service: ledger
dependencies:
  - core
  - redis
```

M = dependências declaradas; N = dependências com teste de indisponibilidade (caso 2). Os casos 1, 3-7 são por serviço. O gate falha se faltar qualquer teste nomeado ou se M != N. Serviço sem vizinhos declara `dependencies: []` (casos 2-5 dispensados; 1, 6 e 7 seguem).

**Gate:** `scripts/check-resilience.sh <dir-do-servico>`. **Limitação documentada:** é heurística por **nome** do teste (tags `boot_sem_dependencias`, `dependencia_indisponivel_<dep>`, `restart_fila_cheia`, `reentrega_idempotente`, `dlq_envenenada`, `shutdown_gracioso`, `crash_entre_persistir_e_confirmar`, sem distinguir caixa nem separadores; teste pulado não conta). Prova que o teste existe, não que é bom; que passa é o CI da stack. Revisão humana confere se o teste afirma de verdade o comportamento.

## Onde está o COMO

| Preciso de… | Vá para |
|---|---|
| Estratégia, pirâmide, comportamento-não-render, cobertura útil, Q.A. como DoD, gates de CI | `schematize-qa` → `references/estrategia.md` |
| Unit/componente/integração/e2e/smoke/a11y/visual/contrato/dados, `simulated` | `schematize-qa` → `references/categorias.md` |
| Flaky tests (detecção, determinismo, quarentena) | `schematize-qa` → `references/flaky.md` |
| Plan-first, test kit, `summary.json`, seeds, CI, Makefile | `schematize-qa` → `references/execucao.md` |
| Q.A. plan-first (comando) | `/qa-plan` -> `/qa-run` (era `eng-qa`, removido na v0.15.1) |

> **Segurança ofensiva** (pentest de rejeição, injeção/coerção, IDOR/BOLA, cross-tenant, hardening,
> red-team) **não** é Q.A. — é a **`schematize-pentest`**. **Auditoria de histórico** (os checklists
> foram sanados?) é a **`schematize-audit`**.
