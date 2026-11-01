# Índice de Microfunções — <serviço>

> Grafo DETALHADO interno de um serviço (§39): funções como nós, chamadas intra-serviço como
> arestas, cada nó com `arquivo:linha`. Idealmente **gerado** dos doc-comments obrigatórios (`padroes-codigo.md` §3)
> via `scripts/build-index.mjs`. NÃO editar à mão as seções geradas — corrija o doc-comment na
> origem e regenere. **Espelho durável** de `.schematize/grafos/<servico>.md` (local operacional
> vivo). Local do espelho: `<projeto>/<projeto>_archive/index/INDEX_FUNCTIONS.md`. Última geração: <data>.
> Arestas SEMPRE em ASCII `->`, nunca `→`. Fronteira: função com saída pra outro serviço marca
> o nó como `nome -> <servico-B>` (aponta pro global).

## <módulo / pasta>

| Função | O quê | Onde é usada / prevista | Efeitos | Origem |
|---|---|---|---|---|
| `createOrder` | valida payload e cria pedido | use-case CreateOrder; handler POST /v1/checkout | persiste orders, publica evento via outbox | `application/order/create.ts:14` |
| ... | ... | ... | ... | ... |

<!-- BEGIN GENERATED -->
<!-- conteúdo gerado por build-index; não editar manualmente -->
<!-- END GENERATED -->
