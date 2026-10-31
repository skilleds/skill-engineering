# Checklist EXAUSTIVO de IAM — o "só está pronto quando está pronto"

O quê: o checklist normativo, por CONTAGEM e por FASE, que o `/eng-iam` instancia e roda sob a
disciplina do overdev (Stop-hook rejeita parada com item aberto). Cada item é pequeno, verificável
e traz **como provar** — checkbox sem prova NÃO fecha. As fases são PORTÕES: não se avança de `Fn`
sem o `GATE Fn-1` verde. Conclusão legítima = **todo item `- [x]` com prova E o `GATE F6` (pentest)
verde**. Deriva de `iam.md` (a normativa); onde este arquivo e o `iam.md` divergirem, o `iam.md` manda.
O checklist mantém o piso; a dona do desenho do broker é a `schematize-iam` (comandos `/iam-audit`,
`/iam-review`, `/iam-authz`; `schematize-iam → references/topologia.md`).

Convenção (mesma do overdev): `- [ ]` aberto de máquina · `- [x]` feito+provado · `- [H ]` item que
só o humano fecha (decisão/aprovação) · `- [~]` on-hold (pergunta parkeada). "prova:" = o teste que
passa / endpoint que responde / `arquivo:linha` / gate que passa HOJE. Sem a prova rodando, o item
volta a `- [ ]` (disciplina red-first da schematize-pentest: "suspeito ≠ feito").

> REGRA DE OURO: o checklist é o juiz. O agente NÃO decide que terminou — o gate decide. Marcar item
> sem prova é a macaquice do "terminei precoce". Em overdev, o Stop-hook veta a parada enquanto houver
> `- [ ]`. Dúvida irreversível? parkeia (`overdev park`) e segue — não trava pra perguntar.

---

## F0 — Núcleo de identidade (app SEPARADA; identidade ≠ email)

- [ ] Auth é **aplicação separada** (`<projeto>_auth_<lang>` + front próprio) servida em `auth.<domain>` — não monolith apensado. prova: repo/serviço/user-systemd isolados; o app principal só fala por OIDC.
- [ ] Consumidores **delegam por OIDC/OAuth2.1 + PKCE**; a chave de assinatura vive **só no auth**; consumidores validam por **JWKS público**. prova: `/.well-known/openid-configuration` + `/.well-known/jwks.json` respondem; consumidor valida assinatura por JWKS (não só presença de cookie).
- [ ] **Chave de assinatura JWT vem de PEM de config** (não efêmera). prova: sem `AUTH_JWT_PRIVATE_KEY_PEM` o serviço RECUSA subir em prod (ou loga erro fatal), NÃO gera chave efêmera — senão todo token invalida a cada restart.
- [ ] **`iss` (issuer) do token == a URL pública do auth** (`https://auth.<domain>`), não o default de dev. prova: token emitido tem `iss` = o que os consumidores esperam; teste de integração bate.
- [ ] **ID interno imutável e opaco** (ULID/UUIDv7) é o `sub`; **email/telefone NUNCA são ID**. prova: schema `users(id ULID pk)` + `identifiers(user_id, kind, value, verified)`; teste: trocar email preserva `sub`.
- [ ] **N identificadores por usuário**; identificador só vale **verificado**. prova: fluxo de verificação (email OTP) marca `verified`; identificador não-verificado não autentica.
- [ ] **Email OTP always-on** com provider **plugável** (Resend default) — e **entregue de verdade**. prova: `EmailProvider` real configurado; **sem `RESEND_API_KEY`/chave o serviço NÃO cai no LogEmailProvider em prod** (senão ninguém recebe código → cadastro/login impossíveis). Teste: OTP chega no canal, não só no log.
- [ ] Telefone/SMS por **provider plugável** (Twilio default), mesma regra de entrega real. prova: `SmsProvider` configurado ou explicitamente desabilitado por operador.
- [ ] **Sink obrigatório fora de `prd`** (o contrapeso do item acima): `EmailProvider`/`SmsProvider` default = **sink** quando `env != prd`, com **guard deny-by-default DENTRO do provider** (destinatário fora do domínio de teste em **rota nula** → **erro**, não no-op) e **cap por execução** que aborta. prova: teste que tenta enviar pra `@gmail.com` com `env=hml` e **espera a recusa** (vermelho visto); `dig MX test.<domain>` devolve **null MX (`0 .`)**; seed de dev/hml **não contém** a chave de produção do provedor. (`efeitos-externos.md`)
- [ ] **Passkey/WebAuthn é o método PADRÃO e entra na FASE 0 (passwordless-first):** registro (attestation) + asserção (login) reais e2e antes de qualquer feature; senha + Email OTP fica de fallback/2FA baseline (≥2 fatores e recuperação ≥ login permanecem). prova: enrolar passkey e logar com ela e2e no `auth.<domain>`; o app cliente só integra via OIDC/PKCE (`/web-iam`, `/mobile-auth`).
- [ ] **Testes obrigatórios de passkey na fase 0:** (1) registro; (2) login; (3) **challenge reutilizado rejeitado**; (4) **origin/rpId errado rejeitado**; (5) **credencial revogada rejeitada**. prova: 5 testes no CI, cada negativo visto VERMELHO antes de verde (red-first).
- [ ] **GATE F0:** cadastro→verificação→identidade criada roda ponta-a-ponta com OTP entregue de verdade, token com `iss` certo assinado por chave de PEM **e passkey (registro+asserção) provada com os 5 testes acima — pré-condição do gate**. prova: teste e2e do onboarding baseline passa em ambiente com https + suíte de passkey verde.

