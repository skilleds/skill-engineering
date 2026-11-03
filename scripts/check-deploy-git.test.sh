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
# vermelho: cada furo achado na revisão G1 (um arquivo por caso; SKIP_GIT=1)
caso() { # nome, linha, trecho esperado
  rm -rf "$T/c"; mkdir "$T/c"; printf '#!/bin/sh\n%s\n' "$2" > "$T/c/x.sh"
  out="$(SKIP_GIT=1 bash "$G" "$T/c" 2>&1)" && { echo "FAIL: '$1' deveria reprovar"; rc=1; return; }
  grep -q "$3" <<<"$out" || { echo "FAIL: '$1' sem '$3' em: $out"; rc=1; }
}
bom() { rm -rf "$T/c"; mkdir "$T/c"; printf '#!/bin/sh\n%s\n' "$2" > "$T/c/x.sh"
  SKIP_GIT=1 bash "$G" "$T/c" >/dev/null 2>&1 || { echo "FAIL: falso positivo '$1'"; rc=1; }; }
caso "sftp" 'sftp deploy@vps:/srv/app' 'sftp'
caso "kubectl cp" 'kubectl cp ./a pod:/b' 'kubectl'
caso "cat|ssh" 'cat a.tgz | ssh vps "tar x"' 'ssh'
caso "ssh sed -i" 'ssh vps "sed -i s/a/b/ /etc/x"' 'mutável'
caso "ssh tee" 'ssh vps "echo x | tee /etc/y"' 'mutável'
caso "ssh redirect remoto" 'ssh vps "echo x > /etc/y"' 'mutável'
caso "ssh psql DROP" 'ssh vps "psql -c \"DROP TABLE x\""' 'mutável'
caso "ssh systemctl" 'ssh vps systemctl restart app' 'mutável'
caso "ssh heredoc" 'ssh vps <<EOF' 'stdin'
caso "ssh < arquivo" 'ssh vps "bash -s" < deploy.sh' 'stdin'
caso "psql remoto -h" 'psql -h db.prod.internal -c "select 1"' 'banco REMOTO'
caso "psql URL remota" 'psql postgres://u:p@db.prod:5432/app -c x' 'banco REMOTO'
caso "docker -H ssh" 'docker -H ssh://vps ps' 'docker em host remoto'
caso "DOCKER_HOST ssh" 'DOCKER_HOST=ssh://vps docker compose up' 'docker em host remoto'
caso "docker context" 'docker context create prd --docker host=ssh://vps' 'docker em host remoto'
caso "git bundle" 'git bundle create /tmp/r.bundle --all' 'bundle'
caso "scp -r" 'scp -r dist vps:/srv' 'scp'
caso "rsync --rsh" 'rsync --rsh="ssh -p 2222" -a dist/ vps:/srv/' 'rsync'
caso "rsync -e ssh" 'rsync -a -e ssh dist/ vps:/srv/' 'rsync'
caso "ansible" 'ansible-playbook -i vps deploy.yml' 'ansible'
bom "ssh ops" 'ssh vps "ops deploy --sha $SHA"'
bom "ssh ops status" 'ssh -i key agent@vps ops status'
bom "psql local" 'psql -h localhost -c "select 1"'
bom "comentário que cita scp" '# nunca: scp -r dist vps:/srv'
bom "linha isenta" 'rsync -a x vps:/srv  # check-deploy-git: ok'
# exceção escopada do piso 29: host+workspace de maquinas.yml (dev/hml); fora do workspace ou host prd continua vermelho
mkdir -p "$T/m/p_ops"; printf 'maquinas:\n  - nome: b1\n    host: build1.dev.lan\n    env: dev\n    papel: build-teste\n    ponte_direta: true\n    workspace: /var/tmp/schematize-build/p/\n    limite_disco_pct: 80\n    limite_cpu: 4\n' > "$T/m/p_ops/maquinas.yml"
printf '#!/bin/sh\nrsync -a ./ deploy@build1.dev.lan:/var/tmp/schematize-build/p/src/\n' > "$T/m/build.sh"
SKIP_GIT=1 bash "$G" "$T/m" >/dev/null 2>&1 || { echo "FAIL: ponte ao workspace de build (maquinas.yml) deveria passar"; rc=1; }
printf '#!/bin/sh\nrsync -a ./ deploy@build1.dev.lan:/srv/app/\n' > "$T/m/build.sh"
SKIP_GIT=1 bash "$G" "$T/m" >/dev/null 2>&1 && { echo "FAIL: fora do workspace deveria reprovar"; rc=1; }
printf '#!/bin/sh\nrsync -a ./ deploy@prd1.example.com:/var/tmp/schematize-build/p/src/\n' > "$T/m/build.sh"
SKIP_GIT=1 bash "$G" "$T/m" >/dev/null 2>&1 && { echo "FAIL: host fora do inventário deveria reprovar"; rc=1; }
git -C "$T/good" init -q && git -C "$T/good" add -A && git -C "$T/good" -c user.name=t -c user.email=t@t commit -qm x
bash "$G" "$T/good" >/dev/null && { echo "FAIL: sem remote deveria falhar"; rc=1; }
[ "$rc" -eq 0 ] && echo "check-deploy-git.test: OK"
exit "$rc"
