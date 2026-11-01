#!/usr/bin/env bash
# higiene.sh — higiene pós-build/teste (piso 29): apaga build e cache inúteis, nunca dado persistente.
# O quê: DRY-RUN por padrão (lista o que apagaria + tamanho); só `--apply` apaga. Escopo restrito a
#   (1) o workspace de build `--workspace DIR` e (2) caminhos `--allow DIR` (conteúdo; o dir fica).
#   Candidatos no workspace (por nome, com guarda): target (c/ Cargo.toml|pom.xml), build, dist, .next,
#   node_modules/.cache, __pycache__, .pytest_cache, .gradle, obj|bin (c/ *.csproj|*.sln|*.fsproj),
#   _build|deps (c/ mix.exs), zig-cache|.zig-cache. `--expire-days N`: workspaces filhos vencidos.
#   `--docker`: containers parados, imagens dangling, build cache e volumes ANÔNIMOS (nome = 64 hex).
# NUNCA apaga: volume nomeado, banco, uploads, .env*, `*_archive`, `.git`, caminho versionado no git,
#   repo com commit não pushado/árvore suja (workspace vencido), symlink, nada fora do escopo.
# Uso: higiene.sh --workspace DIR [--allow DIR]... [--keep-last N] [--expire-days N] [--docker]
#        [--if-above PCT] [--log FILE] [--apply]
#   --keep-last N  poupa os N candidatos mais recentes (cache quente).  --if-above PCT  só roda se o
#   disco do workspace estiver acima de PCT% (limiar do piso 29d; HIGIENE_DF_PCT injeta o valor em teste).
#   Log: linhas `ISO acao caminho bytes` (default WORKSPACE/.higiene.log; só docker: ~/.local/state/schematize/higiene.log); resumo com disco antes/depois.
# Saída: 0 ok, 1 algum item não pôde ser apagado, 2 uso inválido/escopo recusado.  Docker: DOCKER_BIN troca o binário (teste).
# strict-ok: ferramenta de limpeza best-effort — um item que falha não aborta os demais (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail

W=""; APPLY=0; KEEP=0; EXPIRE=""; DOCKER=0; ABOVE=""; LOG=""; ALLOW=()
die() { echo "higiene: $*" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --workspace) W="${2:-}"; shift 2 ;;
    --allow) ALLOW+=("${2:-}"); shift 2 ;;
    --keep-last) KEEP="${2:-}"; shift 2 ;;
    --expire-days) EXPIRE="${2:-}"; shift 2 ;;
    --if-above) ABOVE="${2:-}"; shift 2 ;;
    --log) LOG="${2:-}"; shift 2 ;;
    --docker) DOCKER=1; shift ;;
    --apply) APPLY=1; shift ;;
    *) die "argumento desconhecido: $1" ;;
  esac
done
[[ "$KEEP" =~ ^[0-9]+$ ]] || die "--keep-last exige inteiro"
[ -z "$EXPIRE" ] || [[ "$EXPIRE" =~ ^[0-9]+$ ]] || die "--expire-days exige inteiro"
[ -z "$ABOVE" ] || [[ "$ABOVE" =~ ^[0-9]+$ ]] || die "--if-above exige inteiro"

