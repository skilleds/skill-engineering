# Refactor disciplinado — mudar a forma sem mudar o comportamento

> Refatorar é melhorar a **estrutura** interna **sem mudar o comportamento observável** —
> com rede de testes, em passos pequenos e reversíveis, sem scope creep. O `/eng-scan` acha
> os candidatos; o `/eng-plan` planeja o refactor grande; aqui está **como** mexer sem
> quebrar. Refactor sem rede é aposta; refactor que muda comportamento é outra coisa (feature
> ou fix) e vai em outro PR.

## 1. Pisos inegociáveis do refactor

- **Comportamento preservado.** A saída/contrato observável é **idêntico** antes e depois. Se
  mudou (corrigiu um bug, alterou uma resposta), **não é refactor** — separe: refactor num
  commit/PR, mudança de comportamento em outro. Misturar os dois esconde o risco.
- **Rede de testes ANTES (red-first / characterization).** Antes de mexer, o comportamento
  atual está coberto por testes que **passam**. Não há teste? escreva **characterization tests**
  primeiro (capturam o comportamento de hoje, inclusive o "errado") e prove que eles **falham**
  quando você quebra (a guarda vista no vermelho — cruza a skill **schematize-qa**). A **mesma suíte** roda
  verde depois. Sem rede, não refatora.
- **Passos pequenos e reversíveis.** Um refactor atômico por commit, **verde entre cada um**.
  Nada de "big bang" que fica semanas vermelho. Se travou, `git revert` de um passo é barato.
- **Escopo-diff (regra do escoteiro).** Melhora o que você **toca**; não sai refatorando o
  repo inteiro de carona. Sem scope creep — o refactor oportunista vira dívida de review.
- **Sem novo anti-padrão (§37) nem piso quebrado (`padroes-codigo.md`).** O refactor não introduz segredo no
  cliente, catch que engole, `any`, arquivo >750, função >300 úteis. Ele **reduz** dívida,
  não troca uma por outra.

## 2. Gatilhos — quando um trecho pede refactor (métrica é indício, não mandato)

Do `/eng-scan` e dos pisos de `padroes-codigo.md`: arquivo **>750 linhas** / **>300 úteis**,
função **>50 linhas** ou responsabilidade múltipla, **duplicação** (mesmo bloco em N lugares),
complexidade/aninhamento alto, **god object**, nomes que mentem, dependência ciclica,
abstração vazando, "tocar aqui sempre quebra ali". **Refatora quando paga** (o trecho é
tocado, é caminho crítico, ou bloqueia uma mudança) — não por perfeccionismo cego.

## 3. Catálogo de refactors seguros (o "como")

Cada um preserva comportamento se feito em passo pequeno com a rede verde:

- **Extract function / module:** tira um bloco coeso pra uma unidade nomeada (mata função
  gigante e duplicação). Uma-função-por-arquivo quando fizer sentido (`padroes-codigo.md` §2).
- **Rename:** nome que diz a verdade; propaga em todos os usos (o índice §39 acompanha).
- **Inline:** o inverso, quando a indireção não paga.
- **Introduce parameter object / DTO:** agrupa parâmetros que andam juntos.
- **Replace conditional with polymorphism / table:** mata `switch`/`if` gigante por tipo.
- **Dependency inversion:** o core depende de interface/trait, não do SDK (adaptador na borda).
- **Dedupe:** unifica o bloco repetido numa função — **sem** criar shared lib `commons` de
  domínio (isso é anti-padrão; dedupe dentro do bounded context).
- **Strangler-fig (legado grande):** encapsula o velho, desvia chamada a chamada pro novo,
  mede por funcionalidade, deleta o velho quando ninguém depende (cruza `schematize-node`).

## 4. O laço do refactor

1. **Rede verde** cobrindo o alvo (ou escreve characterization test e prova o vermelho).
2. **Um passo** do catálogo (§3).
3. **Roda a suíte** — verde? segue. Vermelho? o passo mudou comportamento → reverte e reduz o passo.
4. **Commit** pequeno e descritivo (`refactor: extrai X de Y`).
5. Repete até o gatilho fechar. **Atualiza o índice/MAPA (§39)** e os doc-comments no mesmo PR.

Refactor grande (cruza serviços, muda arquitetura) **não** entra no laço direto: passa pelo
`/eng-plan` (fases, deps, riscos, ADR da decisão estrutural) — e pode virar `/eng-overdev`.

## 5. Gate do refactor (Definition of Done)

- **Mesma suíte de testes verde** antes e depois; **comportamento/contrato idêntico** (diff de
  saída zero — characterization/contract test prova).
- **Nenhum anti-padrão novo** (§37); arquivos/funções **dentro do piso** (`padroes-codigo.md`); complexidade/
  duplicação **medida caiu** (não subiu).
- **Índice/MAPA atualizado** (renome/mover reflete no §39); doc-comments acompanham.
- **Escopo contido** (só o que foi tocado) e **archive** (§28) com o antes/depois e o motivo.
- **Reteste no CI:** a característica preservada fica coberta pra não regredir.

> Regra de bolso: se você não consegue provar que o comportamento é o mesmo, **não é
> refactor — é aposta.** A rede de testes vem primeiro; a beleza do código, depois.
