#!/usr/bin/env bash
# core-md.test.sh — guarda do núcleo sempre-on assets/CORE.md.
# O quê: falha se CORE.md passar de 3846 bytes (folga >= 250 sob o teto de 4096), de 55 linhas, ou faltar o
#   marcador de versão `<!-- schematize-core vX.Y.Z -->` igual ao arquivo VERSION (ou ao topo do CHANGELOG, release pendente); e chama
#   `check-fidelidade.sh` (cada piso 13, 18-29 representado com seu veto-chave).
# Saída: exit 0 se tudo ok, 1 se algum caso falhou.
# strict-ok: harness de teste — roda todos os casos e soma (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE/.."; F="$ROOT/assets/CORE.md"; rc=0
[ -f "$F" ] || { echo "core-md.test: FAIL (CORE.md ausente)"; exit 1; }
bytes=$(wc -c < "$F"); lines=$(wc -l < "$F")
[ "$bytes" -le 3846 ] || { echo "FAIL: $bytes bytes > 3846 (folga de 250 B sob o teto de 4096)"; rc=1; }
[ "$lines" -le 55 ] || { echo "FAIL: $lines linhas > 55"; rc=1; }
v="$(tr -d '[:space:]' < "$ROOT/VERSION")"
# marcador == VERSION, ou == a versão do topo do CHANGELOG (release pendente: o gate roda ANTES do bump)
top="$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$ROOT/CHANGELOG.md" 2>/dev/null | tr -d '#[] ')"
if head -1 "$F" | grep -Fxq "<!-- schematize-core v$v -->" || { [ -n "$top" ] && head -1 "$F" | grep -Fxq "<!-- schematize-core v$top -->"; }; then :; else echo "FAIL: marcador de versão ausente ou diferente de v$v (nem do topo do CHANGELOG)"; rc=1; fi
bash "$HERE/check-fidelidade.sh" "$ROOT" || rc=1
[ "$rc" -eq 0 ] && echo "core-md.test: OK ($bytes bytes, $lines linhas, v$v)"
exit "$rc"
