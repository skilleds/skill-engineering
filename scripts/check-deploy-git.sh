#!/usr/bin/env bash
# check-deploy-git.sh — gate dos pisos 22/23 (tudo no git; deploy só do git).
# O quê: (1) falha se aparecerem em scripts de deploy/CI/ops: scp/rsync remoto (inclui scp -r, rsync --rsh/-e/::),
#   sftp, kubectl/oc cp, `... | ssh`, ssh com stdin/heredoc, `ssh host` com comando mutável (sed -i, tee, redirect,
#   systemctl, SQL, docker, rm/mv...), psql/mysql/... em host remoto, docker context/-H/DOCKER_HOST remoto,
#   git bundle, ansible, tar|ssh, docker save|load. Única exceção (piso 29): linha que cita host E workspace de uma
#   máquina dev/hml de `maquinas.yml` (env MAQUINAS_YML ou achado sob o dir). Comentário `# check-deploy-git: ok`
#   isenta a linha (use com ADR). (2) se o dir é repo git,
#   falha sem remote, com árvore suja ou com commits por empurrar (HEAD != upstream).
# Uso: bash scripts/check-deploy-git.sh [dir]   (default: .)   SKIP_GIT=1 pula a parte (2).
# Saída: exit 0 ok, 1 se achou violação. Ver `schematize-engineering` -> `references/ops.md` §1/§8 e CLAUDE.md pisos 22/23.
# strict-ok: gate acumula achados e sai no fim (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
D="${1:-.}"; rc=0
TMP="$(mktemp)" || exit 1; trap 'rm -f "$TMP"' EXIT
SP='(^|[;&|[:space:]])'
# rótulo | flag do grep (E ou Ei) | regex. Um achado = código saindo da máquina sem passar pelo git/ops (piso 23/24).
LABELS=(); FLAGS=(); REGS=()
pat() { LABELS+=("$1"); FLAGS+=("$2"); REGS+=("$3"); }
pat "scp/rsync para host remoto" -nE "${SP}(scp|rsync)[[:space:]][^#]*[[:alnum:]_.-]+@?[[:alnum:]_.-]*:[^[:space:]]"
pat "scp -r" -nE "${SP}scp[[:space:]]+-[A-Za-z]*r"
pat "rsync por --rsh/-e/::/rsync://" -nE "${SP}rsync[[:space:]][^#]*(--rsh|[[:space:]]-e[[:space:]]|[[:alnum:]]::[[:alnum:]]|rsync://)"
pat "tar|ssh / docker save|load" -nE "tar[[:space:]][^#]*\|[[:space:]]*ssh|docker[[:space:]]+(save|load)[^#]*(ssh|\|)"
pat "sftp" -nE "${SP}sftp[[:space:]]"
pat "kubectl/oc cp" -nE "${SP}(kubectl|oc)[[:space:]]+cp[[:space:]]"
pat "pipe para ssh (cat|ssh, echo|ssh...)" -nE "\|[[:space:]]*(sudo[[:space:]]+)?ssh[[:space:]]"
pat "ssh com stdin/heredoc/arquivo (<)" -nE "${SP}ssh[[:space:]][^#|]*<"
pat "ssh com comando mutável (sed -i, tee, redirect, systemctl, SQL, docker, rm/mv/cp, git pull...; só 'ssh host ops <op>')" -nEi "${SP}ssh[[:space:]][^#]*(sed[[:space:]]+-[a-z]*i|[[:space:]]tee[[:space:]]|\"[^\"]*[^-2&\"]>[^\"]*\"|'[^']*>[^']*'|systemctl|crontab|iptables|ufw[[:space:]]|nft[[:space:]]|psql|mysql|mariadb|sqlite3|mongosh|(DROP|ALTER|CREATE)[[:space:]]+(TABLE|INDEX|DATABASE|SCHEMA|ROLE|USER|EXTENSION|VIEW)|(INSERT[[:space:]]+INTO|DELETE[[:space:]]+FROM|TRUNCATE|GRANT[[:space:]]|REVOKE[[:space:]])|UPDATE[[:space:]]+[[:alnum:]_.\"]+[[:space:]]+SET|docker[[:space:]]+(run|exec|rm|stop|start|restart|compose|pull|cp|build|kill|volume|network)|(^|[^[:alnum:]_-])(rm|mv|cp|chmod|chown|patch|dd|kill|pkill)[[:space:]]|git[[:space:]]+(apply|am|reset|checkout|pull|clone)|kubectl[[:space:]]+(apply|delete|exec|edit|patch|scale|rollout))"
pat "SQL/CLI de banco REMOTO (-h/--host/URL/PGHOST) — SQL é do ops, nunca da IA (piso 24)" -nE "((psql|pg_dump|pg_restore|mysql|mysqldump|mariadb|mongosh|redis-cli)[[:space:]][^#]*((-h|--host)[[:space:]=]*[^[:space:]-]|://[^[:space:]'\"]*@)|PGHOST=[^[:space:]]+[^#]*(psql|pg_))"
pat "docker em host remoto (context/-H/DOCKER_HOST)" -nE "docker[[:space:]][^#]*(-H|--host)[[:space:]=]*(ssh|tcp)://|DOCKER_HOST=[\"']?(ssh|tcp)://|docker[[:space:]]+context[[:space:]]+(create|use)|docker[[:space:]]+(--context|-c)[[:space:]=]"
pat "git bundle ad-hoc" -nE "${SP}git[[:space:]]+bundle"
pat "ansible (empurra da máquina)" -nE "${SP}ansible(-playbook)?[[:space:]]"
# EXCEÇÃO ESCOPADA do piso 29: máquina dev/hml de build declarada em maquinas.yml; só vale se a linha citar o host E o workspace.
HOSTS=(); WSS=()
MQ="${MAQUINAS_YML:-}"
[ -n "$MQ" ] || MQ="$(find "$D" -maxdepth 3 -name maquinas.yml -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | head -1)"
if [ -n "$MQ" ] && [ -f "$MQ" ]; then
  while IFS='|' read -r h w; do HOSTS+=("$h"); WSS+=("$w"); done < <(awk '
    function val(s) { sub(/^[^:]*:[ \t]*/, "", s); sub(/[ \t]+#.*$/, "", s); gsub(/^["\x27]|["\x27]$/, "", s); sub(/[ \t]+$/, "", s); return s }
    function fim() { if (em && (env == "dev" || env == "hml") && host != "" && ws != "") print host "|" ws }
    /^[ \t]*-[ \t]*nome:/ { fim(); em = 1; host = env = ws = ""; next }
    /^[ \t]+host:/ { host = val($0) } /^[ \t]+env:/ { env = val($0) } /^[ \t]+workspace:/ { ws = val($0) }
    END { fim() }' "$MQ")
fi
exceto() { # linha -> 0 se cita host+workspace de máquina dev/hml declarada
  local i
  for i in "${!HOSTS[@]}"; do
    case "$1" in *"${HOSTS[$i]}"*) case "$1" in *"${WSS[$i]%/}"*) return 0 ;; esac ;; esac
  done
  return 1
}
local_db() { case "$1" in *localhost*|*127.0.0.1*|*'::1'*|*'$PGHOST'*) return 0 ;; esac; return 1; }
while IFS= read -r f; do
  : >"$TMP"
  for i in "${!REGS[@]}"; do
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      txt="${hit#*:}"
      case "$txt" in *'check-deploy-git: ok'*) continue ;; esac
      case "$(printf '%s' "$txt" | sed 's/^[[:space:]]*//')" in '#'*) continue ;; esac
      case "${LABELS[$i]}" in *"banco REMOTO"*) local_db "$txt" && continue ;; esac
      exceto "$txt" && continue
      printf '%s  [%s]\n' "$hit" "${LABELS[$i]}" >>"$TMP"
    done < <(grep "${FLAGS[$i]}" -- "${REGS[$i]}" "$f" 2>/dev/null)
  done
  if [ -s "$TMP" ]; then
    echo "FAIL: $f envia código/comando ao servidor fora do git/ops (pisos 23/24):"; sort -t: -k1,1n -u "$TMP" | sed 's/^/  /'; rc=1
  fi
done < <(find "$D" -type f \( -name '*.sh' -o -name '*.bash' -o -name '*.yml' -o -name '*.yaml' -o -name '*.mk' -o -name 'Makefile' -o -name 'justfile' -o -name 'Taskfile*' \) \
  -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/versions/*' -not -path '*/references/*' \
  -not -name 'check-deploy-git*' 2>/dev/null)
if [ -z "${SKIP_GIT:-}" ] && git -C "$D" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  [ -n "$(git -C "$D" remote -v)" ] || { echo "FAIL: sem remote (piso 22)"; rc=1; }
  [ -z "$(git -C "$D" status --porcelain)" ] || { echo "FAIL: árvore suja (piso 22)"; rc=1; }
  if up=$(git -C "$D" rev-parse --abbrev-ref '@{u}' 2>/dev/null); then
    [ "$(git -C "$D" rev-list --count "$up..HEAD")" = 0 ] || { echo "FAIL: commits por empurrar (piso 22)"; rc=1; }
  else echo "FAIL: branch sem upstream (piso 22)"; rc=1; fi
fi
[ "$rc" -eq 0 ] && echo "check-deploy-git: OK"
exit "$rc"
