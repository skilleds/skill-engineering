#!/usr/bin/env bash
# higiene.test.sh — vermelho/verde do higiene.sh (piso 29): apaga build/cache no escopo; nunca dado persistente.
# strict-ok: harness de teste — roda todos os casos e soma (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; H="$HERE/higiene.sh"; rc=0
T="$(mktemp -d)"; trap 'rm -rf "${T:?}"' EXIT
fail() { echo "FAIL: $1"; rc=1; }
W="$T/ws"; OUT="$T/fora"; mkdir -p "$W" "$OUT"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# cenário: projeto rust+node+py dentro do workspace
mkdir -p "$W/p/target/debug" "$W/p/web/.next" "$W/p/web/node_modules/.cache" "$W/p/py/__pycache__" "$W/p/py/.pytest_cache" \
         "$W/p/dist" "$W/p/vol/data" "$W/p_archive/target" "$W/p/envbuild"
touch "$W/p/Cargo.toml"; head -c 4096 /dev/zero > "$W/p/target/debug/big"
echo SEGREDO > "$W/p/envbuild/.env"; mkdir -p "$W/p/envbuild/build"; echo x > "$W/p/envbuild/build/.env.local"
echo keep > "$W/p/vol/data/db.sqlite"; echo keep > "$W/p_archive/target/x"
mkdir -p "$W/p/src/build"; echo 'src' > "$W/p/src/build/mod.rs"   # "build" VERSIONADO no git
( cd "$W/p" && git init -q . && git add src Cargo.toml && git commit -qm init )
echo FORA > "$OUT/precioso"; mkdir -p "$OUT/target"; touch "$OUT/Cargo.toml"

# 1) dry-run não apaga nada, mas lista e mede
o="$(bash "$H" --workspace "$W" 2>&1)"; rc1=$?
[ "$rc1" -eq 0 ] || fail "dry-run rc=$rc1"
[ -d "$W/p/target" ] && [ -d "$W/p/dist" ] || fail "dry-run apagou"
if ! { grep -q DRY-RUN <<<"$o" && grep -q "$W/p/target" <<<"$o"; }; then fail "dry-run não listou"; fi
# 2) --apply apaga build/cache dentro do escopo
o="$(bash "$H" --workspace "$W" --apply 2>&1)"
for d in p/target p/web/.next p/web/node_modules/.cache p/py/__pycache__ p/py/.pytest_cache p/dist; do
  [ -e "$W/$d" ] && fail "não apagou $d"; done
# 3) nunca apaga persistente / protegido / versionado / fora do escopo
[ -f "$W/p/vol/data/db.sqlite" ] || fail "apagou dado persistente (volume/banco)"
[ -f "$W/p/envbuild/.env" ] && [ -f "$W/p/envbuild/build/.env.local" ] || fail "apagou .env"
[ -f "$W/p_archive/target/x" ] || fail "apagou archive"
[ -f "$W/p/src/build/mod.rs" ] || fail "apagou diretório versionado no git"
[ -f "$OUT/precioso" ] && [ -d "$OUT/target" ] || fail "apagou fora do escopo"
[ -d "$W/p/.git" ] || fail "apagou .git"
# 4) log e resumo
grep -qs apagou "$W/.higiene.log" || fail "log vazio"
grep -q 'recursos liberados' <<<"$o" || fail "sem 'recursos liberados' no resumo"
# 5) escopo recusado
for bad in / "$HOME" relativo "$T/inexistente"; do
  bash "$H" --workspace "$bad" >/dev/null 2>&1; [ $? -eq 2 ] || fail "workspace '$bad' deveria ser recusado (rc 2)"; done
