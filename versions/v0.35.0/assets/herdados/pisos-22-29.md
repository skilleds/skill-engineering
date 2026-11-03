<!--
FONTE ÚNICA — bloco "Herda os pisos 22–29" (texto curto e idêntico em toda skill filha).
Herdada pelas skills derivadas da schematize-engineering via `tools/sync-herdados` (obrigatório em SKILL.md e
assets/CLAUDE.md, ver tools/herdados-obrigatorios.json). Editar = editar AQUI + `tools/sync-herdados --write`.
Variantes: bloco (sem parâmetros; UMA linha). Detalhe normativo: schematize-engineering, assets/CLAUDE.md pisos 22-29.
Não escreva aqui o marcador "herdado" literal: este arquivo é a fonte, não um consumidor.
-->

<!-- variante:bloco -->
**Herda os pisos 22–29 da `schematize-engineering`** (texto completo em `assets/CLAUDE.md` dela): 22 tudo no git — sem remote, push falho ou HEAD≠origin a demanda NÃO se conclui; 23 deploy só do git (VETADO scp/rsync/tar|ssh/docker save|load/git bundle); 24 o ops é o gate da IA — a IA nunca muda a VPS direto nem escreve SQL, só operação nomeada (`ssh vps "ops <op>"`); 25 sem agents inúteis (entregou, morreu); 26 relatório a cada 30 min e handoff a cada 6 h; 27 CI remoto só antes do hml, a pedido ou em tag (`workflow_dispatch` + `hml-*`/`v*`; VETADO `pull_request`, `push` em branch, `workflow_run`, cron sem justificativa); 28 microserviço autônomo (fila durável + 7 testes de resiliência); 29 build/teste na máquina dev/hml quando existe (ponte só no workspace de build, nunca prd) + higiene (`scripts/higiene.sh`).
<!-- /variante -->
