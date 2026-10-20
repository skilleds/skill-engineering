# Observabilidade, Healthchecks, Performance e FinOps

> Parte da skill **schematize-engineering**. A observabilidade (§16/§17) é **ponteiro** para a `schematize-observability`, que é a dona do tema. As referências cruzadas (§N) apontam para seções do corpo completo — todas presentes no conjunto de references desta skill.

## Índice
- 16. Observabilidade
- 17. Healthchecks
- 30. Performance — Metas Padrão
- 33. FinOps — Gestão de Custos

---

## 16. Observabilidade

> **A dona deste tema é a `schematize-observability`** (padrão OpenTelemetry, sinais, cardinalidade,
> amostragem, SLO/alertas, dashboards, stack de referência, ambientes). Aqui ficam só os **pisos da
> base** — o *como* mora lá e **não é repetido** (`schematize-observability` -> `SKILL.md` e `references/`).

**Piso:** toda ferramenta/serviço criado ou atualizado — **inclusive o `<projeto>_ops`** — nasce com
observabilidade **integrada de ponta a ponta**, nunca como extra depois: **OpenTelemetry** (SDK -> OTLP -> Collector),
logs estruturados, métricas, traces correlacionados por `trace_id`, e **dashboard + alertas + SLO versionados**
entregues com o serviço (chart/IaC). Um serviço só é "pronto" (§35) se expõe probes e `/metrics`, emite logs
e traces e sobe com dashboard + alertas. A stack de referência da casa (Collector, Prometheus/Mimir ou
VictoriaMetrics, Loki, Tempo, Grafana, Pyroscope) e o que é volátil estão em
`schematize-observability` -> `references/stack-referencia.md`.

### 16.1 Logs

- JSON estruturado, `trace_id`/`span_id`/`correlation_id`/`tenant_id` em toda request, níveis DEBUG..FATAL.
- **Proibido logar:** senhas, tokens, JWT, PII (CPF, email, telefone), dados financeiros, payloads de pagamento.
- **VETADO** logar request/response inteiros, headers ou body cru "pra debugar" (§37). Mascarar na origem e no Collector.
- Formato e regras: `schematize-observability` -> `references/logs.md`.

### 16.2 Métricas

- **RED por endpoint/handler** (Rate, Errors, Duration em histograma) e **USE para infra**.
- **Cardinalidade é orçamento:** `user_id`, e-mail, IP e URL crua nunca são label.
- Detalhe: `schematize-observability` -> `references/metricas.md`.

### 16.3 Tracing

- Toda chamada externa, fila, banco e fluxo crítico instrumentados; propagação **W3C Trace Context**
  (baggage sem dado sensível); 100% dos traces com erro amostrados.
- Detalhe: `schematize-observability` -> `references/padrao-otel.md` e `references/amostragem-profiling.md`.

### 16.4 SLOs

- Cada serviço define SLI/SLO em `/docs/slo.md`; error budget consumido -> freeze de features até recuperação.
- Alerta por **burn-rate multi-window**, sintoma de usuário, com `severity`, `for` e `runbook_url`.
- Detalhe e gate: `schematize-observability` -> `references/slo-alertas.md`.

### 16.5 Business Observability

**SHOULD**
- Métricas de negócio expostas (pedidos/min, conversão, churn, etc), em dashboards separados dos técnicos,
  KPIs principais instrumentados desde o dia 1.

### 16.6 Auditoria

**MUST**
- Operações sensíveis (mudança de permissão, transações financeiras, alteração de configuração, ações administrativas) registradas em **trilha de auditoria imutável**.
- Campos mínimos: `actor_id`, `tenant_id`, `action`, `resource`, `timestamp`, `ip`, `user_agent`, `result`.
- Retenção mínima conforme regulação aplicável.
- Storage append-only (não usar a mesma tabela de domínio). **Auditoria não é log de debug**:
  não é amostrada nem sofre a retenção do log (`schematize-observability` -> `references/logs.md` §4).

---

## 17. Healthchecks

Endpoints obrigatórios:
- `/health` — liveness (processo está vivo; **não** checa dependência)
- `/ready` — readiness (dependências OK, pronto pra tráfego; **distinta** da liveness)
- `/metrics` — Prometheus

Liveness != readiness != startup: o desenho completo está em `schematize-observability` -> `references/healthchecks.md`.

---

---

## 30. Performance — Metas Padrão

| Métrica | Alvo |
|---|---|
| API p95 | < 300 ms |
| API p99 | < 1 s |
| Startup | < 10 s |
| Imagem Docker | < 200 MB (Go/Rust), < 400 MB (Node) |

Metas específicas sobrescrevem, registradas no `/docs/slo.md`.

---

---

## 33. FinOps — Gestão de Custos

**SHOULD**
- Monitoramento de custo por serviço/squad/tenant.
- Budgets configurados com alertas de threshold.
- Revisão periódica de overprovisioning (CPU/memória/réplicas).
- Tags de billing consistentes em IaC.
- Custo por request rastreado em serviços de alto volume.

---

---
