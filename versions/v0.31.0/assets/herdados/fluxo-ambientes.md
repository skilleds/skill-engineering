<!--
FONTE ÚNICA — bullet "Fluxo de ambientes e ops" (miolo comum).
Herdada pelas skills derivadas da schematize-engineering via `tools/sync-herdados.mjs`.
Editar = editar AQUI + `node tools/sync-herdados.mjs`; o CI roda --check.
Variantes: corpo (sem parâmetros).
Não escreva aqui o marcador "herdado" literal: este arquivo é a fonte, não um consumidor.
-->

<!-- variante:corpo -->
Toda mudança segue **dev local → teste local → GitHub → hml → prd**; **VETADO editar código direto no servidor** (hml/prd é imutável por edição manual, recebe só artefato do git). **100%** das operações no servidor (install/update/correção/config/migrate/rollback) passam pela **ferramenta do `<projeto>_ops`** — nunca à mão; o ops é **autônomo** (o usuário provisiona o servidor do zero sem a IA). **Instalação sempre paralela** = `nproc`; **falha no paralelo = serviços não independentes → corrigir a independência é prioridade máxima** (não serializar pra mascarar).
<!-- /variante -->

