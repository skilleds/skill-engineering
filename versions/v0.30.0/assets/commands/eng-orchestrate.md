---
description: schematize-engineering — decompõe a tarefa em mini-tasks independentes e paraleliza com subagents (plan-first); otimiza tempo de relógio sobre tokens
argument-hint: "[a tarefa a paralelizar]"
---

Planeje a execução **paralela** da tarefa (`references/orquestracao.md`). Padrão da casa: **tempo do usuário acima de tokens** — se dá pra dividir sem colidir, divide e paraleliza. **Nada dispara antes da aprovação.**

Tarefa: **${ARGUMENTS:-(descreva a tarefa)}**

## 1. Decida se paraleliza

- Liste as **unidades de trabalho**. Marque quais são **independentes** (sem alvo de escrita compartilhado, sem ordem obrigatória entre si).
- **Regra:** ≥3 unidades independentes e não-triviais → **fan-out**. Menos, ou acoplado/sequencial → **inline** (e diga por quê, honestamente — não paralelize por paralelizar).

## 2. Fixe o contrato ANTES (plan-first)

Se o desenho não está fechado, decida agora: interfaces/nomes, formato de saída, convenções, e o **critério de "pronto"** por unidade. Agents divergem sem contrato.

## 3. Monte o plano de fan-out (MD)

- **Papéis (§9):** você (orquestrador) **só planeja, despacha e revisa — não desenvolve**. Toda ação onerosa vira **micro-tasks** para subagent barato, mesmo com <3 unidades (o fan-out decide *paralelizar*; a §9 decide *quem executa*).
- **Mostre no plano, por unidade, o motor/modelo (papel):** mecânico → `haiku`; código → `sonnet`; **visual → Codex `gpt-5.6-terra` direto**; imagem → nunca pelo Claude: detectar Codex/Gemini e PERGUNTAR ao usuário qual usar, Codex sugerido (API de imagem paga PROIBIDA). E a **escada**: falhou → mesmo subagent corrige (até 2 rodadas) → Codex Terra → Cursor (se instalado) → subagent `opus` (motivo no checkpoint) → `park`/`- [~]`. Codex/Cursor via `schematize overdev delegar --papel <p> --brief-stdin --json` (rc 3 → `proximo`); sem overdev: `codex exec -m gpt-5.6-terra -s workspace-write --json -C <dir> "<brief>"`. Papéis em `agentes.toml` (`orquestracao.md` §9.3).
- **Ondas de até 8** subagents (teto global 25; acima de 8, ondas sequenciais de 8).
- Por agent: **brief autossuficiente** (contexto + caminhos absolutos + contrato + critério de pronto — ele começa frio, não vê esta conversa).
- **Isolamento de escrita:** se tocam o mesmo repo, `isolation: "worktree"` ou partição por diretório/arquivo sem cruzar.
- Marque passos **destrutivos/arriscados** com **gate humano**.
- Defina o passo de **gather**: como você (orquestrador) junta, integra e **verifica uma vez** (build/test/publish), paralelizando a verificação quando dá.

## 4. Grave o checkpoint no archive — ANTES de disparar (à prova de crash, proporcional)

**Obrigatório se ≥ 5 unidades, OU duração estimada > 15 min, OU qualquer overdev, OU publicação/efeito irreversível no meio** (`orquestracao.md` §7). Abaixo disso basta a tabela de status (unidades, motor, modelo, rodadas, resultado) no relato final; a regra de retomada não se aplica — refazer é mais barato que registrar. Acima do limiar, antes de qualquer agent rodar, escreva **`<projeto>/<projeto>_archive/orchestration/<YYYY-MM-DD-HH-MM-SS>-<tarefa>.md`** (`references/orquestracao.md` §7): o contrato, as unidades e uma **tabela de status** (`PENDENTE/EM ANDAMENTO/FEITO/FALHOU`) com **modelo** (`sonnet`/`opus`), **rodadas de correção** e o caminho do resultado de cada uma. **Instrua cada subagent a gravar o próprio resultado** em `…/orchestration/<tarefa>/<unidade>.md` (não só retornar pelo evento — evento é efêmero). O estado nunca vive só no chat: se travar, retoma-se **lendo este MD**.

## 5. Peça aprovação

Mostre o plano (unidades × agents, ondas, custo aproximado, gate). **Só após "ok"** dispare a onda 1. **A cada onda que fecha, atualize a tabela de status** no checkpoint. Retomada = ler o checkpoint e rodar só `PENDENTE/FALHOU` (sem retry infinito; falhou 2× → gate humano). **Cada entrega é revisada por você (diff + gate) e, se falhar, devolvida ao subagent — você não corrige com a própria mão** (exceto a exceção estreita da §9.1). Achado crítico pausa e reporta.
**A cada onda que fecha, varredura de ociosos (§9.6):** idle com pendência executável → reuse (SendMessage); pendência que depende de outro agent → mate (`TaskStop`) e enfileire com gatilho de dependência (`BLOQUEADA`); terminou → mate. Sem frota ociosa.

## 6. Consolide

Junte os resultados, rode a verificação única, marque tudo `FEITO` no checkpoint, e **grave o archive** (§28) com a decomposição e o resultado consolidado — em `<projeto>/<projeto>_archive/orchestration/`, **nunca no root**. Confirme ao usuário: unidades feitas, ondas, verde da verificação.
