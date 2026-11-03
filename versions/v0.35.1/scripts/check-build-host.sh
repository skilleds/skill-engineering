#!/usr/bin/env bash
# check-build-host.sh — lint do inventário de máquinas de build/teste (piso 29): `<projeto>_ops/maquinas.yml`.
# O quê: cada entrada (`- nome:`) precisa de nome, host, env ∈ {dev,hml} (prd/staging reprovam),
#   papel: build-teste, ponte_direta: true, workspace (absoluto, >= 3 componentes, fora de /, /etc, /usr,
#   /var puro, $HOME), limite_disco_pct (1-100) e limite_cpu (inteiro >= 1). Arquivo sem entradas reprova.
# Formato:  maquinas:\n  - nome: build-1\n    host: 10.0.0.5\n    env: dev\n    papel: build-teste
#           \n    ponte_direta: true\n    workspace: /var/tmp/schematize-build/proj/\n    limite_disco_pct: 80\n    limite_cpu: 4
# Uso: bash scripts/check-build-host.sh <maquinas.yml>   Saída: 0 ok, 1 violação, 2 uso inválido.
# LIMITAÇÃO: valida o inventário, não prova que a máquina existe nem que a higiene rodou.
# strict-ok: gate acumula achados e sai no fim (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
F="${1:-}"; [ -f "$F" ] || { echo "uso: check-build-host.sh <maquinas.yml>" >&2; exit 2; }
out="$(awk '
  function val(s) { sub(/^[^:]*:[ \t]*/, "", s); sub(/[ \t]+#.*$/, "", s); gsub(/^["\x27]|["\x27]$/, "", s); sub(/[ \t]+$/, "", s); return s }
  function fim(   n, c) {
    if (!em) return
    n = nome != "" ? nome : "entrada#" idx
    if (nome == "") print "FAIL: " n " sem nome"
    if (host == "") print "FAIL: " n " sem host"
    if (env != "dev" && env != "hml") print "FAIL: " n " env=\"" env "\" (só dev ou hml; prd/staging nunca)"
    if (papel != "build-teste") print "FAIL: " n " papel deve ser build-teste"
    if (ponte != "true") print "FAIL: " n " ponte_direta deve ser true (escopo do piso 29)"
    c = split(ws, p, "/") - 1
    if (ws !~ /^\// || c < 3 || ws ~ /^\/(etc|usr|root|boot|bin|sbin|lib[0-9a-z]*)(\/|$)/ || ws ~ /^\/home\/[^\/]+\/?$/ || ws ~ /\.\./)
      print "FAIL: " n " workspace inválido (absoluto, >= 3 componentes, dedicado ao build): \"" ws "\""
    if (disco !~ /^[0-9]+$/ || disco+0 < 1 || disco+0 > 100) print "FAIL: " n " limite_disco_pct deve ser 1-100"
    if (cpu !~ /^[0-9]+$/ || cpu+0 < 1) print "FAIL: " n " limite_cpu deve ser inteiro >= 1"
  }
  /^[ \t]*#/ || /^[ \t]*$/ { next }
  /^[ \t]*-[ \t]*nome:/ { fim(); em = 1; idx++; nome = val($0); host = env = papel = ponte = ws = disco = cpu = ""; total++; next }
  /^[ \t]+host:/ { host = val($0) } /^[ \t]+env:/ { env = val($0) } /^[ \t]+papel:/ { papel = val($0) }
  /^[ \t]+ponte_direta:/ { ponte = val($0) } /^[ \t]+workspace:/ { ws = val($0) }
  /^[ \t]+limite_disco_pct:/ { disco = val($0) } /^[ \t]+limite_cpu:/ { cpu = val($0) }
  END { fim(); if (!total) print "FAIL: nenhuma máquina declarada (piso 29: sem máquina dev/hml, não crie o arquivo)" }
' "$F")"
if [ -n "$out" ]; then echo "$out"; exit 1; fi
echo "check-build-host: OK"
