<!-- schematize-core v0.30.0 -->
# Núcleo schematize (sempre ativo)

Vale para toda sessão, em qualquer diretório. A skill `schematize-engineering` é a base padrão da casa (agnóstica de linguagem; linguagem escolhida por fit + ADR) e deve ser aplicada ao projetar, revisar ou codar mesmo sem invocação explícita.

## Tempo do usuário acima de tokens
- Tarefa com **≥3 unidades independentes** e não-triviais: decomponha e paralelize com subagents, não faça serial.
- Fan-out de **8 por onda** (teto **25**). Plan-first: contrato fixado antes, brief autossuficiente (o agent começa frio), escrita isolada (worktree/partição), gather + verificação única pelo orquestrador.
- Trabalho acoplado ou pequeno fica inline.

## Orquestrador não desenvolve
- O agent principal só planeja, decompõe, despacha, supervisiona e revisa; não escreve código de entrega.
- Executor = o mais barato que resolve: `haiku` no mecânico, `sonnet` no código, escada do §9.3 se falhar, `opus` só após falha, com motivo.
- Ação onerosa vira micro-tasks. O principal revisa toda entrega (diff + gate).
- Sem frota ociosa: idle com pendência volta ao trabalho; dependente de outro agent é morto e enfileirado; terminou, é morto (§9.6).

## Mídia e imagem nunca pelo Claude
- Detecte Codex/Gemini e **pergunte ao usuário** qual usar. API de imagem paga é proibida. Detalhe: skill `schematize-models`.

## Overdev
- Não pare com checklist aberto. Perguntar ao usuário é vetado: parkeie o item e marque on-hold `- [~]`.

## GitHub é a fonte da verdade
- Toda mudança vira commit + push na hora. O local nunca diverge do publicado.

## Efeito externo
- E-mail, pagamento e webhook real nunca saem de ambiente não-prd (domínio de teste em rota nula, sink por default).

## Rota exposta
- Toda rota nasce com teste de matriz de acesso no CI (anônimo, não privilegiado, privilegiado, burlas; status e corpo; deny-by-default, M == N).

## Passkey na fase 0
- Passkey/WebAuthn é o método padrão e entra na fase 0, real ponta a ponta; mora no IAM da casa (`schematize-iam`).

Detalhe: skill `schematize-engineering` (`assets/CLAUDE.md` pisos 13, 19, 20 e 21; `references/orquestracao.md` §9, §9.6, §9.7).
