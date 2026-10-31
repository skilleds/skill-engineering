---
description: schematize-engineering — refactor disciplinado: muda a forma SEM mudar o comportamento, com rede de testes ANTES (red-first/characterization), passos pequenos e reversíveis (verde entre cada), escopo-diff (regra do escoteiro), sem novo anti-padrão; catálogo de refactors seguros; gate exige mesma suíte verde + contrato idêntico + índice atualizado
argument-hint: "[alvo, ex: internal/pedido]"
---

Refatore `${ARGUMENTS:-o alvo}` pela disciplina de `references/refactor.md` — **mudar a
estrutura sem mudar o comportamento observável**. Se a mudança altera comportamento (corrige
bug, muda resposta), **não é refactor**: separe em outro commit/PR.

## Pisos (não negocia — `references/refactor.md` §1)
- **Comportamento preservado** (saída/contrato idêntico antes/depois).
- **Rede de testes ANTES:** o comportamento atual está coberto e **verde**; sem teste, escreve **characterization test** e **prova que ele falha** quando você quebra (a guarda vista no vermelho). A **mesma suíte** roda verde depois.
- **Passos pequenos e reversíveis:** um refactor atômico por commit, **verde entre cada**. Nada de big-bang.
- **Escopo-diff (escoteiro):** melhora o que **toca**; sem scope creep.
- **Sem novo anti-padrão (§37) nem piso quebrado (`padroes-codigo.md`)** — reduz dívida, não troca por outra.

## Gatilhos (métrica é indício, refatora quando paga — §2)
arquivo >750 / >300 úteis, função >50 ou responsabilidade múltipla, duplicação, complexidade/aninhamento, god object, nomes que mentem, ciclo de dependência. (Vêm do `/eng-scan`.)

## Catálogo seguro (o "como" — §3)
extract function/module · rename (índice §39 acompanha) · inline · introduce parameter object/DTO · replace conditional with polymorphism/table · dependency inversion · dedupe (sem `commons` de domínio) · **strangler-fig** pra legado grande (cruza `schematize-node`).

## O laço (§4)
1. rede verde (ou characterization test provado no vermelho) → 2. **um** passo do catálogo → 3. roda a suíte: verde segue, vermelho reverte (o passo mudou comportamento) → 4. commit pequeno (`refactor: …`) → 5. repete; **atualiza índice/MAPA (§39)** + doc-comments no mesmo PR.
Refactor grande (cruza serviços/muda arquitetura) passa antes pelo **`/eng-plan`** (fases/deps/riscos/ADR) e pode virar `/eng-overdev`.

## Gate / DoD (§5)
**Mesma suíte verde** antes e depois · **contrato/saída idêntico** (characterization/contract test prova) · nenhum anti-padrão novo · arquivos/funções no piso, duplicação/complexidade **mediu e caiu** · índice/MAPA atualizado · escopo contido · **archive** com antes/depois + motivo · reteste no CI.
