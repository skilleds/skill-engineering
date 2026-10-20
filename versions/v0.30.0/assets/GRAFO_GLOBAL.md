# Grafo GLOBAL da Aplicação — <projeto>

> O grafo GLOBAL da aplicação (§39). **Local operacional vivo:** `.schematize/grafos/GRAFO_GLOBAL.md`
> — é o que o app lê e desenha. **Espelho durável:** `<projeto>/<projeto>_archive/index/INDEX_GLOBAL.md`.
> Numa app MULTI-SERVIÇO, **cada microserviço é um nó** com suas **funções principais**
> (entrypoints/APIs públicas); as **arestas são os contratos** (saída de dados de A pra B).
> Enumere **TODOS** os serviços. Num serviço único: esse serviço + as arestas que cruzam a fronteira.
> **Arestas SEMPRE em ASCII `A -> B (contrato)` — NUNCA a seta unicode `→`** (o parser do app lê ASCII).
> Detalhe interno de cada serviço em `.schematize/grafos/<servico>.md`. Última atualização: <data>.

## Serviços (nós) e suas funções principais

### loja_api
| Função principal | O quê | arquivo:linha |
|---|---|---|
| `POST /pedido` | cria pedido a partir do checkout | `interface/http/pedido.rs:20` |
| `GET /pedido/:id` | consulta status do pedido | `interface/http/pedido.rs:58` |

### loja_worker
| Função principal | O quê | arquivo:linha |
|---|---|---|
| `consume pedido.criado` | processa pagamento do pedido | `jobs/pagamento.rs:14` |

### loja_ledger
| Função principal | O quê | arquivo:linha |
|---|---|---|
| `consume pedido.pago` | registra lançamento contábil | `jobs/lancamento.rs:11` |

## Arestas (contratos entre serviços) — ASCII

```
loja_api -> loja_worker (evento pedido.criado, Kafka v1)
loja_worker -> loja_ledger (evento pedido.pago, Kafka v1)
loja_worker -> loja_api (callback PATCH /pedido/:id/status)
```

> Cada aresta acima corresponde, no grafo detalhado do serviço de origem
> (`.schematize/grafos/<servico>.md`), a um nó de fronteira marcado `funcao -> <servico-destino>`.
