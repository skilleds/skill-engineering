#!/usr/bin/env bash
# check-ci-triggers.test.sh — vermelho/verde do gate check-ci-triggers.sh (piso 27).
# strict-ok: harness de teste — roda todos os casos e soma (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; G="$HERE/check-ci-triggers.sh"; rc=0
T="$(mktemp -d)"; trap 'rm -rf "${T:?}"' EXIT
CONC=$'concurrency:\n  group: ci-${{ github.ref }}\n  cancel-in-progress: true\n'
nega() { # nome, conteúdo, trecho esperado na saída
  printf '%s' "$2" > "$T/w.yml"
  out="$(bash "$G" "$T/w.yml" 2>&1)" && { echo "FAIL: '$1' deveria reprovar"; rc=1; return; }
  grep -q "$3" <<<"$out" || { echo "FAIL: '$1' sem a mensagem '$3'"; rc=1; }
}
passa() {
  printf '%s' "$2" > "$T/w.yml"
  bash "$G" "$T/w.yml" >/dev/null 2>&1 || { echo "FAIL: '$1' deveria passar"; rc=1; }
}
nega "push em branch" $'name: x\non:\n  push:\n    branches: [main]\n'"$CONC" "push em branch"
nega "push puro" $'name: x\non:\n  push:\n  workflow_dispatch:\n'"$CONC" "push em branch"
nega "inline push" $'name: x\non: [push, workflow_dispatch]\n'"$CONC" "push em branch"
nega "pull_request sem filtro" $'name: x\non:\n  pull_request:\n  workflow_dispatch:\n'"$CONC" "pull_request sem filtro"
nega "sem concurrency" $'name: x\non:\n  workflow_dispatch:\n' "concurrency"
nega "concurrency sem cancel" $'name: x\non:\n  workflow_dispatch:\nconcurrency:\n  group: a\n' "concurrency"
nega "cron sem justificativa" $'name: x\non:\n  schedule:\n    - cron: "0 6 * * 1"\n'"$CONC" "justificativa"
passa "dispatch + tags" $'name: x\non:\n  workflow_dispatch:\n  push:\n    tags: ["hml-*", "v*"]\n'"$CONC"
passa "pr com filtro" $'name: x\non:\n  pull_request:\n    branches: [main]\n    paths-ignore: ["**.md"]\n  workflow_dispatch:\n'"$CONC"
passa "cron justificado" $'# justificativa: deriva semanal acordada em ADR-9\nname: x\non:\n  schedule:\n    - cron: "0 6 * * 1"\n'"$CONC"
# comentário não conta como gatilho
passa "push só em comentário" $'name: x\non:\n  workflow_dispatch:\n  # push:\n'"$CONC"
# dir sem workflows = nada a checar
mkdir -p "$T/vazio"; bash "$G" "$T/vazio" >/dev/null 2>&1 || { echo "FAIL: dir vazio deveria passar"; rc=1; }
# o template da casa precisa passar
bash "$G" "$HERE/../assets/ci/github-actions-ci.yml" >/dev/null 2>&1 || { echo "FAIL: template assets/ci/github-actions-ci.yml reprovado"; rc=1; }
[ "$rc" -eq 0 ] && echo "check-ci-triggers.test: OK"
exit "$rc"
