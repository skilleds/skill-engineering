#!/usr/bin/env bash
# check-build-host.test.sh — vermelho/verde do gate check-build-host.sh (piso 29).
# strict-ok: harness de teste — roda todos os casos e soma (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; G="$HERE/check-build-host.sh"; rc=0
T="$(mktemp -d)"; trap 'rm -rf "${T:?}"' EXIT
mk() {  # mk <env> <workspace> [papel] [ponte]
  printf 'maquinas:\n  - nome: build-1\n    host: 10.0.0.5\n    env: %s\n    papel: %s\n    ponte_direta: %s\n    workspace: %s\n    limite_disco_pct: 80\n    limite_cpu: 4\n' \
    "$1" "${3:-build-teste}" "${4:-true}" "$2" > "$T/m.yml"; }
mk dev /var/tmp/schematize-build/proj/; bash "$G" "$T/m.yml" >/dev/null || { echo "FAIL: válido deveria passar"; rc=1; }
mk hml /srv/build/proj; bash "$G" "$T/m.yml" >/dev/null || { echo "FAIL: hml válido deveria passar"; rc=1; }
for e in prd staging stg ""; do mk "$e" /var/tmp/b/p; bash "$G" "$T/m.yml" >/dev/null 2>&1 && { echo "FAIL: env='$e' deveria reprovar"; rc=1; }; done
for w in / /etc/x/y /var relativo /home/tom /var/tmp/../etc/x; do mk dev "$w"; bash "$G" "$T/m.yml" >/dev/null 2>&1 && { echo "FAIL: workspace '$w' deveria reprovar"; rc=1; }; done
mk dev /var/tmp/b/p outro true; bash "$G" "$T/m.yml" >/dev/null 2>&1 && { echo "FAIL: papel errado deveria reprovar"; rc=1; }
mk dev /var/tmp/b/p build-teste false; bash "$G" "$T/m.yml" >/dev/null 2>&1 && { echo "FAIL: ponte_direta false deveria reprovar"; rc=1; }
printf 'maquinas: []\n' > "$T/m.yml"; bash "$G" "$T/m.yml" >/dev/null 2>&1 && { echo "FAIL: sem máquinas deveria reprovar"; rc=1; }
printf 'maquinas:\n  - nome: a\n    host: h\n' > "$T/m.yml"; bash "$G" "$T/m.yml" >/dev/null 2>&1 && { echo "FAIL: campos faltando deveria reprovar"; rc=1; }
bash "$G" "$T/nao-existe" >/dev/null 2>&1; [ $? -eq 2 ] || { echo "FAIL: arquivo ausente deveria dar rc 2"; rc=1; }
[ "$rc" -eq 0 ] && echo "check-build-host.test: OK"
exit "$rc"