bash "$H" >/dev/null 2>&1; [ $? -eq 2 ] || fail "sem --workspace deveria recusar"
ln -s "$OUT" "$T/link"; bash "$H" --workspace "$T/link" >/dev/null 2>&1; [ $? -eq 2 ] || fail "symlink como workspace deveria ser recusado"
# 6) --keep-last poupa o mais recente
K="$T/k"; mkdir -p "$K/a/build" "$K/b/build" "$K/c/build"; touch -d '3 days ago' "$K/a/build"; touch -d '2 days ago' "$K/b/build"
bash "$H" --workspace "$K" --keep-last 1 --apply >/dev/null 2>&1
[ -d "$K/c/build" ] && [ ! -e "$K/a/build" ] && [ ! -e "$K/b/build" ] || fail "keep-last 1 deveria poupar só o mais recente"
# 7) workspaces vencidos: repo com commit não pushado/sujo fica; sem git apaga; com .env fica
E="$T/e"; mkdir -p "$E/velho" "$E/comenv" "$E/novo" "$E/repo_local"; echo a > "$E/velho/x"; echo S > "$E/comenv/.env"; echo n > "$E/novo/x"
( cd "$E/repo_local" && git init -q . && echo a > f && git add f && git commit -qm c )
mkdir "$E/limpo_pushado"; git init -q --bare "$T/remote.git"
( cd "$E/limpo_pushado" && git init -q -b main . && echo a > f && git add f && git commit -qm c && git remote add origin "$T/remote.git" && git push -q -u origin main )
for d in velho comenv repo_local limpo_pushado; do touch -d '10 days ago' "$E/$d"; done
bash "$H" --workspace "$E" --expire-days 5 --apply >/dev/null 2>&1
[ ! -e "$E/velho" ] || fail "workspace vencido sem dado deveria sumir"
[ -d "$E/novo" ] || fail "workspace novo apagado"
[ -f "$E/comenv/.env" ] || fail "apagou workspace com .env"
[ -f "$E/repo_local/f" ] || fail "apagou repo com commit não pushado"
[ ! -e "$E/limpo_pushado" ] || fail "repo limpo e pushado vencido deveria sumir"
# 8) allowlist: limpa conteúdo, mantém o dir; sem --allow nada fora é tocado
A="$T/cache"; mkdir -p "$A/pip"; echo x > "$A/pip/f"; mkdir -p "$T/w2"
bash "$H" --workspace "$T/w2" --allow "$A" >/dev/null 2>&1; [ -f "$A/pip/f" ] || fail "dry-run da allowlist apagou"
bash "$H" --workspace "$T/w2" --allow "$A" --apply >/dev/null 2>&1; { [ -d "$A" ] && [ ! -e "$A/pip" ]; } || fail "allowlist deveria esvaziar e manter o dir"
bash "$H" --workspace "$T/w2" --allow "/etc" >/dev/null 2>&1; [ $? -eq 2 ] || fail "--allow /etc deveria ser recusado"
# 9) limiar de disco: abaixo não faz nada; acima higieniza
L="$T/l"; mkdir -p "$L/x/dist"
HIGIENE_DF_PCT=40 bash "$H" --workspace "$L" --if-above 80 --apply >/dev/null 2>&1; [ -d "$L/x/dist" ] || fail "abaixo do limiar não deveria apagar"
HIGIENE_DF_PCT=90 bash "$H" --workspace "$L" --if-above 80 --apply >/dev/null 2>&1; [ ! -e "$L/x/dist" ] || fail "acima do limiar deveria apagar"
# 10) docker (binário falso): só volume anônimo (64 hex) cai; nomeado nunca
FK="$T/fakebin"; mkdir -p "$FK"; HEX="$(printf 'a%.0s' $(seq 64))"
cat > "$FK/docker" <<DK
#!/usr/bin/env bash
echo "\$*" >> "$T/docker.calls"
[ "\$1 \$2" = "volume ls" ] && { echo meu_banco_pgdata; echo $HEX; }
exit 0
DK
chmod +x "$FK/docker"; : > "$T/docker.calls"
DOCKER_BIN="$FK/docker" bash "$H" --docker --log "$T/dk.log" >/dev/null 2>&1
grep -q 'volume rm' "$T/docker.calls" && fail "dry-run docker removeu volume"
DOCKER_BIN="$FK/docker" bash "$H" --docker --log "$T/dk.log" --apply >/dev/null 2>&1
grep -q "volume rm $HEX" "$T/docker.calls" || fail "não removeu volume anônimo"
grep -q 'volume rm meu_banco_pgdata' "$T/docker.calls" && fail "removeu volume NOMEADO"
if ! { grep -q 'builder prune' "$T/docker.calls" && grep -q 'container prune' "$T/docker.calls"; }; then fail "faltou prune de cache/containers"; fi
grep -q 'system prune\|--volumes\|-a ' "$T/docker.calls" && fail "prune amplo demais (volumes/-a)"
[ "$rc" -eq 0 ] && echo "higiene.test: OK"
exit "$rc"
