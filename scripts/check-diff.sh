#!/usr/bin/env bash
# check-diff.sh — gate determinístico de padrões (`padroes-codigo.md`, §35, §37) sobre o diff.
# Uso: bash scripts/check-diff.sh [base-ref|--cached]   (default: origin/main)
#   base-ref = HEAD (ou --cached, ou qualquer ref que resolva para o MESMO commit do HEAD): modo "pre-commit" —
#   olha o que está staged/modificado contra HEAD (`git diff HEAD`), nunca HEAD contra HEAD (que dava verde vazio).
#   Linguagens: Go, Rust, TS/JS, Elixir (.ex/.exs), C# (.cs), Zig, Ruby, Kotlin, Swift, Dart, Python.
# Sai 1 se achar qualquer violação de PISO; imprime achados com arquivo:linha.
#
# Cobre o que dá pra checar por regex/contagem. O julgamento fino (semântica de
# auth, coerção de tipo, etc.) fica pro /eng-review com leitura humana/da IA.

# EXCEÇÃO DECLARADA de strict mode (`schematize-shell` -> `references/piso.md` secao 1):
# este script é um COLETOR — ele varre tudo e SOMA os achados. Com `set -e` abortaria no
# primeiro problema e reportaria um, escondendo os outros. Por isso `set -uo pipefail` sem `-e`.
set -uo pipefail
BASE="${1:-origin/main}"
[ "$BASE" = "--cached" ] && BASE="HEAD"
FAIL=0
RED=$'\033[0;31m'; YLW=$'\033[0;33m'; GRN=$'\033[0;32m'; RST=$'\033[0m'

# Base inexistente NAO pode virar verde: `git diff` falha, FILES fica vazio e o gate diria OK sem ter olhado nada.
if ! git rev-parse --verify -q "$BASE^{commit}" >/dev/null 2>&1; then
  echo "${RED}✗ BLOQUEIA${RST} base '$BASE' não resolve para um commit (ou não é repo git) — o gate não olhou nada"
  exit 1
fi

# Modo pre-commit: base == HEAD (mesmo commit) => árvore de trabalho/staged contra HEAD; senão merge-base...HEAD.
PRECOMMIT=0
if [ "$(git rev-parse "$BASE^{commit}")" = "$(git rev-parse HEAD 2>/dev/null)" ]; then PRECOMMIT=1; fi
changed() { # lista os arquivos alterados (adicionados/copiados/modificados/renomeados), 1 por linha
  if (( PRECOMMIT )); then git diff --name-only --diff-filter=ACMR HEAD 2>/dev/null
  else git diff --name-only --diff-filter=ACMR "$BASE"...HEAD 2>/dev/null; fi
}
CODE_EXT='go|rs|ts|tsx|js|mjs|jsx|ex|exs|cs|zig|rb|kt|kts|swift|dart|py'
# Arquivos de código alterados (exclui exceções de padroes-codigo.md: testes, migrations, gerados, mocks).
mapfile -t FILES < <(changed \
  | grep -E "\\.($CODE_EXT)\$" \
  | grep -vE '(_test\.|\.test\.|_spec\.|(Tests?|Spec)\.(cs|kt|swift)$|\.Tests?/|/migrations/|/db/migrate/|/generated/|\.gen\.|\.g\.dart$|\.freezed\.dart$|/mocks?/)' || true)

block() { echo "${RED}✗ BLOQUEIA${RST} $1"; FAIL=1; }
warn()  { echo "${YLW}⚠ ATENÇÃO${RST} $1"; }

echo "== schematize-engineering check-diff (base: $BASE) =="

