---
description: schematize-engineering — força/audita/scaffolda o IAM da casa (identidade≠email, ≥2 fatores, ReBAC multi-tenant, sessão longa/logout irreversível) como app separado em auth.<domain>, ou atualiza um auth existente. RESTRITIVO — deriva o checklist exaustivo por fase e trava no overdev até tudo estar provado + o gate do pentest verde.
argument-hint: "[bootstrap | audit | migrate]"
---

Para auditar ou revisar só o IAM de um projeto com auth, existem também `/iam-audit` e `/iam-review` (`schematize-iam`); este comando é o orquestrador restritivo.

Governe identidade e autorização pelo padrão IAM da casa (`references/iam.md` = a normativa;
`references/iam-checklist.md` = o checklist exaustivo por fase). **Plan-first E restritivo:** audita,
mostra o plano, pede aprovação, então executa **sob a disciplina do overdev** — o checklist é o juiz,
não o agente. **Só está pronto quando está pronto:** todo item `- [x]` com prova E o `GATE F6`
(pentest) verde. Use este comando para forçar **só a parte de IAM** (projeto novo ou existente) ou
portar um auth legado.

## 0. Modo
- `audit` — varre o projeto e marca CADA item do `references/iam-checklist.md` como feito(`- [x]` com
  prova)/aberto(`- [ ]`)/on-hold(`- [~]`), medindo a cobertura por fase. Grava o relatório no archive.
- `bootstrap` — scaffolda o IAM do zero como **app separada** e roda o checklist até fechar.
- `migrate` — porta um auth legado pro IAM (**prioridade 0**, strangler-fig) e roda o checklist.

## 1. Topologia primeiro (inegociável)
Auth é **aplicação SEPARADA** (`iam.md` §1): serviço `<projeto>_auth_<lang>` + front próprio em
**`auth.<domain>`** — **VETADO** monolith apensado. Repo/deploy/user-systemd isolados. Consumidores
**delegam por OIDC/OAuth2.1 + PKCE**; chave de assinatura só no auth; validação por **JWKS público**.

## 2. Identidade
**ID interno imutável** (ULID/UUIDv7) é o `sub`; **email/telefone NUNCA são ID**; **N emails**
(incentivado), só valem **verificados**. SSO com **recuperação local forçada**; account-linking
explícito (anti-takeover); **nudge de email secundário**.

## 3. Fatores (≥2 sempre) — SEM muro pré-login
- **A conta nasce com 2FA baseline: senha + Email OTP** (always-on, Resend, entregue de verdade — não
  só no log). Isso **já é 2FA de verdade** e dá **acesso baseline pleno desde o cadastro**.
- **Passkey/WebAuthn é o método PADRÃO e entra na FASE 0** (piso 21; passwordless-first; fluxo real de registro+asserção antes de qualquer feature, não só o label AAL); testes obrigatórios na fase 0: registro, login, challenge reutilizado, origin/rpId errado e credencial revogada rejeitados. Pré-condição do `GATE F0`.
- Demais fatores: TOTP (segredo
  cifrado at-rest) e push; **Twilio** p/ telefone; providers **plugáveis**.
- **Senha por padrão** (argon2id + HIBP), marcável como opcional no seletor de modos.
- **Fator forte é INCENTIVADO (nudge) e exigido JUST-IN-TIME (step-up) só em operação sensível** — e
  escalado sob risco (§9). **NUNCA muro pré-login.** Contar senha+Email OTP como "sem 2FA" e barrar o
  acesso até enrolar fator forte é o **círculo infinito / bug de bootstrap** que a norma **VETA**
  (`iam.md:72-79,110-125`). Enrolar fator forte usa o Email OTP como verificação (Y≠X): sem deadlock.
- Invariante de troca: **mutar fator X exige fator Y≠X no maior AAL**; notifica canais; remover último
  fator forte = **atraso cancelável**. Recuperação **≥ força do login**.

## 4. Autorização (multi-tenant, ReBAC)
**Identidade global, papéis por tenant** (membership). Motor **ReBAC (OpenFGA/SpiceDB)**, tuplas
`(objeto, relação, usuário)`; **RBAC granular** (`recurso:ação`) + **ABAC** (conditional tuples).
**PDP/PEP separados, deny-default, enforcement server-side, token fino, decisão auditada.**

## 4b. Matriz de acesso por rota (piso 20)
Toda rota do auth e dos consumidores nasce com teste das 4 personas (anônimo, não privilegiado, privilegiado, burlas) afirmando status **e** corpo; deny-by-default; inventário derivado, M == N (`schematize-qa`, `check-route-authz.sh`). O `GATE F6` parte dessa matriz.

## 5. Sessão / logout
**Multi-dispositivo** + view de remover + "sair de todos". **Sessão 7 dias padrão; 90 dias se
confiável**; access token curto **com refresh silencioso — e o CONSUMIDOR (BFF) tem que exercer o
refresh** (nada de "15 min e é chutado"). Step-up fresco em op sensível. **Botão Sair → kill
IRREVERSÍVEL:** revoga refresh + família, apaga sessão server-side, `jti` na denylist, desassocia push.

## 6. Migração de legado (modo `migrate`, prioridade 0)
Strangler-fig: dual-run, **re-hash preguiçoso →argon2id** no login, mapeia registros→modelo novo
(dedupe emails, cunha IDs), **revoga sessões legadas**, **re-deriva authz** (nunca confia na antiga).
O **1º login pós-migração usa nudge + step-up, NUNCA barra por falta de fator forte** (mesma regra §3
— não recrie o deadlock). O auth migrado nasce app separado.

## 7. EXECUÇÃO RESTRITIVA (o "só está pronto quando está pronto")
1. **Instancia o checklist:** dos itens ABERTOS do `references/iam-checklist.md` (fases F0→F6, cada um
   com "como provar"), grava em `.schematize/overdev/CHECKLIST.md`.
2. **Roda sob overdev:** `schematize overdev start "IAM"` — o Stop-hook **rejeita a parada enquanto
   houver `- [ ]`**. Marcar item exige a PROVA rodando (teste/endpoint/`arquivo:linha`/gate). Checkbox
   sem prova volta a aberto (red-first: "suspeito ≠ feito").
3. **Fases são portões:** não avança de `Fn` sem o `GATE Fn-1` verde.
4. **Gate do pentest é CONDIÇÃO de conclusão, não sugestão:** rode a rotina agressiva da
   `schematize-pentest` (`/pentest-authz`) — **cross-tenant (BOLA/IDOR), priv-esc (BFLA), abuso de
   fluxo (bypass 2FA/reset/step-up, replay, refresh reuse, logout que não invalidou), reachability de
   bootstrap**. Vazou → **NÃO está pronto** (build vermelho). É o `GATE F6`.

## 8. Saída
Grave o plano/relatório em `<projeto>/<projeto>_archive/` (§28): topologia (app separado?), a tabela do
checklist por fase (feitos/abertos/on-hold + a prova de cada feito), e — se `migrate` — o mapa
legado→novo + a ordem de corte. **Só declare concluído com todo item `- [x]` provado E o `GATE F6`
verde.** Restou item aberto/on-hold? reporte o que falta e as perguntas parkeadas — não anuncie
"pronto".
