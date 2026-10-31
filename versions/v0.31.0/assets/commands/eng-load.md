---
description: schematize-engineering — carrega à força TODO o corpo normativo (DDD/arquitetura, clean code, segurança, dados, testes, operação) no contexto e passa a aplicá-lo no projeto atual como regra inegociável
---

Carregue **à força** e passe a aplicar **integralmente** os Padrões de Engenharia da Casa (skill `schematize-engineering`) neste projeto. A partir de agora, nesta sessão, isto **não é opcional**.

1. **Leia agora, na íntegra, TODOS os arquivos** de references da skill — não trabalhe de memória, abra cada arquivo. O caminho é `.claude/skills/schematize-engineering/references/*.md` (instalação no projeto) ou `~/.claude/skills/schematize-engineering/references/*.md` (instalação global). Com destaque para:
   - `padroes-codigo.md` — **clean code**: arquivo ≤750 linhas (~500 úteis + ~250 comentário; flag >300 úteis, ~400 obs), uma função/unidade por arquivo, doc-comment obrigatório (motivo/comportamento/I-O), `MAPA.md`.
   - `linguagens.md` — **escolha de linguagem**: rol sancionado (Go/Rust/Elixir/C#/Zig/Ruby) + guia de fit por problema; Node-backend/PHP em saída; o piso é o mesmo em todas (a linguagem muda o "como", não o "o quê").
   - `arquitetura.md` — **DDD**, camadas, repositórios, bounded contexts, anti-monólito, shared libs, CQRS.
   - `seguranca.md` — auth/JWT, multi-tenancy, LGPD, segredo nunca no cliente, SQL parametrizado.
   - `dados-eventos.md` — eventos/mensageria, banco, cache, APIs, resiliência, jobs.
   - `cadeia-suprimentos.md` — lockfile, SBOM, scan que trava, imagem mínima/pinada/assinada, SLSA.
   - `testes.md` — **ponteiro**: testes/Q.A. viraram a skill dedicada `schematize-qa` (pirâmide, "verde de verdade", a11y/visual, contrato/dados, flaky, cobertura, plan-first `/qa-plan`); a engenharia mantém só o piso "a DoD exige testes verdes".
   - `observabilidade.md` — healthchecks, performance, FinOps.
   - `operacao.md` + `entrega.md` — config, deploy/K8s, git/PR, runbooks, ADR, **archive**, DoD, índice.
   - `ops.md` — **control plane `<projeto>_ops`**: fluxo dev→local→github→hml→prd (nada direto no servidor), ops como interface única (100%, autônomo), instalação paralela=`nproc`, independência=invariante (prioridade máxima).
   - `iam.md` — **IAM da casa**: auth como app separada (`auth.<domain>`), ID≠email, ≥2 fatores (passkey/Resend/Twilio), ReBAC multi-tenant deny-default, sessão longa 7d/90d, logout irreversível, migração de legado prioridade 0.
   - `overdev.md` — **modo desenvolvimento contínuo** (`/eng-overdev`): Fase 0 (colher decisões acordadas → grafo do index → planejamento pesado → checklist) + Stop hook que rejeita parada prematura; só termina com tudo `- [x]` e gate verde. Opt-in, inerte fora de um run.
   - `scan.md` — **scan de problemas** (`/eng-scan`): varredura ampla da base por todas as classes (correção, §37, pisos de código, duplicação/morto, testes, concorrência, dados, supply chain, dívida, deriva de índice), exaustiva + fan-out, suspeito≠achado, cada achado com arquivo:linha+conserto.
   - `planejamento.md` — **planejamento extensivo** (`/eng-plan`): entender→escopo→spikes→decompor no grafo→risco/rollback→ADR→paralelização→fases; plano no archive, deriva checklist, pede aprovação.
   - `refactor.md` — **refactor disciplinado** (`/eng-refactor`): muda a forma sem mudar o comportamento; rede de testes ANTES (red-first/characterization), passos pequenos reversíveis, escopo-diff, catálogo seguro, gate de contrato idêntico.
   - `auditoria.md` — **auditoria de histórico** (`/eng-audit`): todo checklist criado foi sanado? enumera overdev/QA/handoff/plano/ADR/perguntas, acha órfãos RED, "feito" sem prova volta a aberto, gera saneamento, trava se sobrar.
   - `orquestracao.md` — **tempo do usuário acima de tokens**: decompor em mini-tasks e paralelizar com subagents (fan-out 8/onda, teto 25), isolamento, gather/verificação única, plan-first.
   - `anti-padroes.md` — a lista completa de anti-padrões vetados (§37).
   - `contexto-claude-code.md` — gestão de contexto/handoff em sessões longas.

2. **Confirme ao usuário** que leu, com **1 linha por arquivo** resumindo o piso central de cada um.

3. Deste ponto em diante, **aplique estes padrões como regra inegociável** em toda decisão, geração e revisão de código deste projeto — arquitetura/DDD, clean code, segurança, testes e archive. Em conflito entre "fazer rápido" e o padrão, **o padrão vence**.

4. **Atualize o `CLAUDE.md` da raiz** do repositório com a versão atual de `assets/CLAUDE.md` da skill — **sobrescreva mesmo se já existir** (rodar não pode deixar a versão antiga). Se o `CLAUDE.md` atual tiver customização local (seções fora do template da skill), salve backup `./CLAUDE.md.bak` e reaplique as customizações por cima do template novo. Se não existir, crie. É o mesmo que o comando `/eng-claude`. Confirme a versão aplicada.
