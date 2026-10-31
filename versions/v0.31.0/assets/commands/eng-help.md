---
description: schematize-engineering — lista todos os comandos disponíveis e o que cada um faz
---

Mostre ao usuário a lista de comandos do conjunto **schematize-engineering**, em formato
de tabela legível, exatamente com este conteúdo (ajuste se houver comandos novos
instalados em `.claude/commands/`):

| Comando | O que faz |
|---|---|
| `/schematize-help` | **Índice ÚNICO de TODAS as skills** (todas as skills da casa) — o que cada comando faz, num lugar só. |
| `/eng-help` | Lista todos os comandos do schematize-engineering (este). |
| `/eng-load` | **Carrega à força TODO o corpo normativo** (DDD/arquitetura, clean code, segurança, dados, testes, operação) no contexto e passa a aplicá-lo no projeto como regra inegociável. |
| `/eng-claude` | Cria ou **atualiza (sobrescreve)** o `CLAUDE.md` da raiz com a versão atual da skill (backup se houver customização local). |
| `/eng-cc` | Context compact: gera `context.md` + `checklist.md` em `<projeto>/<projeto>_archive/context/` e roda `/compact`. |
| `/eng-handoff` | Gera o handoff (`context.md` + `checklist.md`) **sem** compactar — ideal pra fim de sessão ou troca de tarefa. |
| `/eng-review` | Roda o gate da Definition of Done e dos anti-padrões (§35, §37): arquivo >750 linhas bloqueia / >300 úteis flag, função sem doc-comment, índice desatualizado, macaquices de segurança. |
| `/eng-scan` | **Varredura ampla** de problemas na base inteira (correção, anti-padrões, pisos de código (`references/padroes-codigo.md`), duplicação/morto, testes, concorrência, dados/API, supply chain, dívida, deriva de índice) — exaustiva por inventário, com fan-out; achado com `arquivo:linha`+severidade+conserto. |
| `/eng-plan` | **Planejamento extensivo** plan-first: entender→escopo→spikes→decompor no grafo→risco/rollback→ADR→paralelização→fases; gera o plano no archive, deriva o checklist e pede aprovação. |
| `/eng-refactor` | **Refactor disciplinado**: muda a forma sem mudar o comportamento, rede de testes ANTES (red-first/characterization), passos pequenos reversíveis, escopo-diff; gate exige mesma suíte verde + contrato idêntico + índice atualizado. |
| `/eng-audit` | **Auditoria de histórico**: enumera todos os checklists criados (overdev/QA/handoff/plano/ADR/perguntas) e verifica se foram sanados — acha órfãos RED (aberto nunca fechado, on-hold sem resposta, "feito" sem prova), gera saneamento e trava se sobrar. |
| `/eng-index` | (Re)gera o índice de microfunções (§39) a partir dos doc-comments das funções. |
| `/eng-orchestrate` | Decompõe a tarefa em mini-tasks independentes e paraleliza com subagents (plan-first): otimiza tempo de relógio sobre tokens; fan-out de 8/onda, teto 25. |
| `/eng-ops` | Audita/scaffolda o `<projeto>_ops` (interface única de operação): fluxo dev→local→github→hml→prd (nada direto no servidor), instalação paralela (`nproc`), independência dos serviços. |
| `/eng-iam` | Força/audita/scaffolda o IAM da casa (auth como app separada em `auth.<domain>`, ID≠email, ≥2 fatores, ReBAC multi-tenant, sessão longa/logout irreversível) ou porta um auth legado (prioridade 0). |
| `/eng-overdev` | Modo desenvolvimento contínuo: força um checklist exaustivo e um Stop hook **rejeita a parada** até tudo `- [x]` e o gate passar. Anti "entreguei uma micro-função e disse que terminei". Roda só quando você chama; inerte fora disso. |

Depois da tabela, diga em uma linha que **Q.A./testes agora são a skill dedicada `schematize-qa`**
(`/qa-plan`, `/qa-run`, `/qa-help` — o antigo `eng-qa` foi pra lá) e que **segurança ofensiva é a
`schematize-pentest`**. Diga também que o detalhe normativo está na skill `schematize-engineering`
(referências em `references/`) e que o site é `skills.schematize.me/engineering`.
