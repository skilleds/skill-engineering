# schematize-engineering

> A **base comum de engenharia da casa** — agnóstica de linguagem. Arquitetura/DDD, MAPA+grafo+endpoints, segurança, dados/eventos, cadeia de suprimentos, observabilidade, operação/DoD/archive e anti-padrões. As demais skills (linguagens, web, mobile, QA, pentest etc. — catálogo completo no comando `/schematize-help`) **especializam** esta base. Pacote de **skill normativa para [Claude Code](https://claude.com/claude-code)**. Parte do catálogo **schematize skills** ([skills.schematize.me](https://skills.schematize.me)).

Use **esta** quando o projeto não é de uma linguagem específica, ou quando quer só os princípios da casa. Use a **irmã de linguagem** quando há stack definida (ela contém esta base + o detalhe daquela linguagem).

## Instalar

```bash
git clone https://github.com/skilleds/skill-engineering.git
cd skill-engineering && ./install.sh          # no projeto atual
# ./install.sh ~                               # global (~/.claude, todos os projetos)
```

Ou baixe o `.zip` da última release e descompacte em `.claude/skills/`:

```bash
curl -L -o schematize-engineering.zip \
  https://github.com/skilleds/skill-engineering/releases/latest/download/skill-engineering.zip
unzip schematize-engineering.zip -d .claude/skills/
```

Depois, copie a regra sempre-on: `.claude/skills/schematize-engineering/assets/CLAUDE.md` → `CLAUDE.md` (ou rode `/eng-claude`).

## Comandos

`/eng-help` · `/eng-load` · `/eng-claude` · `/eng-index` · `/eng-review` · `/eng-scan` · `/eng-plan` · `/eng-refactor` · `/eng-audit` · `/eng-orchestrate` · `/eng-overdev` · `/eng-ops` · `/eng-iam` · `/eng-cc` · `/eng-handoff` · `/eng-report`.

## Formato

Padrão aberto Agent Skills. Funciona em Claude Code, Claude.ai e API.
