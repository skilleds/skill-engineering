#!/usr/bin/env bash
# build-zip.sh — gera skill-engineering.zip, o asset do GitHub Release.
#
# O quê: empacota o corpo da skill sob o diretório de topo `schematize-engineering/`
#   (layout idêntico ao das releases manuais; é o que o instalador do schematize_skills_rs
#   espera: `unzip` e depois `<skill_dir>/`). Exclui .git, .github, versions/, install.sh,
#   README.md, .gitignore e *.zip.
# Onde: chamado por .github/workflows/release.yml (tag v*) e localmente para conferência.
# Determinismo: ordem de arquivos fixa (LC_ALL=C sort), mtimes normalizados e zip -X.
# Uso: scripts/build-zip.sh [saida.zip]   (default: ./skill-engineering.zip)
set -euo pipefail

SKILL_NAME="schematize-engineering"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$(realpath -m "${1:-$SRC/skill-engineering.zip}")"
STAMP="$(git -C "$SRC" log -1 --format=%cd --date=format:%Y%m%d%H%M.%S 2>/dev/null || date -u +%Y%m%d%H%M.%S)"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/$SKILL_NAME"

( cd "$SRC" && tar -cf - \
    --exclude=./.git --exclude=./.github --exclude=./versions \
    --exclude=./install.sh --exclude=./README.md --exclude=./.gitignore \
    --exclude='*.zip' . ) | ( cd "$STAGE/$SKILL_NAME" && tar -xf - )

find "$STAGE" -exec touch -h -t "$STAMP" {} +
rm -f "$OUT"
# python3 (stdlib) em vez de `zip`: presente em qualquer runner/máquina, saída byte a byte estável.
python3 -I - "$STAGE" "$SKILL_NAME" "$OUT" "$STAMP" <<'PY'
import os, sys, zipfile
stage, top, out, stamp = sys.argv[1:5]
t = (int(stamp[0:4]), int(stamp[4:6]), int(stamp[6:8]), int(stamp[8:10]), int(stamp[10:12]), int(stamp[13:15]))
paths = []
for root, dirs, files in os.walk(os.path.join(stage, top)):
    paths += [os.path.join(root, n) for n in dirs + files]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for p in sorted(paths + [os.path.join(stage, top)]):
        rel = os.path.relpath(p, stage)
        isdir = os.path.isdir(p)
        zi = zipfile.ZipInfo(rel + ("/" if isdir else ""), t)
        zi.external_attr = ((0o40755 if isdir else (0o100755 if os.access(p, os.X_OK) else 0o100644)) << 16)
        if isdir:
            z.writestr(zi, b"")
        else:
            zi.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(zi, open(p, "rb").read())
PY
echo "ok: $OUT ($(unzip -Z1 "$OUT" | wc -l) entradas)"