## F1 — 2FA baseline por desenho + fluxos (SEM muro pré-login)

- [ ] **Senha argon2id + verificação contra vazadas (HIBP)**; senha é padrão mas **marcável como opcional** no seletor de modos. prova: hash argon2id; senha vazada é recusada; conta consegue viver sem senha (passkey/OTP).
- [ ] **Conta nasce com 2FA baseline: senha + Email OTP** — tratada como **2FA de verdade**, acesso baseline pleno desde o cadastro. prova: usuário só com senha+email verificado tem acesso baseline completo.
- [ ] **PROIBIDO o muro pré-login de fator forte** — nenhum estado barra o login/acesso baseline por falta de passkey/TOTP. prova: **teste de reachability** (schematize-pentest `iam-testing.md`): conta só senha+email NÃO é bloqueada; `iam.md:124` "bloquear login por falta de fator forte = bug de bootstrap".
- [ ] **Passkey/WebAuthn é NÚCLEO — fluxo REAL, não label:** registro (attestation) + asserção (login) implementados. prova: enrolar passkey e logar com passkey funciona e2e; NÃO basta mapear a string `"passkey" => AAL_HIGH` sem fluxo (esse é o furo comum).
- [ ] **TOTP** (enroll com segredo **cifrado at-rest**) e **push-approval** implementados. prova: enroll+verify TOTP passa; segredo TOTP não está em texto claro no banco.
- [ ] **Escolha de método no login:** sem app→Email OTP; com app→pergunta; vários fatores→lista e o usuário escolhe. prova: teste dos 3 caminhos.
- [ ] **Invariante de troca Y≠X:** mutar o fator X exige um fator Y≠X no maior AAL; notifica todos os canais; remover o último fator forte = **atraso cancelável**. prova: teste tenta trocar app usando o próprio app → recusado; troca via email → ok + notificação.
- [ ] **Fator forte = nudge + step-up just-in-time**, exigido só em operação sensível (AAL alto) e escalado sob risco — enrolado NA HORA, verificado pelo Email OTP (Y≠X). prova: op sensível sem fator forte dispara step-up e permite enrolar ali; baseline segue livre.
- [ ] **Alcançabilidade por estado de conta:** para CADA estado (só senha+email, fator forte perdido, SSO sem local, convidado) existe acesso baseline + saída self-service para o que estiver degradado. prova: teste de reachability por estado; a "saída" nunca manda quem não tem sessão pra página que exige sessão, nem terceiriza o que só o dono faz.
- [ ] **Risk engine adaptativo:** score (IP/device/geo/velocity/honeypot) + escalonamento a **3FA** sob risco + **negação deceptiva/tarpit** (resposta idêntica ao erro real, timing constante) + notifica login suspeito. prova: sinais reais (não stub `false` fixo) alimentam o score; teste de timing constante.
- [ ] **GATE F1:** onboarding→login→step-up→troca de fator rodam e2e; reachability verde em todos os estados; ZERO muro pré-login. prova: suíte F1 + reachability passa.

## F2 — Multi-tenant + autorização ReBAC (deny-default)

- [ ] **Identidade global, papéis por tenant** (membership): tabelas `tenant`, `membership`, `role`/`permission`. prova: schema existe; um usuário pertence a N tenants com papéis distintos.
- [ ] **Motor ReBAC** (OpenFGA/SpiceDB estilo Zanzibar): tuplas `(objeto, relação, usuário)`; **RBAC granular** `recurso:ação` + papéis customizados; **ABAC** por conditional tuples. prova: modelo de autorização carregado; check de tupla decide acesso.
- [ ] **PDP/PEP separados, deny-default, enforcement SERVER-SIDE, token fino, decisão auditada.** prova: token não carrega permissões gordas; a decisão é do PDP no servidor; negação por padrão (recurso novo = negado até liberar); cada decisão vira audit log.
- [ ] **GATE F2:** autorização cross-tenant é NEGADA por padrão e só passa com tupla explícita. prova: teste BOLA/IDOR cross-tenant da schematize-pentest passa (nega o que não tem tupla).

