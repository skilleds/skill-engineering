#!/usr/bin/env bash
# check-fidelidade.sh — o CORE.md (núcleo sempre-on) representa fielmente os pisos de assets/CLAUDE.md.
# O quê: para cada piso 13, 18-29 há uma lista de VETOS-CHAVE (abaixo). Cada âncora precisa existir no piso da
#   fonte (`assets/CLAUDE.md`, linha `N. `) E no `CORE.md`. Falha se: a âncora sumiu do CORE (regra perdida),
#   sumiu da fonte (âncora velha: atualize a tabela), ou o CORE traz frase obsoleta (ex.: "pull_request sem filtro").
#   Também exige a linha final do CORE citar os pisos cobertos.
# Uso: bash scripts/check-fidelidade.sh [raiz-da-skill]   (default: pai de scripts/)   Saída: 0 ok, 1 achado, 2 uso.
# strict-ok: gate acumula achados e sai no fim (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="$ROOT/assets/CLAUDE.md"; CORE="$ROOT/assets/CORE.md"
[ -f "$SRC" ] && [ -f "$CORE" ] || { echo "uso: check-fidelidade.sh [raiz da skill com assets/CLAUDE.md e assets/CORE.md]" >&2; exit 2; }
# piso | âncoras separadas por ';' (texto literal, sem regex). A âncora vale se aparece (case-insensitive) no trecho.
TABELA='13|8 por onda;25
18|SMS;push;sink;cap por execução
19|haiku;sonnet;opus
20|matriz;deny-by-default
21|Passkey;fase 0
22|NÃO se conclui;HEAD == origin
23|scp;rsync;docker save;git bundle
24|nunca;SQL;append-only;kill-switch;rate-limit
25|ListAgents
26|30 min;6 h;.ritmo.json
27|pull_request;workflow_run;workflow_dispatch;cancel-in-progress;paths-ignore
28|durável;DLQ;trace_id;idempot;M == N
29|maquinas.yml;higiene.sh;não é promovível;workspace'
OBSOLETAS='pull_request sem filtro;CI verde no PR;check obrigatório no PR'
rc=0
piso() { # N -> texto do piso N na fonte (linha "N. ..." até a próxima linha numerada)
  awk -v n="$1" '$0 ~ "^" n "\\. " {p=1; print; next} p && /^[0-9]+\. / {exit} p && /^## / {exit} p {print}' "$SRC"
}
tem() { grep -qiF -- "$2" <<<"$1"; }
CORE_TXT="$(cat "$CORE")"
while IFS='|' read -r n ancoras; do
  [ -n "$n" ] || continue
  txt="$(piso "$n")"
  [ -n "$txt" ] || { echo "FAIL: piso $n não encontrado em assets/CLAUDE.md"; rc=1; continue; }
  IFS=';' read -ra A <<<"$ancoras"
  for a in "${A[@]}"; do
    tem "$txt" "$a" || { echo "FAIL: âncora '$a' do piso $n sumiu da fonte (assets/CLAUDE.md) — atualize a tabela do check-fidelidade"; rc=1; }
    tem "$CORE_TXT" "$a" || { echo "FAIL: CORE.md perdeu '$a' (piso $n) — a regra não está representada"; rc=1; }
  done
done <<<"$TABELA"
IFS=';' read -ra OB <<<"$OBSOLETAS"
for o in "${OB[@]}"; do tem "$CORE_TXT" "$o" && { echo "FAIL: CORE.md traz frase obsoleta '$o'"; rc=1; }; done
tail -n 3 "$CORE" | grep -Eq 'pisos 13, 18-29' || { echo "FAIL: linha final do CORE.md deve citar 'pisos 13, 18-29'"; rc=1; }
[ "$rc" -eq 0 ] && echo "check-fidelidade: OK (CORE.md ↔ pisos 13, 18-29)"
exit "$rc"
