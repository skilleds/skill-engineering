# Operação: Config, Deploy, Git, Archive, ADR, IA e Anexos

> **Dividida:** §29+ (templates, feature flags, IA assistida, DoD §35, evolução, índice §39) estão em `references/entrega.md`. A numeração de seções é contínua entre os dois arquivos.

> Parte da skill **schematize-engineering**. As referências cruzadas (§N) apontam para seções do corpo completo — todas presentes no conjunto de references desta skill.

## Índice
- 20. Configuração
- 21. Infraestrutura e Deploy
- 24. Qualidade e Git
- 25. Ownership
- 26. Runbooks e Incidentes
- 27. ADR — Architecture Decision Records
- 28. Archive de Conversas e Tarefas — INEGOCIÁVEL
- 29. Templates
- 31. Feature Flags
- 34. Uso de IA Assistida
- 35. Definition of Done
- 36. Evolução
- 39. Índice de Funcionalidades (fonte da verdade viva)
- Anexo A — Versões Correntes
- Anexo B — Glossário Mínimo

---

## 20. Configuração

- Via environment variables (12-factor).
- Validação tipada no startup — falha rápido.
- Sem hardcode.
- Defaults seguros (fail closed).

---

---

## 21. Infraestrutura e Deploy

**MUST**
- Kubernetes + Helm.
- IaC: Terraform ou OpenTofu.
- CI/CD: GitHub Actions.
- Ambientes isolados: `dev` (local), `hml`/`staging` (homologação), `production`/`prd`.
- Promoção entre ambientes por **artefato imutável** (mesma imagem, commit SHA rastreável).
- **Fluxo de promoção fixo, sem atalho:** `desenvolvimento local → teste local (verde) → GitHub → hml → prd`. Nada pula etapa; **nada vai direto pra hml/prd**.
- **VETADO editar código direto no servidor (hml/prd).** O servidor é **imutável por edição manual** — recebe só artefato promovido do git. Precauções: filesystem read-only, **drift detection** (recusa/alerta divergência com o git), acesso de escrita = break-glass auditado. Hotfix segue o mesmo fluxo, acelerado. Detalhe e o control plane em **`references/ops.md`**.
- **Toda operação no servidor passa pelo `<projeto>_ops`** (§2, `references/ops.md`): install/update/config/migrate/rollback/troubleshoot — nunca à mão. Instalação **paralela por padrão** (= `nproc`); falha no paralelo = serviços não independentes → corrigir a independência é prioridade máxima (piso 10).

### 21.1 Estratégia de Deploy

| Estratégia | Quando usar |
|---|---|
| Rolling update | Default para serviços comuns |
| Blue/green | Serviços críticos, rollback instantâneo necessário |
| Canary | Mudanças de alto impacto, rollouts graduais |

**MUST**
- Rollback automatizado quando healthcheck falhar pós-deploy.
- Healthcheck gating: tráfego só vai pra pod ready.
- Janela de validação antes de declarar deploy bem-sucedido.

### 21.2 Preview Environments

**SHOULD**
- PRs em serviços principais geram ambiente efêmero automaticamente.
- Destruído ao merge ou após X dias de inatividade.

---

---

## 24. Qualidade e Git

**Commits:** Conventional Commits (regra completa, assinatura, PR e rulesets: `schematize-git → references/fluxo.md`).
**Versionamento:** SemVer.

**Branches — trunk-based como padrão**

```
main      → produção (protegida, linear history)

feature/<ticket>-<slug>
fix/<ticket>-<slug>
hotfix/<ticket>-<slug>
```

GitFlow (`develop`) é opcional e exige justificativa — só vale a pena em times com release cadenciado pesado.

**Pull Requests**
- Tamanho alvo: ≤ 400 linhas alteradas.
- ≥ 1 reviewer (≥ 2 para `domain`, schema, segurança).
- **CODEOWNERS obrigatório.**
- CI verde obrigatório.
- Squash merge na `main`.
- **Merge direto na `main` é VETADO.** Force push em branch protegida idem (§37).

---

---

## 25. Ownership

**MUST**
- Cada serviço tem **owner explícito** (squad ou pessoa).
- `CODEOWNERS` configurado.
- Documentação de **oncall** definida.
- Contato de escalação documentado no README.

---

---

## 26. Runbooks e Incidentes

### 26.1 Runbooks

**MUST**
- Todo serviço crítico tem runbook, e ele é **operável**: alguém de plantão que nunca mexeu no
  serviço consegue seguir. Runbook que só o autor entende não é runbook.
- Conteúdo mínimo: **sintoma → diagnóstico → ação → rollback → escalação**, com os dashboards e os
  comandos concretos.
- Incidente recorrente **atualiza** o runbook; se não atualizou, o postmortem não fechou.

> **A anatomia, o template e o teste do runbook são da `schematize-docs`**
> (`references/runbooks.md`, comando `/docs-runbook`) — 98 linhas contra as 3 que existiam aqui.
> Este §26.1 é o **contrato** (o que a engenharia exige), não o manual. Achado D3 da vistoria de
> 2026-08-21: a base nunca removeu o original depois de extrair.