# 1) padroes-codigo.md §1 — tamanho de arquivo em camadas: teto DURO 750 (≤500 útil + ~250 comentário),
#    FLAG (não bloqueia) em >300 de código útil (~400 em observabilidade).
useful_lines() { # conta linhas de código útil: exclui branco e linha só-comentário (aprox multi-linguagem)
  grep -vcE '^[[:space:]]*($|//|#|///|/\*|\*/|\*[^/])' "$1" 2>/dev/null || echo 0
}
is_observ() { echo "$1" | grep -qiE '(observ|telemetr|tracing|/metrics?|metric|instrument|logg?(er|ing)|otel|prometheus|opentelemetry)'; }
for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || continue
  total=$(wc -l < "$f"); useful=$(useful_lines "$f")
  if (( total > 750 )); then
    block "$f: $total linhas (>750 teto duro; ~250 são p/ comentário, ~500 úteis) — quebre por coesão (padroes-codigo.md §1)"
  elif (( useful > 500 )); then
    block "$f: $useful linhas de código útil (>500 teto duro) — quebre por coesão (padroes-codigo.md §1)"
  else
    thr=300; ctx=""
    is_observ "$f" && { thr=400; ctx=" [observabilidade infla ~400]"; }
    (( useful > thr )) && warn "$f: $useful linhas de código útil (>$thr)$ctx — indício de função muito extensa / falta de abstração; FLAG, registre como dívida p/ rever quando prioridades permitirem (padroes-codigo.md)"
  fi
done

# 2) §37 — macaquices grep-áveis (padrão -> mensagem)
# scan "regex" "mensagem" [--perl]
#   Roda a regex sobre os arquivos do diff e BLOQUEIA em cada acerto.
#   O `|| true` de antes engolia o exit 2 do grep (regex invalida / erro de I/O) e transformava
#   ERRO DE REGEX EM VERDE — foi assim que o piso de `<img>` sem alt ficou morto desde que existe
#   (A3/A3b da vistoria de 2026-08-21). Agora: 0 = achou, 1 = nao achou, >=2 = ERRO, e erro FALHA.
scan() {
  local re="$1" msg="$2" flavor="${3:-ere}" ext="${4:-}" hit rc
  local -a gflags
  case "$flavor" in
    --perl|perl) gflags=(-nP) ;;
    *)           gflags=(-nE) ;;
  esac
  for f in "${FILES[@]}"; do
    [[ -f "$f" ]] || continue
    [[ -z "$ext" || "$f" =~ \.($ext)$ ]] || continue
    hit=$(grep "${gflags[@]}" "$re" "$f" 2>/dev/null); rc=$?
    if (( rc >= 2 )); then
      block "scripts/check-diff.sh — grep saiu $rc na regra '"'"'$msg'"'"' (regex invalida ou arquivo ilegivel): $re"
      continue
    fi
    (( rc == 0 )) && while IFS= read -r l; do block "$f:${l%%:*} — $msg"; done <<< "$hit"
  done
}

