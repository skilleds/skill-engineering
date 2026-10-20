<!--
FONTE ÚNICA da regra de orquestração ("Orquestrador não desenvolve; subagent barato executa"
+ "Sem frota ociosa") herdada pelas skills derivadas da schematize-engineering.

Mecanismo: cada skill derivada envolve o CORPO do item (depois do marcador de lista) num bloco
marcado com o comentário de abertura "herdado" (skill-base/id:variante) e o de fechamento
"/herdado". O sincronizador `tools/sync-herdados.mjs` reescreve o miolo de cada bloco com a
variante correspondente deste arquivo. Editar a regra = editar AQUI + rodar
`node tools/sync-herdados.mjs`; o CI roda com --check e reprova divergência.

Variantes (cada uma delimitada por variante:NOME ... /variante, conteúdo em UMA linha):
  longo  — item do CLAUDE.md das skills grandes (sem o número do item)
  curto  — item das skills pequenas / gates textuais
  bullet — bullet do SKILL.md

Não escreva aqui o marcador "herdado" literal: este arquivo é a fonte, não um consumidor.
-->

<!-- variante:longo -->
**Orquestrador não desenvolve; subagent barato executa.** O agent principal (o que fala com o humano, Claude Opus) **só planeja, decompõe, despacha, supervisiona e revisa** — não escreve código de entrega. Toda ação onerosa é quebrada em **micro-tasks/micro-funções** executáveis por agent barato (mesmo com <3 unidades: em série, por subagents, nunca inline no principal). Principal = **Claude Opus** (só orquestra). Roteamento: mecânico/muito simples → **`haiku`**; código → **`sonnet`** (falhou → o **mesmo subagent corrige**, até 2 rodadas) → **Codex `gpt-5.6-terra`** → **Cursor** (`cursor-agent`, se instalado) → **subagent `opus`** (motivo no checkpoint) → `park` + `- [~]`; escala **só quando o mais barato falhar**. **Visual (UI/layout/CSS/tema/ícone) vai direto ao Codex** (Claude é fraco em visual); **imagem nunca pelo Claude: detectar Codex/Gemini e PERGUNTAR ao usuário qual usar (Codex, cota da assinatura, é a sugestão — não automático) — PROIBIDO endpoint/API de imagem pago.** Estrutura configurável em `agentes.toml` (global `~/.claude/schematize/agentes.toml` + override por projeto) e na aba "Agentes" do overdev; Codex/Cursor via `schematize overdev delegar --papel <p> --brief-stdin --json` (rc 3 = indisponível → `proximo`). O principal revisa toda entrega (diff + gate) e **só corrige com a própria mão se necessário** (trivial, 1–2 linhas). No overdev, **cada item do checklist é executado pelo agente do papel adequado (default subagent `sonnet`)** e revisado pelo principal antes do `- [x]`; escalar não é pergunta, esgotou a escada → `park`. **Sem frota ociosa:** agent idle com pendência executável volta ao trabalho; pendência que depende de outro agent → mata e enfileira com gatilho de dependência; terminou → mata (§9.6). Detalhe em `schematize-engineering` → `references/orquestracao.md` §9.
<!-- /variante -->

<!-- variante:curto -->
**Orquestrador não desenvolve; subagent barato executa.** O agent principal só planeja, despacha e revisa; ação onerosa vira micro-tasks para o executor mais barato que resolve: `haiku` (mecânico) / `sonnet` (código; falhou → mesmo subagent corrige, até 2 rodadas) → Codex `gpt-5.6-terra` → Cursor → subagent `opus` (motivo) → `park`; **visual vai direto ao Codex**; **imagem nunca pelo Claude: detectar Codex/Gemini e perguntar ao usuário qual usar (Codex é a sugestão), nunca API de imagem paga**; papéis em `agentes.toml`. No overdev, cada item do checklist vai a um subagent e o principal revisa antes do `- [x]`. **Sem frota ociosa:** idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata (§9.6). Detalhe: `schematize-engineering` → `references/orquestracao.md` §9.
<!-- /variante -->

<!-- variante:bullet -->
**Orquestrador não desenvolve; subagent barato executa** (`schematize-engineering` → `references/orquestracao.md` §9). O principal só planeja/decompõe/despacha/supervisiona/revisa; ação onerosa vira micro-tasks; principal = Claude Opus; executor mais barato que resolve: `haiku` (mecânico) / `sonnet` (código, até 2 rodadas de correção pelo mesmo subagent) → Codex `gpt-5.6-terra` → Cursor → subagent `opus` (motivo no checkpoint) → `park`; **visual direto ao Codex; imagem nunca pelo Claude (pergunta ao usuário: Codex sugerido, ou Gemini), API de imagem paga PROIBIDA**; papéis configuráveis em `agentes.toml` (aba "Agentes" do overdev). No `overdev`, cada item do checklist é executado pelo papel adequado e revisado pelo principal (diff + gate) antes do `- [x]`. **Sem frota ociosa:** agent idle com pendência executável volta ao trabalho; pendência que depende de outro agent → mata e enfileira com gatilho de dependência; terminou → mata (§9.6).
<!-- /variante -->