### 26.2 Incidentes

**MUST**
- Postmortem **blameless** para todo incidente Sev1/Sev2.
- RCA (root cause analysis) documentado.
- Ações preventivas rastreáveis (issue/task) com prazo.
- Repositório central de postmortems acessível ao time.

> Piso aqui; a resposta ao incidente (severidade SEV1-4, papéis, mitigar antes de diagnosticar,
> LGPD/ANPD, postmortem e recorrência) é da `schematize-incident`
> (`schematize-incident → references/severidade.md`, `→ references/postmortem.md`).

---

---

## 27. ADR — Architecture Decision Records

Toda decisão arquitetural relevante vira ADR.

```
<projeto>/<projeto>_archive/decisoes/
  0001-use-postgresql.md
  0002-adopt-hexagonal-architecture.md
```

> **Caminho único de ADR da casa:** `<projeto>/<projeto>_archive/decisoes/`. É onde o `/docs-adr` grava, onde a `/archive-todos` procura e onde a `/audit-run` audita — o mesmo lugar nos três. Antes de 2026-08-21 havia **quatro** caminhos concorrentes (`/docs/adr/`, `docs/adr/`, `_archive/decisoes/`, `archive/adr/`), o que tornava o piso *"ADR `proposed` é órfão RED"* inexequível por construção (achado B2b).


Formato MADR. Status: `proposed`, `accepted`, `deprecated`, `superseded by NNNN`.

> **A anatomia do ADR, o ciclo e o comando são da `schematize-docs`** (`references/adr.md`,
> `/docs-adr`). Este §27 é o **contrato**: toda decisão estruturante vira ADR, no caminho único, e
> **`proposed` eterno é órfão RED** para a `schematize-audit` — decisão sem desfecho trava o
> veredito. O *como* é lá.

**Quando criar:** escolha de banco/broker/linguagem, padrão arquitetural, mudança de contrato público, qualquer desvio deste documento (exceto itens VETADO, que não admitem exceção).

---

---

## 28. Archive de Conversas e Tarefas — INEGOCIÁVEL

> **PONTEIRO.** A planta, o ciclo de vida e as ferramentas do archive são da skill dedicada
> **`schematize-archive`** (`references/archive.md`, comandos `/archive-init` e `/archive-todos`,
> e o `scripts/collect-history.sh`). Este §28 é o **contrato** — o que a engenharia exige e o que
> reprova na DoD —, não o manual. Manter os dois manuais foi o achado **D3** da vistoria de
> 2026-08-21, e foi assim que **três plantas concorrentes** do archive passaram a existir
> — a regra é "uma planta só, na schematize-archive".

**Esta seção não tem modo "pula pra ir mais rápido".** O archive é parte da entrega, não um extra.
Tarefa sem archive = **tarefa não feita** (§35).

**O contrato (o que a base exige):**

1. **O archive existe, e é obrigatório** — `<projeto>/<projeto>_archive/`, **DENTRO** do projeto,
   irmão dos diretórios de microserviço. Projeto sem archive: **criá-lo é o 1º item**, não uma
   tarefa de fim de sprint.
2. **É um REPOSITÓRIO git próprio e PRIVADO**, não uma pasta solta nem lixo gitignored. Sua função
   é a **evolução do projeto documentada** — é o `git log` dele que responde *"como o sistema
   chegou aqui"*. (O operacional volátil é o `.schematize/`, esse sim gitignored.)
3. **Todo MD gerado mora nele, nunca no root** — MAPA, índices, planos, relatórios, handoffs,
   checkpoints, ADRs. O root fica limpo: código, config e os poucos MDs de mão (`README`, `CLAUDE`,
   `LICENSE`, `CHANGELOG`, `CONTRIBUTING`, `SECURITY`, mais os que o ecossistema exige: `SKILL`,
   `AGENTS`, `CONTEXT`, `CODE_OF_CONDUCT`) — a lista é a do gate `docs-gate` da `schematize-docs`. Antes de gravar um `.md`, o caminho **começa** com
   `<projeto>/<projeto>_archive/`. Largar artefato gerado no root é violação (§37).
4. **Toda decisão/plano/handoff relevante vira arquivo durável** — nada de histórico só no chat.
   É o que a `schematize-audit` depois **cobra**: o que não está gravado não aconteceu.
5. **O archive entra no PR.** PR que produziu decisão ou mudança de estado e não trouxe o `.md`
   correspondente **não passa** na DoD (§35).

**A planta canônica** (quais pastas, o que vai em cada uma) é **uma só** e vive na
`schematize-archive` → `references/archive.md`, seção "Estrutura" — não a redefina aqui nem em
lugar nenhum (uma planta só). Rode **`/archive-init`** para materializá-la, e **`/archive-todos`** para
transformar o histórico recuperável no próximo checklist de overdev.

> **Onde este §28 divergir da `schematize-archive`, ELA manda** no *como*; aqui manda o *o quê*
> (os 5 pontos acima).

