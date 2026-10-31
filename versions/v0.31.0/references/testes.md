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
