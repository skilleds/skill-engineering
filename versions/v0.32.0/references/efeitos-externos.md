# Efeitos externos fora de produção — sandbox por default e domínio de teste em ROTA NULA

> Parte da skill **schematize-engineering** (base agnóstica de linguagem). O detalhe de *teste*
> é a **schematize-qa**; o de *ataque/abuso* é a **schematize-pentest**; DNS/rede é a
> **schematize-infra**; o IAM que **dispara** e-mail (OTP always-on) é `references/iam.md`.

**Efeito externo** = qualquer ação de um ambiente nosso que **sai da nossa fronteira e chega em
alguém**: e-mail, SMS/voz, push, webhook para terceiro, cobrança/pagamento, chamada a API de
parceiro, correio físico. Fora de produção, **nenhum deles acontece de verdade** — por default,
sem ninguém precisar lembrar.

## 0. Por que isto é piso, e não "cuidado"

Um laço de teste que cria 5.000 contas dispara 5.000 OTPs. O estrago **não é o custo por e-mail**
(esse é o menor): endereços sintéticos viram **hard bounce** e **spam trap**; bounce e complaint
acima do limiar (**bounce > 2%**, **complaint > 0,1%** — os patamares de SES/Resend/Postmark)
**queimam a reputação do IP e do domínio**. A consequência é assimétrica e não tem undo:

- O e-mail **transacional de produção** para de chegar — inclusive o **OTP de login** (§iam.md
  §3: Email OTP é o 2º fator baseline). Reputação queimada = **usuário legítimo trancado fora**.
- Recuperar reputação leva **semanas a meses** de warm-up, não um deploy.
- Utilidade do envio: **zero**. Ninguém do outro lado. Custo puro, dano puro.

Por isso a regra não é "tome cuidado com o ambiente": **o ambiente é seguro por construção**, e
mandar de verdade é que exige um ato deliberado.

## 1. O domínio de teste da casa (rota nula)

Todo endereço sintético — fixture, seed, persona, factory, demo, carga, `simulated`, screenshot —
usa **o domínio de teste**, e ele é **nulo por DNS**:

```dns
; test.<domain> — existe só para receber lixo e não entregar nada
test.<domain>.        IN MX  0 .                                  ; Null MX (RFC 7505): não aceita e-mail
test.<domain>.        IN TXT "v=spf1 -all"                         ; ninguém envia em nome dele
_dmarc.test.<domain>. IN TXT "v=DMARC1; p=reject; sp=reject; rua=mailto:dmarc@<domain>"
```

- **Null MX (RFC 7505)** faz o MTA remetente **falhar na hora**, sem tentar entregar, sem fila,
  sem backscatter. É a "rota nula" do e-mail.
- **SPF `-all` + DMARC `p=reject`** impedem que o domínio de teste seja usado como remetente
  forjado — e isolam a reputação dele da do domínio corporativo.
- **Sem DNS próprio?** Use os TLDs reservados de **RFC 2606 / RFC 6761**: `@*.test`,
  `@*.invalid`, `@*.example`, `@example.com`. Não resolvem, por norma, em lugar nenhum do mundo.
- **Nunca** um subdomínio do domínio que **envia** produção. O domínio (ou subdomínio) de envio
  é separado por ambiente, para que a reputação de um jamais contamine o outro.

**VETADO como destinatário em qualquer artefato não-produtivo:**

| Vetado | Por quê |
|---|---|
| `@gmail.com`, `@hotmail.com`, `@outlook.com`, `@yahoo.com`, `@icloud.com` | são caixas reais de pessoas reais; spam trap e complaint direto |
| domínio do cliente / do parceiro / de qualquer terceiro | idem, e vira incidente de relacionamento |
| e-mail de pessoa real (inclusive o **seu** e o da equipe) | 5.000 na própria caixa é o mesmo bug, com a vítima mais perto |
| o **domínio de produção** da casa | contamina a reputação exata que se quer proteger |
| `@localhost`, `@teste`, endereços sem TLD | não são inválidos por norma; alguns MTAs tentam entregar |

**Forma canônica do endereço:** `<papel>+<run-id>-<n>@test.<domain>` — o `+tag` mantém unicidade
por execução e deixa o rastro (qual run gerou aquilo) sem inventar domínio novo.

## 2. Sink por default, fail-closed (a camada que realmente segura)

DNS é a rede de segurança; **o guard é o freio**. Fora de `prd`:

1. **O provider default é o SINK**, não o provedor real. Sink = catcher local (**Mailpit**/
   MailHog, com API HTTP para o teste ler a caixa) ou log estruturado. A escolha do provider é
   **por ambiente**, resolvida **uma vez** na composição — não em cada chamador.
2. **Guard deny-by-default DENTRO do provider** (não no chamador — chamador esquece):
   destinatário fora do domínio de teste com `env != prd` → **erro**, não warning, não no-op
   silencioso. Falha fechada: se a config de ambiente estiver ausente/ilegível, assume
   **não-produção** (o modo seguro).
3. **Teto por execução** (`MAIL_MAX_PER_RUN`, default 50) **+ circuit breaker**: estourou, o
   processo **aborta** com erro acionável. Os 5.000 só existem porque **nada estava contando**.
4. **Chave de API de não-produção é chave SANDBOX** — nunca a de produção, nem "a mesma chave, é
   só não usar". Chave de prd não existe fora de prd (`references/ops.md`: seed por ambiente).
