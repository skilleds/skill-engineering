# Auditoria de histórico — PONTEIRO para a `schematize-audit`

> **A disciplina inteira mora na skill dedicada: `schematize-audit`.** Este arquivo era uma
> segunda normativa do mesmo tema (71 linhas contra 406 de references de lá) — e as duas **já
> estavam divergindo** (esta mandava auditar `assets/ADR.md`, que é o *template* da skill, não
> artefato de projeto). Duas normativas do mesmo assunto não são redundância: são **duas
> respostas diferentes** para a mesma pergunta, e quem lê só uma não sabe disso.
> Achado D3 da vistoria de 2026-08-21.

## O que a base exige (e só isso)

A engenharia da casa exige que **todo checklist criado seja sanado, com prova** — não apenas
marcado. É o mesmo red-first do teste: `- [x]` cujo teste/commit/arquivo/gate **não passa hoje**
volta a `- [ ]`. Suspeito ≠ feito; alegação em CHANGELOG ≠ prova.

Isso entra na **DoD (§35)** e fecha o laço do **overdev** (`references/overdev.md`): o overdev
garante que a *sessão viva* não para com item aberto; a auditoria garante que *nenhum item aberto
ficou órfão no histórico*.

## Como se faz — na `schematize-audit`

| O quê | Onde |
|---|---|
| A disciplina (enumeração exaustiva por contagem, órfão RED, cobertura A/A) | `schematize-audit` → `references/auditoria.md` |
| Metodologia (plan-first, contagem, JSON, gate, CI/agendado) | `schematize-audit` → `references/metodologia.md` |
| O que conta como **prova** (+ spot-check e reabertura) | `schematize-audit` → `references/evidencias.md` |
| Anatomia do relatório, veredito e onde gravar | `schematize-audit` → `references/relatorio.md` |
| Comandos | `/audit-plan` → `/audit-run` → `/audit-report` |

**Fontes que a auditoria varre** (para não repetir a lista aqui: ela é mantida lá) — overdev
(`CHECKLIST`/`OBJETIVO`/`premature-stops`/perguntas parkeadas/`DECISOES`/`PLAN`), Q.A. plan-first,
handoffs de contexto em `<projeto>_archive/context/` **e** `chats/`, planos do `/eng-plan`, **ADRs
`proposed`** em `<projeto>/<projeto>_archive/decisoes/` (caminho único `ADR-NNNN-<slug>.md` em `decisoes/`), e qualquer MD
do archive com `- [ ]` / `- [~]` / "EM ABERTO".

> **Onde este arquivo divergir da `schematize-audit`, ELA manda.** Aqui só fica o que a base
> exige; o *como* é dela.
