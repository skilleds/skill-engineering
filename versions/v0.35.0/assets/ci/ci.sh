#!/usr/bin/env bash
# ci.sh — gate LOCAL por commit do projeto (piso 27: custo zero; o CI remoto NÃO roda por commit nem por PR).
# Copie para <projeto>/tools/ci.sh e instale como pre-push: `ln -sf ../../tools/ci.sh .git/hooks/pre-push`.
# Roda os gates da schematize-engineering que valem para qualquer stack; acrescente os da sua linguagem
# (lint/teste da stack) no fim. Sai 0 só se TUDO passar; um gate que não pode rodar (script ausente) REPROVA.
# Env: ENG_SCRIPTS (default .claude/skills/schematize-engineering/scripts), BASE (default HEAD = o que está staged),
#      RITMO_ARCHIVE (dir <projeto>_archive; liga o gate do ritmo), RESILIENCE_DIRS (dirs com resilience.yml).
# strict-ok: coletor — roda todos os gates e soma (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
S="${ENG_SCRIPTS:-.claude/skills/schematize-engineering/scripts}"; BASE="${BASE:-HEAD}"; rc=0
gate() { # nome, comando...
  local n="$1"; shift
  [ -f "$S/$1" ] || { echo "✖ $n: $S/$1 ausente (gate desarmado reprova)"; rc=1; return; }
  echo "▶ $n"; bash "$S/$1" "${@:2}" || { echo "✖ $n"; rc=1; }
}
gate "padrões no diff (§35/§37)" check-diff.sh "$BASE"
gate "segredo/PII no archive (§16.1/§32)" archive-secret-scan.sh .
gate "efeito externo fora de prd (piso 18)" check-external-effects.sh .
gate "deploy só do git / ops é o gate (pisos 22-24)" check-deploy-git.sh .
gate "gatilhos de CI (piso 27)" check-ci-triggers.sh .
[ -z "${INDEX_FILE:-}" ] || gate "índice de funcionalidades (§39)" check-index.sh
[ -z "${RITMO_ARCHIVE:-}" ] || gate "ritmo de registro (piso 26)" check-ritmo.sh "$RITMO_ARCHIVE"
for d in ${RESILIENCE_DIRS:-}; do gate "resiliência do microserviço $d (piso 28)" check-resilience.sh "$d"; done
# >>> gates da sua stack aqui (lint, testes unitários, matriz de acesso por rota — piso 20) <<<
[ "$rc" -eq 0 ] && echo "ci.sh local: OK" || echo "ci.sh local: FALHOU"
exit "$rc"