# Escopo: absoluto, existente, fora de "/" e de $HOME, com >= 2 componentes.
safe_dir() {
  local p="$1"
  [[ "$p" == /* ]] || return 1
  [ -d "$p" ] && [ ! -L "$p" ] || return 1
  p="$(cd "$p" && pwd -P)"
  [ "$p" != "/" ] && [ "$p" != "${HOME:-/nonexistent}" ] || return 1
  [ "$(awk -F/ '{print NF-1}' <<<"$p")" -ge 2 ] || return 1
  case "$p" in /etc|/usr|/bin|/sbin|/lib*|/boot|/root|/home|/var|/opt|/srv|/tmp) return 1 ;; esac
  return 0
}
[ -n "$W" ] || [ "$DOCKER" -eq 1 ] || die "--workspace obrigatório (escopo do piso 29)"
if [ -n "$W" ]; then safe_dir "$W" || die "workspace recusado (use caminho absoluto, existente, dedicado ao build): $W"; W="$(cd "$W" && pwd -P)"; fi
for a in "${ALLOW[@]+"${ALLOW[@]}"}"; do safe_dir "$a" || die "--allow recusado: $a"; done

disk_pct() {
  if [ -n "${HIGIENE_DF_PCT:-}" ]; then echo "$HIGIENE_DF_PCT"; return; fi
  df --output=pcent "${W:-.}" 2>/dev/null | tail -1 | tr -dc '0-9'
}
disk_used() { df -B1 --output=used "${W:-.}" 2>/dev/null | tail -1 | tr -dc '0-9'; }
if [ -n "$ABOVE" ] && [ -n "$W" ]; then
  p="$(disk_pct)"
  if [ "${p:-0}" -le "$ABOVE" ]; then echo "higiene: disco em ${p}% (<= ${ABOVE}%): nada a fazer"; exit 0; fi
  echo "higiene: disco em ${p}% (> ${ABOVE}%): higienizando antes de novo build"
fi

[ -n "$LOG" ] || { if [ -n "$W" ]; then LOG="$W/.higiene.log"; else LOG="${XDG_STATE_HOME:-${HOME:-.}/.local/state}/schematize/higiene.log"; mkdir -p "$(dirname "$LOG")" 2>/dev/null; fi; }
MODE="dry-run"; [ "$APPLY" -eq 1 ] && MODE="apagou"
before="$(disk_used)"; TOTAL=0; COUNT=0; SKIPPED=0; FAILS=0
log() { printf '%s %s %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" "${3:-0}" >> "$LOG" 2>/dev/null; }
skip() { SKIPPED=$((SKIPPED+1)); echo "  poupado ($2): $1"; }

# Guardas comuns a qualquer candidato (dir).
protegido() {
  local d="$1" c
  [ -L "$d" ] && { echo symlink; return 0; }
  case "/$d/" in */.git/*|*_archive/*) echo "archive/.git"; return 0 ;; esac
  c="$(find -P "$d" -name '.env*' -print -quit 2>/dev/null)"; [ -z "$c" ] || { echo ".env"; return 0; }
  if git -C "$(dirname "$d")" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    c="$(git -C "$(dirname "$d")" ls-files -- "$(basename "$d")" 2>/dev/null | head -1)"
    [ -z "$c" ] || { echo "versionado no git"; return 0; }
  fi
  return 1
}
remover() {  # remover <caminho> : mede, loga e (com --apply) apaga
  local d="$1" sz
  sz="$(du -sb "$d" 2>/dev/null | cut -f1)"; sz="${sz:-0}"
  TOTAL=$((TOTAL+sz)); COUNT=$((COUNT+1))
  echo "  $MODE: $d ($sz bytes)"
  if [ "$APPLY" -eq 1 ]; then rm -rf --one-file-system -- "$d" 2>/dev/null || { echo "  falhou: $d"; FAILS=$((FAILS+1)); return; }; fi
  log "$MODE" "$d" "$sz"
}

candidato_ok() {  # candidato_ok <dir> : guardas por nome
  local d="$1" n p; n="$(basename "$d")"; p="$(dirname "$d")"
  case "$n" in
    target) [ -f "$p/Cargo.toml" ] || [ -f "$p/pom.xml" ] ;;
    obj|bin) compgen -G "$p/*.csproj" >/dev/null || compgen -G "$p/*.sln" >/dev/null || compgen -G "$p/*.fsproj" >/dev/null ;;
    _build|deps) [ -f "$p/mix.exs" ] ;;
    .cache) [ "$(basename "$p")" = "node_modules" ] ;;
    *) return 0 ;;
  esac
}

if [ -n "$W" ]; then
  echo "higiene: workspace $W ($MODE)"
  mapfile -t CANDS < <(find -P "$W" \( -name .git -o -name '*_archive' \) -prune -o -type d \
    \( -name target -o -name build -o -name dist -o -name .next -o -name .cache -o -name __pycache__ \
       -o -name .pytest_cache -o -name .gradle -o -name obj -o -name bin -o -name _build -o -name deps \
       -o -name zig-cache -o -name .zig-cache \) -print -prune 2>/dev/null)
  OK=()
  for d in "${CANDS[@]+"${CANDS[@]}"}"; do candidato_ok "$d" && OK+=("$d"); done
  # mais recentes primeiro; os KEEP primeiros ficam (cache quente)
  mapfile -t OK < <(for d in "${OK[@]+"${OK[@]}"}"; do printf '%s\t%s\n' "$(stat -c %Y "$d" 2>/dev/null || echo 0)" "$d"; done | sort -rn | cut -f2-)
  i=0
  for d in "${OK[@]+"${OK[@]}"}"; do
    i=$((i+1))
    [ "$i" -le "$KEEP" ] && { skip "$d" "keep-last"; continue; }
    if r="$(protegido "$d")"; then skip "$d" "$r"; else remover "$d"; fi
  done
  if [ -n "$EXPIRE" ]; then
    while IFS= read -r d; do
      case "$d" in *_archive) skip "$d" "archive"; continue ;; esac
      if [ -e "$d/.git" ]; then
        dirty="$(git -C "$d" status --porcelain 2>/dev/null)"
        ahead="$(git -C "$d" rev-list --count '@{u}..HEAD' 2>/dev/null || echo unpushed)"
        { [ -n "$dirty" ] || [ "$ahead" != 0 ]; } && { skip "$d" "repo com commit não pushado/sujo"; continue; }
      fi
      c="$(find -P "$d" \( -name '.env*' -o -name uploads -o -name volumes \) -not -path '*/node_modules/*' -print -quit 2>/dev/null)"
      [ -z "$c" ] || { skip "$d" "dado persistente ($c)"; continue; }
      [ -L "$d" ] && { skip "$d" symlink; continue; }
      remover "$d"
    done < <(find -P "$W" -mindepth 1 -maxdepth 1 -type d -mtime +"$EXPIRE" 2>/dev/null)
  fi
fi

for a in "${ALLOW[@]+"${ALLOW[@]}"}"; do
  echo "higiene: allowlist $a ($MODE)"
  while IFS= read -r e; do
    if r="$(protegido "$e")"; then skip "$e" "$r"; else remover "$e"; fi
  done < <(find -P "$a" -mindepth 1 -maxdepth 1 2>/dev/null)
done

if [ "$DOCKER" -eq 1 ]; then
  DK="${DOCKER_BIN:-docker}"
  if command -v "$DK" >/dev/null 2>&1; then
    echo "higiene: docker ($MODE) — só parados/dangling/anônimos; volume nomeado nunca"
    # volume ANÔNIMO = nome de 64 hex; nomeado fica sempre.
    while IFS= read -r v; do
      [[ "$v" =~ ^[0-9a-f]{64}$ ]] || { [ -z "$v" ] || skip "volume $v" "volume nomeado"; continue; }
      echo "  $MODE: volume anônimo $v"; COUNT=$((COUNT+1)); log "$MODE" "docker-volume:$v" 0
      [ "$APPLY" -eq 1 ] && "$DK" volume rm "$v" >/dev/null 2>&1
    done < <("$DK" volume ls -q -f dangling=true 2>/dev/null)
    for cmd in "container prune -f" "image prune -f" "builder prune -f"; do
      echo "  $MODE: docker $cmd"; log "$MODE" "docker:$cmd" 0
      # shellcheck disable=SC2086  # $cmd é literal controlado acima
      [ "$APPLY" -eq 1 ] && "$DK" $cmd >/dev/null 2>&1
    done
  else echo "higiene: docker ausente — pulado"; fi
fi

after="$(disk_used)"
echo "higiene: $COUNT item(ns) ($MODE), $SKIPPED poupado(s), $TOTAL bytes ($((TOTAL/1048576)) MiB) ${MODE/apagou/liberados}"
echo "higiene: disco usado antes=${before:-?} depois=${after:-?} bytes | recursos liberados: $([ "$APPLY" -eq 1 ] && echo "$TOTAL bytes" || echo "0 (dry-run; rode com --apply)")"
[ "$APPLY" -eq 1 ] || echo "higiene: DRY-RUN — nada foi apagado"
exit $((FAILS > 0))
