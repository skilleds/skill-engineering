#!/usr/bin/env bash
# core-md.test.sh — guarda do núcleo sempre-on assets/CORE.md.
# O quê: falha se CORE.md passar de 4096 bytes, de 60 linhas, ou faltar o marcador de versão
#   `<!-- schematize-core vX.Y.Z -->` igual ao arquivo VERSION.
# Saída: exit 0 se tudo ok, 1 se algum caso falhou.
# strict-ok: harness de teste — roda todos os casos e soma (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE/.."; F="$ROOT/assets/CORE.md"; rc=0
[ -f "$F" ] || { echo "core-md.test: FAIL (CORE.md ausente)"; exit 1; }
bytes=$(wc -c < "$F"); lines=$(wc -l < "$F")
[ "$bytes" -le 4096 ] || { echo "FAIL: $bytes bytes > 4096"; rc=1; }
[ "$lines" -le 60 ] || { echo "FAIL: $lines linhas > 60"; rc=1; }
v="$(tr -d '[:space:]' < "$ROOT/VERSION")"
head -1 "$F" | grep -Fxq "<!-- schematize-core v$v -->" || { echo "FAIL: marcador de versão ausente ou diferente de v$v"; rc=1; }
[ "$rc" -eq 0 ] && echo "core-md.test: OK ($bytes bytes, $lines linhas, v$v)"
exit "$rc"