5. **Auditoria:** todo envio (real ou sinkado) emite métrica/log com `env`, `provider`,
   `template`, `destino_hash`, `run_id`. Contador exposto → dá para **alertar** em anomalia
   (`mail_sent_total` subindo em hml é incidente, não curiosidade).

Pseudocódigo do guard — **uma função, server-side, sem bypass por parâmetro**:

```
fn assert_deliverable(to, env, allowlist):
    if env == PRD: return Ok            # produção entrega de verdade
    if domain_of(to) in TEST_DOMAINS: return Ok
    if to in allowlist and allowlist_enabled: return Ok
    return Err("bloqueado: destinatário externo em ambiente {env}. Use @test.<domain> \
                ou registre o ADR de exceção. Nada foi enviado.")
```

O `Err` é **erro de programação**, não erro do usuário: aparece no teste, no CI e no log — e
ensina o caminho certo na própria mensagem (`references/anti-padroes.md` §37, item *"A mensagem de erro ENSINA o caminho certo"* — por título, não por número: a numeração dos itens diverge entre skills).

## 3. Defesa em profundidade — as 4 camadas

Nenhuma sozinha basta; as quatro juntas tornam o acidente **impossível de acontecer em silêncio**.

| # | Camada | O que impede | Onde mora |
|---|---|---|---|
| 1 | **DNS** — null MX + SPF `-all` + DMARC `p=reject` no domínio de teste | entrega, mesmo se tudo o mais falhar | `schematize-infra` |
| 2 | **Aplicação** — sink default + guard deny-by-default + cap/circuit breaker | o disparo sair do processo | esta skill + skill de linguagem |
| 3 | **Rede/segredo** — egress SMTP (25/465/587) bloqueado em dev/hml; só chave sandbox no seed | o bypass "chamei o SDK direto" | `schematize-infra` / `references/ops.md` |
| 4 | **Provedor** — sandbox mode, subdomínio de envio por ambiente, alerta de bounce/complaint | contaminação de reputação entre ambientes | `schematize-infra` |

## 4. Vale para TODO efeito externo (não só e-mail)

Mesma classe de bug, mesmo guard, mesmo default:

- **SMS/voz (Twilio):** número de teste do provedor (magic numbers) + sink. SMS ainda **custa por
  unidade** — o cap importa mais, não menos.
- **Push:** token de sandbox (APNs sandbox / FCM de projeto de teste).
- **Webhook para terceiro:** aponta para receptor local (`webhook.site` **não** — é público;
  use um sink interno). Nunca a URL do parceiro.
- **Pagamento/cobrança:** chave de teste do PSP, sempre. Cartão real em não-prd é incidente
  financeiro, não bug. Regra e gate: `schematize-payments → references/nao-cobrar-fora-de-prd.md`.
- **Agente/LLM com tool de envio (`schematize-ai`):** a tool herda o **mesmo** provider guardado.
  Modelo não decide destinatário externo — o enforcement é determinístico, no servidor.

## 5. A exceção legítima (só com ADR — as 5 condições)

Existe caso real de precisar entregar de verdade fora de prd (validar renderização em Gmail,
homologar template com o cliente). Só roda com **as cinco** condições, registradas em **ADR**
(§27):

1. **ADR aceito** com motivo, janela e responsável nomeado.
2. **Allowlist nominal de ≤5 endereços**, todos da própria casa, no seed do ambiente.
3. **Cap explícito por execução** (ordem de dezenas), com abort ao estourar.
4. **Janela de tempo** — a flag expira por data (flag sem expiração é dívida, `entrega.md`).
5. **Subdomínio de envio separado** do de produção, para isolar reputação.

Faltou uma das cinco → **não roda**. "É rapidinho" não é uma das cinco.

## 6. Se já aconteceu — runbook de contenção

1. **Parar o disparo** (mata o job/laço) e **revogar a chave de API** usada — nessa ordem.
2. Medir no painel do provedor: **enviados, bounce %, complaint %, spam trap hits**.
3. Se bounce/complaint acima do limiar: **pausar todo envio** daquele domínio/subdomínio, abrir
   ticket com o provedor **antes** que ele suspenda a conta, e planejar **warm-up** (volume
   crescente) — não voltar ao volume normal de uma vez.
4. **Incidente registrado** (`references/operacao.md`, runbook) com post-mortem sem culpa: qual
   das 4 camadas faltava. Falta de camada é **bug de engenharia**, não descuido de quem rodou.
5. O post-mortem **fecha com a camada implantada** — não com "combinamos de tomar cuidado".

## 7. Definition of Done (entra na §35 quando o projeto envia qualquer coisa)

- [ ] Domínio de teste existe com **null MX + SPF `-all` + DMARC `p=reject`** (provado por `dig`).
- [ ] `EmailProvider`/`SmsProvider`/`PushProvider` **default = sink** fora de prd (provado por config).
- [ ] **Guard no provider** recusa destinatário externo fora de prd — com **teste que vê o vermelho**
      (tenta `@gmail.com` em hml e **espera a recusa**; `schematize-qa`).
- [ ] **Cap por execução** configurado, com teste que prova o abort ao estourar.
- [ ] **Nenhum** endereço de terceiro/pessoa real em fixture, seed, persona ou factory
      (grep no CI: `gmail|hotmail|outlook|yahoo|icloud` em `test*/`, `seed*/`, `fixtures/` **trava**).
- [ ] Chave de produção do provedor **não existe** no seed de dev/hml.
- [ ] Métrica de envio exposta e **alerta** para volume anômalo fora de prd.
