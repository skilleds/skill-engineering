#!/usr/bin/env bash
# build-zip.test.sh — vermelho e verde plantados do build-zip.sh.
# O quê: monta uma "skill" de brinquedo (repo git com arquivos de corpo + lixo que NÃO pode ir
#   no asset) e prova que o zip tem o diretório de topo certo, o corpo, nenhum excluído, e é
#   byte a byte determinístico. Os VERMELHOS provam que o verificador enxerga um zip ruim.
# Saída: exit 0 se todos os casos passam, 1 se algum falhou.
# strict-ok: harness de teste — roda TODOS os casos e soma; com `-e` pararia no primeiro vermelho (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
rc=0
command -v python3 >/dev/null && command -v unzip >/dev/null || { echo "build-zip.test: SKIP (precisa de python3 e unzip)"; exit 0; }

S="$W/skill"; mkdir -p "$S/scripts" "$S/references" "$S/.git.d" "$S/.github" "$S/versions/0.1.0" "$S/assets"
cp "$HERE/build-zip.sh" "$S/scripts/"
printf -- '---\nname: x\n---\n' > "$S/SKILL.md"
echo corpo > "$S/references/a.md"; echo hook > "$S/assets/h.sh"; chmod +x "$S/assets/h.sh"
echo ci > "$S/.github/wf.yml"; echo snap > "$S/versions/0.1.0/SKILL.md"
echo i > "$S/install.sh"; echo r > "$S/README.md"; echo g > "$S/.gitignore"; echo z > "$S/velho.zip"
git -C "$S" init -q -b main && git -C "$S" config user.email t@t && git -C "$S" config user.name t
git -C "$S" config commit.gpgsign false
git -C "$S" add -A && GIT_COMMITTER_DATE="2026-01-02T03:04:05" GIT_AUTHOR_DATE="2026-01-02T03:04:05" git -C "$S" commit -qm c

# verifica "lista" (entradas do zip, uma por linha): exige topo + SKILL.md e proíbe os excluídos
verify() { # verify arquivo_lista -> imprime problemas; rc 0 = zip bom
  local l="$1" bad=0
  grep -q '^schematize-engineering/SKILL.md$' "$l" || { echo "falta schematize-engineering/SKILL.md"; bad=1; }
  grep -q '^schematize-engineering/references/a.md$' "$l" || { echo "falta references/a.md"; bad=1; }
  if grep -vq '^schematize-engineering/' "$l"; then echo "entrada fora do topo schematize-engineering/"; bad=1; fi
  if grep -Eq '(^|/)(\.git|\.github|versions)(/|$)|/(install\.sh|README\.md|\.gitignore)$|\.zip$' "$l"; then
    echo "contém item que devia ser excluído: $(grep -E '(^|/)(\.git|\.github|versions)(/|$)|/(install\.sh|README\.md|\.gitignore)$|\.zip$' "$l" | head -3 | tr '\n' ' ')"; bad=1
  fi
  return "$bad"
}
expect() { # expect "descrição" rc_esperado rc_real [saída]
  if [ "$3" -eq "$2" ]; then echo "  ok  $1"; else echo "  FALHOU $1 (rc=$3, esperado $2)"; echo "${4:-}" | sed 's/^/      /'; rc=1; fi
}

echo "── VERDE: build normal"
out=$(bash "$S/scripts/build-zip.sh" "$W/a.zip" 2>&1); expect "build sai 0" 0 $? "$out"
unzip -Z1 "$W/a.zip" > "$W/a.lst"
p=$(verify "$W/a.lst"); expect "zip tem topo, corpo e nenhum excluído" 0 $? "$p"
unzip -Z1 "$W/a.zip" | grep -q 'scripts/build-zip.sh' && echo "  ok  scripts/ vai no asset" || { echo "  FALHOU scripts/ ausente"; rc=1; }
perm=$(unzip -Zl "$W/a.zip" 2>/dev/null | awk '/assets\/h.sh/{print substr($1,4,1)}')
[ "$perm" = "x" ] && echo "  ok  bit de execução preservado" || { echo "  FALHOU bit x perdido ($perm)"; rc=1; }

echo "── VERDE: determinismo (2 builds, mesmo byte)"
sleep 1; bash "$S/scripts/build-zip.sh" "$W/b.zip" >/dev/null 2>&1
cmp -s "$W/a.zip" "$W/b.zip"; expect "zips idênticos" 0 $?

echo "── VERDE: o zip antigo no diretório não entra no novo (rebuild no lugar)"
bash "$S/scripts/build-zip.sh" "$S/skill-engineering.zip" >/dev/null 2>&1
bash "$S/scripts/build-zip.sh" "$W/c.zip" >/dev/null 2>&1
unzip -Z1 "$W/c.zip" | grep -q '\.zip$'; expect "nenhum .zip dentro do zip" 1 $?

echo "── VERMELHO: o verificador enxerga um zip ruim (planta de excluídos e de topo errado)"
printf 'schematize-engineering/SKILL.md\nschematize-engineering/references/a.md\nschematize-engineering/versions/0.1.0/SKILL.md\n' > "$W/r1.lst"
verify "$W/r1.lst" >/dev/null; expect "versions/ no zip é pego" 1 $?
printf 'schematize-engineering/SKILL.md\nschematize-engineering/references/a.md\nschematize-engineering/.github/wf.yml\n' > "$W/r2.lst"
verify "$W/r2.lst" >/dev/null; expect ".github/ no zip é pego" 1 $?
printf 'SKILL.md\nreferences/a.md\n' > "$W/r3.lst"
verify "$W/r3.lst" >/dev/null; expect "sem diretório de topo é pego" 1 $?

echo "── VERMELHO: saída em local impossível falha (não 'ok' mudo)"
bash "$S/scripts/build-zip.sh" "$W/arquivo-comum/x.zip" >/dev/null 2>&1; z=$?
[ "$z" -ne 0 ] && echo "  ok  destino inválido sai $z" || { echo "  FALHOU destino inválido saiu 0"; rc=1; }

[ "$rc" -eq 0 ] && echo "build-zip.test: OK" || echo "build-zip.test: FALHOU"
exit "$rc"
