---
description: schematize-engineering — auditoria de histórico: enumera TODOS os checklists/promessas do projeto (overdev, Q.A., handoffs, planos, ADRs, PERGUNTAS parkeadas, premature-stops) e verifica se cada item foi SANADO — acha órfãos RED (aberto nunca fechado, on-hold sem resposta, "feito" sem prova), gera checklist de saneamento e trava se sobrar órfão
argument-hint: "[dir do archive, ex: <projeto>/<projeto>_archive]"
---

Rode a **auditoria de histórico** (`references/auditoria.md`): todo checklist criado no
projeto foi **mesmo sanado**? Fecha o loop `scan → plan → refactor → overdev` provando que o
prometido foi **entregue e verificado**, não só marcado.

## 1. Enumere as fontes (e conte — `references/auditoria.md` §1)
Varra o archive `${ARGUMENTS:-<projeto>/<projeto>_archive}` **e** o histórico git:
- overdev: `.schematize/overdev/CHECKLIST.md` (ou `.overdev/CHECKLIST.md` legado), `<archive>/overdev/OBJETIVO.md`, `premature-stops.log`, `./PERGUNTAS-OVERDEV.txt`, `DECISOES.md`/`PLAN.md`;
- Q.A.: `<archive>/qa/*.md`; contexto/handoff: `<archive>/context/*-checklist.md`; plano: `<archive>/plan/*.md`; ADRs `proposed`; qualquer MD com `- [ ]`/`- [~]`/"EM ABERTO".
Cobertura: `A` auditados / `A` existentes (tem que bater).

## 2. Classifique e cruze (§2)
Por item: `- [x]` feito · `- [ ]` **órfão RED** (nunca fechado) · `- [~]` on-hold (a pergunta foi respondida? o item fechou?). Cruzamentos que pegam o buraco:
- overdev "concluído" com `- [ ]` aberto → só legítimo por budget/thrashing, e aí os itens **reaparecem** depois? sumiram = dívida esquecida;
- `premature-stops.log` → os itens que faltavam foram **eventualmente feitos**? (grep no código/testes/archive);
- pergunta parkeada em `PERGUNTAS-OVERDEV.txt` **respondida** em algum lugar?
- ADR `proposed` órfão (nunca ratificado/descartado); handoff "EM ABERTO" nunca retomado.

## 3. "Fechou de verdade" — prova, não fé (§3)
`- [x]` sem evidência é **suspeito**. Spot-check nos itens feitos de caminho crítico: existe o teste/commit/arquivo? o gate passa hoje? Item marcado-feito que não se prova **volta a aberto** no relatório (mesma disciplina do red-first).

## 4. Saída (`<projeto>/<projeto>_archive/audit/<data>.md`)
- **Cobertura** + total por estado; **Órfãos RED** (lista: aberto nunca fechado, on-hold sem resposta, pergunta pendente, ADR órfão, feito-sem-prova) com origem + o que falta.
- **Checklist de saneamento:** os órfãos viram um **novo checklist** (candidato a `/eng-overdev`) — reabrir + resolver + verificar + reteste.
- **Gate:** histórico são = **zero órfãos RED**. Qualquer aberto/hold/parkeado sem desfecho **não fecha**.

## Quando rodar
Fim de marco/entrega (antes do "pronto" macro), retomada de projeto parado, periódico em projeto ativo, e depois de um `/eng-scan` grande (os achados viraram itens fechados?).
