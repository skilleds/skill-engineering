<!--
FONTE ÚNICA — cauda comum do bullet "Efeito externo NUNCA sai de não-produção" (o lead específico da linguagem fica fora do bloco).
Herdada pelas skills derivadas da schematize-engineering via `tools/sync-herdados.mjs`.
Editar = editar AQUI + `node tools/sync-herdados.mjs`; o CI roda --check.
Variantes: invariantes (sem parâmetros).
Não escreva aqui o marcador "herdado" literal: este arquivo é a fonte, não um consumidor.
-->

<!-- variante:invariantes -->
**Cap por execução** (`MAIL_MAX_PER_RUN`, default 50) com abort; **fail-closed** (ambiente ausente/desconhecido ⇒ não-prd; só o valor exato de produção entrega de verdade); **chave sandbox** fora de prd. Todo endereço sintético (fixture, seed, persona, demo, carga) é `<papel>+<run-id>-<n>@test.<domain>` — domínio em **rota nula** (null MX RFC 7505 + SPF `-all` + DMARC `p=reject`) ou TLD reservado (`.test`/`.invalid`/`.example`); **VETADO** `@gmail.com`, domínio de cliente/terceiro, e-mail de pessoa real (**inclusive o seu**) e o domínio de produção. A recusa é **erro**, nunca warning nem sucesso silencioso. Entregar de verdade fora de prd exige **as cinco** (ADR + allowlist ≤5 + cap + janela + subdomínio separado). Motivo: bounce/complaint em massa **queima IP e domínio** e derruba o transacional de prd — inclusive o **OTP de login** — com semanas de warm-up e utilidade zero (o incidente dos 5.000 e-mails só existiu porque nada contava).
<!-- /variante -->

