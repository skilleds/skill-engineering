#!/usr/bin/env bash
# check-deploy-git.sh — gate dos pisos 22/23 (tudo no git; deploy só do git).
# O quê: (1) falha se `scp`/`rsync` para host remoto (`host:`/`user@host:`) ou `tar|ssh`,
#   `docker save|load` por ssh aparecerem em scripts de deploy/CI/ops; (2) se o dir é repo git,
#   falha sem remote, com árvore suja ou com commits por empurrar (HEAD != upstream).
# Uso: bash scripts/check-deploy-git.sh [dir]   (default: .)   SKIP_GIT=1 pula a parte (2).
# Saída: exit 0 ok, 1 se achou violação. Ver `references/ops.md` §1/§8 e CLAUDE.md pisos 22/23.
# strict-ok: gate acumula achados e sai no fim (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
D="${1:-.}"; rc=0
PAT='(^|[;&|[:space:]])(scp|rsync)[[:space:]][^#]*[[:alnum:]_.-]+@?[[:alnum:]_.-]*:[^[:space:]]|tar[[:space:]][^#]*\|[[:space:]]*ssh|docker[[:space:]]+(save|load)[^#]*(ssh|\|)'
while IFS= read -r f; do
  if grep -nE "$PAT" "$f" | grep -v 'check-deploy-git: ok' >/tmp/.cdg.$$ 2>/dev/null && [ -s /tmp/.cdg.$$ ]; then
    echo "FAIL: $f envia código ao servidor fora do git (piso 23):"; sed 's/^/  /' /tmp/.cdg.$$; rc=1
  fi
done < <(find "$D" -type f \( -name '*.sh' -o -name '*.yml' -o -name '*.yaml' -o -name 'Makefile' -o -name 'justfile' \) \
  -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/versions/*' -not -path '*/references/*' \
  -not -name 'check-deploy-git*' 2>/dev/null)
rm -f /tmp/.cdg.$$
if [ -z "${SKIP_GIT:-}" ] && git -C "$D" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  [ -n "$(git -C "$D" remote -v)" ] || { echo "FAIL: sem remote (piso 22)"; rc=1; }
  [ -z "$(git -C "$D" status --porcelain)" ] || { echo "FAIL: árvore suja (piso 22)"; rc=1; }
  if up=$(git -C "$D" rev-parse --abbrev-ref '@{u}' 2>/dev/null); then
    [ "$(git -C "$D" rev-list --count "$up..HEAD")" = 0 ] || { echo "FAIL: commits por empurrar (piso 22)"; rc=1; }
  else echo "FAIL: branch sem upstream (piso 22)"; rc=1; fi
fi
[ "$rc" -eq 0 ] && echo "check-deploy-git: OK"
exit "$rc"