## F3 — Recuperação resiliente (força ≥ login)

- [ ] **Múltiplos caminhos independentes** (vários emails, códigos de backup offline, telefone). prova: cada caminho recupera sozinho; nenhum é bypass de 1 fator.
- [ ] **Recuperação com força ≥ login** (2 fatores ou processo com atraso + revisão), rate-limit agressivo, tudo auditado. prova: reset exige ≥ a força do login; teste de rate-limit.
- [ ] **SSO com recuperação local forçada** + account-linking explícito (anti-takeover) + **nudge de email secundário**. prova: conta SSO tem caminho local; linking pede prova.
- [ ] **GATE F3:** cada estado de "perdi acesso" tem saída provada; reset nunca vira bypass. prova: suíte de recuperação + abuso de reset (pentest) passa.

## F4 — App de 1ª classe + sessão longa + logout irreversível

- [ ] **OIDC/PKCE nativo** no app + **push-approval** + **view de dispositivos** (remover / "sair de todos"). prova: fluxo nativo + listar/revogar device.
- [ ] **Sessão 7 dias padrão; 90 dias se confiável**; access token curto **com refresh silencioso**. prova: sessão não expira em 15 min.
- [ ] **Refresh IMPLEMENTADO no consumidor (BFF)** — não basta o IdP ter refresh rotativo; o front/consumidor tem que exercê-lo. prova: com access token expirado, o BFF renova via `sz_rt` e a sessão sobrevive (mata o "chutado em 15 min"; hoje o BFF do front NÃO tem rota de refresh — furo real).
- [ ] **Logout IRREVERSÍVEL:** revoga refresh + família, apaga sessão server-side, `jti` na denylist, desassocia push token — nada recria a sessão. prova: pós-logout, o refresh antigo é rejeitado (teste de refresh-reuse) e a sessão não ressuscita.
- [ ] **GATE F4:** sessão longa sobrevive à expiração do access; logout não deixa resíduo revivível. prova: suíte de sessão + refresh-reuse + logout (pentest) passa.

## F5 — Migração de legado (prioridade 0 quando há auth legado)

- [ ] **Strangler-fig dual-run**; **re-hash preguiçoso →argon2id** no login; mapeia registros→modelo novo (dedupe emails, cunha IDs). prova: login legado re-hasheia; nenhum registro órfão.
- [ ] **Re-deriva authz do zero** (nunca confia na antiga); **revoga sessões legadas**. prova: sessão legada não vale; permissões vêm do ReBAC novo.
- [ ] **1º login pós-migração NÃO barra por falta de fator forte** — usa nudge + step-up (mesma regra F1), não o muro. prova: migração não recria o deadlock de bootstrap.
- [ ] **GATE F5:** corte legado→novo sem takeover, sem sessão legada viva, sem muro. prova: suíte de migração passa.

## F6 — Rotina AGRESSIVA de testes = o gate de conclusão

- [ ] **Cross-tenant (BOLA/IDOR)** — vazamento entre tenants. prova: gate trava em qualquer vazamento.
- [ ] **Priv-esc (BFLA)** — subir de papel/função. prova: nega escalonamento.
- [ ] **Abuso de fluxo:** bypass de 2FA/reset/step-up, replay, **refresh reuse**, logout que não invalidou. prova: cada vetor recusado.
- [ ] **Reachability de bootstrap** (F1) roda no CI: nenhum estado bloqueia o baseline. prova: teste de reachability no pipeline.
- [ ] **GATE F6 (conclusão):** a rotina agressiva da schematize-pentest (`/pentest-authz`) passa no CI E agendada, travando em qualquer vazamento. prova: pipeline verde; um vazamento = build vermelho = NÃO está pronto.

---

## Como o `/eng-iam` usa isto

1. **audit:** varre o projeto e marca cada item acima como feito(`- [x]` com prova)/aberto(`- [ ]`)/on-hold(`- [~]`), medindo a cobertura por fase.
2. **bootstrap|migrate:** instancia os itens ABERTOS em `.schematize/overdev/CHECKLIST.md` e roda sob `schematize overdev start "IAM"` — o Stop-hook **rejeita a parada** enquanto houver `- [ ]`. Não avança de fase sem o `GATE` anterior verde. Conclusão só com **todo item provado + GATE F6 (pentest) verde**.
3. O gate do pentest é **condição de conclusão**, não sugestão: vazou cross-tenant/priv-esc/abuso-de-fluxo → não está pronto.