# has_perl_grep — `grep -P` existe nesta maquina? Sem ele, regra que exige lookahead NAO roda
# em silencio; entao a ausencia vira BLOQUEIO explicito, nao um verde a menos.
has_perl_grep() { echo x | grep -qP x 2>/dev/null; }
scan 'NEXT_PUBLIC_[A-Z_]*(SECRET|KEY|TOKEN|PASSWORD|PRIVATE)' 'segredo exposto via NEXT_PUBLIC_ (§13.4/§37)'
scan 'rejectUnauthorized:\s*false|InsecureSkipVerify:\s*true|verify\s*=\s*False' 'verificação TLS desabilitada (§37)'
scan 'Math\.random\(\).*(token|secret|session|nonce|reset)' 'Math.random em contexto de segredo — use CSPRNG (§14/§37)'
scan 'eslint-disable.*security|//\s*nolint:.*(gosec|sec)|#\s*nosec' 'desabilitando regra de segurança inline (§37)'
scan 'Access-Control-Allow-Origin["'\'' :,]*\*' 'CORS * — allowlist explícita (§37)'
scan '(query|exec|raw)\(\s*[`"'\''].*\$\{|"\s*\+\s*.*(req|input|param|body)' 'possível SQL/comando por concatenação (§10/§37)'
scan 'catch\s*\(\s*\)\s*\{\s*\}|except\s*:\s*pass|catch\s*\{\s*\}' 'erro engolido (§37)'
scan '@ts-ignore|: any\b|interface\{\}' 'tipo silenciado (any/@ts-ignore/interface{}) (§37)'
scan '\.(skip|only)\(|t\.Skip\(|xit\(|@Ignore' 'teste pulado/silenciado (§37)'
# Regras equivalentes por linguagem do rol (SQL interpolado, erro engolido, teste pulado).
scan '(Repo\.query!?|SQL\.query!?|fragment)\(.*#\{' 'SQL interpolado em Elixir (#{}) — use parâmetros/fragment com ? (§10/§37)' ere 'ex|exs'
scan 'rescue[[:space:]]+_[[:space:]]*->[[:space:]]*(:ok|nil)|catch[[:space:]]+_,[[:space:]]*_[[:space:]]*->[[:space:]]*(:ok|nil)' 'erro engolido em Elixir (rescue _ -> :ok) (§37)' ere 'ex|exs'
scan '@tag[[:space:]]+(:skip|skip:)' 'teste pulado em Elixir (@tag :skip) (§37)' ere 'ex|exs'
scan '(FromSqlRaw|ExecuteSqlRaw|SqlQueryRaw|SqlQuery|CommandText)[^;]*(\$"|"[[:space:]]*\+)' 'SQL interpolado/concatenado em C# — use parâmetros (§10/§37)' ere 'cs'
scan 'catch[[:space:]]*(\([^)]*\))?[[:space:]]*\{[[:space:]]*\}' 'erro engolido em C# (catch vazio) (§37)' ere 'cs|kt|dart|swift'
scan '\[(Fact|Theory)\(Skip|\[Ignore' 'teste pulado em C# (Skip/Ignore) (§37)' ere 'cs'
scan 'catch[[:space:]]+unreachable|SkipZigTest' 'catch unreachable / teste pulado em Zig (§37)' ere 'zig'
scan 'allocPrint\(.*(SELECT|INSERT|UPDATE|DELETE)[[:space:]]' 'SQL montado por allocPrint em Zig — use parâmetros (§10/§37)' ere 'zig'
scan '(where|find_by_sql|execute|exec_query|select_all|order|joins|pluck)\([[:space:]]*["'\''`].*#\{' 'SQL interpolado em Ruby (#{}) — use placeholders (§10/§37)' ere 'rb'
scan 'rescue[[:space:]]+nil\b|rescue([[:space:]]+[A-Z][A-Za-z:]*)?([[:space:]]*=>[[:space:]]*[a-z_]+)?[[:space:]]*;[[:space:]]*(nil|end)\b' 'erro engolido em Ruby (rescue nil) (§37)' ere 'rb'
scan '(^|[[:space:]])(xit|xdescribe|xcontext|pending)[[:space:](]' 'teste pulado em Ruby (xit/pending) (§37)' ere 'rb'
scan '(rawQuery|execSQL|createNativeQuery|rawInsert|rawUpdate|rawDelete)\([[:space:]]*"[^"]*\$' 'SQL interpolado em Kotlin/Dart ($var) — use bind (§10/§37)' ere 'kt|kts|dart'
scan '(rawQuery|execute|rawInsert)\([[:space:]]*'\''[^'\'']*\$' 'SQL interpolado em Dart ($var) — use whereArgs (§10/§37)' ere 'dart'
scan '(sqlite3_exec|\.execute|\.prepare)\(.*\\\(' 'SQL interpolado em Swift (\()) — use bind (§10/§37)' ere 'swift'
scan 'except[[:space:]]+[A-Za-z_.]+([[:space:]]+as[[:space:]]+[a-z_]+)?:[[:space:]]*pass' 'erro engolido em Python (except X: pass) (§37)' ere 'py'
scan '\.(execute|executemany)\([[:space:]]*f["'\'']' 'SQL por f-string em Python — use parâmetros (§10/§37)' ere 'py'

# 3) §39 — índice atualizado quando muda funcionalidade
if (( ${#FILES[@]} > 0 )); then
  idx=$(changed | grep -E 'INDEX_(GLOBAL|FUNCTIONS)\.md' || true)
  [[ -z "$idx" ]] && warn "diff mexe em código mas não toca INDEX_*.md — índice atualizado? (§39)"
fi

# 4) §3 — backend novo em PHP
php=$(changed | grep -E '\.php$' || true)
[[ -n "$php" ]] && block "arquivo PHP no diff — PHP é proibido, migrar (§3.2): $php"

echo
if (( FAIL )); then
  echo "${RED}== check-diff: BLOQUEADO ==${RST}"; exit 1
else
  echo "${GRN}== check-diff: OK ==${RST}"; exit 0
fi
