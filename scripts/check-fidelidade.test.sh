#!/usr/bin/env bash
# check-fidelidade.test.sh — vermelho/verde do check-fidelidade.sh (CORE ↔ pisos).
# strict-ok: harness de teste — roda todos os casos e soma (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; G="$HERE/check-fidelidade.sh"; rc=0
T="$(mktemp -d)"; trap 'rm -rf "${T:?}"' EXIT
mkdir -p "$T/assets"; cp "$HERE/../assets/CLAUDE.md" "$HERE/../assets/CORE.md" "$T/assets/"
bash "$G" "$T" >/dev/null 2>&1 || { echo "FAIL: skill real deveria passar"; rc=1; }
muda() { # nome, sed-expr no CORE, trecho esperado
  cp "$HERE/../assets/CORE.md" "$T/assets/CORE.md"; sed -i "$2" "$T/assets/CORE.md"
  out="$(bash "$G" "$T" 2>&1)" && { echo "FAIL: '$1' deveria reprovar"; rc=1; return; }
  grep -q -- "$3" <<<"$out" || { echo "FAIL: '$1' sem '$3' em: $out"; rc=1; }
}
muda "CORE sem git bundle" 's/git bundle, //' "git bundle"
muda "CORE sem DLQ" 's/DLQ, //' "DLQ"
muda "CORE sem kill-switch" 's/, kill-switch//' "kill-switch"
muda "CORE sem workflow_run" 's/`workflow_run`, //' "workflow_run"
muda "CORE sem .ritmo.json" 's/`\.ritmo\.json`/o carimbo/' ".ritmo.json"
muda "CORE com frase obsoleta" 's/^- Gate por commit é LOCAL/- Check obrigatório no PR. Gate por commit é LOCAL/' "obsoleta"
muda "linha final sem pisos" 's/pisos 13, 18-29/pisos 13/' "linha final"
# âncora velha na fonte: remove 'kill-switch' do piso 24 da FONTE
cp "$HERE/../assets/CORE.md" "$T/assets/CORE.md"; sed -i '/^24\. /s/kill-switch/chave geral/g' "$T/assets/CLAUDE.md"
out="$(bash "$G" "$T" 2>&1)" && { echo "FAIL: âncora sumida da fonte deveria reprovar"; rc=1; }
grep -q "sumiu da fonte" <<<"$out" || { echo "FAIL: sem aviso de fonte"; rc=1; }
[ "$rc" -eq 0 ] && echo "check-fidelidade.test: OK"
exit "$rc"
