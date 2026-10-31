#!/usr/bin/env bash
# check-ci-triggers.sh — gate do piso 27 (CI remoto NÃO roda por commit; o gate por commit é local).
# O quê: lê workflows do GitHub Actions e REPROVA: (a) `on: push` em branch (push sem `tags` ou com
#   `branches`); (b) `pull_request`/`pull_request_target` sem filtro (`branches` ou `paths`);
#   (c) workflow sem `concurrency` com `cancel-in-progress: true`; (d) `schedule` sem comentário
#   `justificativa:` no arquivo. AVISO (não reprova): push/PR sem `paths-ignore`/`paths`.
# Uso: bash scripts/check-ci-triggers.sh [dir|arquivo.yml ...]   (default: .; procura .github/workflows/*.y*ml)
# Saída: exit 0 limpo, 1 achado, 2 uso inválido.
# LIMITAÇÃO (heurística, sem parser YAML): olha o bloco `on:` por indentação e texto; âncoras/aliases,
#   `on` gerado por template e YAML exótico passam despercebidos. É piso mínimo, não prova.
# strict-ok: gate acumula achados e sai no fim (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
[ $# -gt 0 ] || set -- .
files=()
for a in "$@"; do
  if [ -f "$a" ]; then files+=("$a")
  elif [ -d "$a/.github/workflows" ]; then while IFS= read -r f; do files+=("$f"); done < <(find "$a/.github/workflows" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
  elif [ -d "$a" ]; then while IFS= read -r f; do files+=("$f"); done < <(find "$a" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
  else echo "uso: check-ci-triggers.sh [dir|arquivo.yml ...]" >&2; exit 2; fi
done
[ "${#files[@]}" -gt 0 ] || { echo "check-ci-triggers: nenhum workflow encontrado (nada a checar)"; exit 0; }
rc=0
for f in "${files[@]}"; do
  out="$(awk '
    function ind(s) { match(s, /^ */); return RLENGTH }
    function fim() {
      if (key == "") return
      if (key == "push") { if (buf !~ /tags/ || buf ~ /branches/) print "FAIL: on: push em branch (sem filtro de tags) — piso 27: use workflow_dispatch + push: tags"; if (buf !~ /paths-ignore|paths:/) print "AVISO: push sem paths-ignore (docs/md)" }
      else if (key ~ /^pull_request/) { if (buf !~ /branches|paths/) print "FAIL: " key " sem filtro (branches/paths) — piso 27"; else if (buf !~ /paths-ignore|paths:/) print "AVISO: " key " sem paths-ignore (docs/md)" }
      else if (key == "schedule") sched = 1
      key = ""; buf = ""
    }
    { l = $0; sub(/[ \t]+#.*$/, "", l); if (l ~ /^[ \t]*#/) next }
    l ~ /^[ \t]*$/ { next }
    l ~ /^concurrency:/ { conc = 1 }
    l ~ /cancel-in-progress:[ \t]*true/ { cancel = 1 }
    inon && ind(l) == 0 { fim(); inon = 0 }
    l ~ /^("on"|on):/ {
      inon = 1; base = -1
      rest = l; sub(/^("on"|on):[ \t]*/, "", rest)
      if (rest != "") {
        if (rest ~ /push/ && rest !~ /tags/) print "FAIL: on: push em branch (inline, sem tags) — piso 27"
        if (rest ~ /pull_request/ && rest !~ /branches|paths/) print "FAIL: pull_request sem filtro (inline) — piso 27"
        if (rest ~ /schedule/) sched = 1
        inon = 0
      }
      next
    }
    inon {
      i = ind(l)
      if (base < 0) base = i
      if (i == base) {
        fim()
        k = l; sub(/^ */, "", k); sub(/:.*/, "", k); key = k
        buf = l
        if (key == "push" || key ~ /^pull_request/ || key == "schedule") next
      } else { buf = buf "\n" l }
    }
    END { fim(); if (!conc || !cancel) print "FAIL: sem concurrency com cancel-in-progress: true — piso 27"; if (sched) print "SCHED" }
  ' "$f")"
  if grep -qx 'SCHED' <<<"$out"; then
    grep -qi 'justificativa:' "$f" || out="$out"$'\n'"FAIL: schedule (cron) sem comentário 'justificativa:' — piso 27"
    out="$(grep -vx 'SCHED' <<<"$out")"
  fi
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    echo "$f: $line"
    case "$line" in FAIL*) rc=1 ;; esac
  done <<<"$out"
done
[ "$rc" -eq 0 ] && echo "check-ci-triggers: OK (${#files[@]} workflow(s))"
exit "$rc"
