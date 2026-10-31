#!/usr/bin/env bash
# check-deploy-git.test.sh — vermelho/verde do gate check-deploy-git.sh.
# strict-ok: harness de teste — roda todos os casos e soma (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; G="$HERE/check-deploy-git.sh"; rc=0
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir "$T/bad" "$T/good"
printf '#!/bin/sh\nrsync -az ./dist/ deploy@vps:/srv/app/\n' > "$T/bad/deploy.sh"
printf '#!/bin/sh\nssh vps "cd /srv/app && ops deploy --sha $SHA"\n' > "$T/good/deploy.sh"
SKIP_GIT=1 bash "$G" "$T/bad" >/dev/null && { echo "FAIL: rsync remoto não detectado"; rc=1; }
SKIP_GIT=1 bash "$G" "$T/good" >/dev/null || { echo "FAIL: falso positivo"; rc=1; }
printf '#!/bin/sh\ntar cz . | ssh vps "tar xz"\n' > "$T/bad/b.sh"
out="$(SKIP_GIT=1 bash "$G" "$T/bad" 2>&1)"
grep -q 'b.sh' <<<"$out" || { echo "FAIL: tar|ssh não detectado"; rc=1; }
git -C "$T/good" init -q && git -C "$T/good" add -A && git -C "$T/good" -c user.name=t -c user.email=t@t commit -qm x
bash "$G" "$T/good" >/dev/null && { echo "FAIL: sem remote deveria falhar"; rc=1; }
[ "$rc" -eq 0 ] && echo "check-deploy-git.test: OK"
exit "$rc"
