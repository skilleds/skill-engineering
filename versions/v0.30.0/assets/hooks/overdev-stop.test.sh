#!/usr/bin/env bash
# overdev-stop.test.sh — o VERMELHO VISTO da trava do overdev (A6 e A6b da vistoria de 2026-08-21).
#
# Motivo: o hook contava UMA das tres classes de item aberto — um checklist inteiro de itens
# humanos ou de perguntas parkeadas dava open=0 e LIBERAVA a parada. E lia `$SD/state` enquanto
# a normativa documentava `state.json`: quem seguia a doc criava o arquivo errado e o hook ficava
# INERTE, saindo 0 em silencio — a trava do overdev nao existia na pratica.
# Entrada: nenhuma. Saida: exit 0 todos os casos passam - exit 1 algum caso falhou.
# strict-ok: harness de teste — roda todos os casos e soma; com `-e` pararia no primeiro vermelho
# (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/overdev-stop.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
rc=0
mkdir -p "$W/.schematize/overdev"
SD="$W/.schematize/overdev"

roda() { ( cd "$W" && echo '{}' | bash "$HOOK" 2>&1 ); }
bloqueia() { grep -q '"decision":"block"' <<<"$1"; }

echo "── inerte sem overdev nenhum"
W2="$(mktemp -d)"; OUT=$( cd "$W2" && echo '{}' | bash "$HOOK" 2>&1 ); rm -rf "$W2"
if [ -z "$OUT" ]; then echo "  ✔ silencio (nao engata fora de overdev)"; else echo "  ✖ falou: $OUT"; rc=1; fi

echo "── A6b: state.json (o formato DOCUMENTADO) e lido"
printf '{"mode":"active","max_iters":200}\n' > "$SD/state.json"
printf -- '- [ ] item de maquina\n' > "$SD/CHECKLIST.md"
OUT=$(roda)
if bloqueia "$OUT"; then echo "  ✔ bloqueou lendo state.json"; else echo "  ✖ ignorou state.json: $OUT"; rc=1; fi

echo "── A6b: CHECKLIST sem estado nenhum FALHA RUIDOSAMENTE (nao sai 0 em silencio)"
rm -f "$SD/state.json"; rm -f "$SD/iterations"
OUT=$(roda)
if bloqueia "$OUT" && grep -q 'SEM estado legivel' <<<"$OUT"; then echo "  ✔ bloqueou e explicou"; else echo "  ✖ ficou inerte: $OUT"; rc=1; fi

echo "── A6b: formato legado \`state\` (KEY=VALUE) segue aceito"
printf 'mode=active\nmax_iters=200\n' > "$SD/state"
OUT=$(roda)
if bloqueia "$OUT"; then echo "  ✔ compat mantida"; else echo "  ✖ quebrou o legado: $OUT"; rc=1; fi
rm -f "$SD/state"

echo "── A6: checklist SO com itens humanos NAO libera a parada"
printf '{"mode":"active","max_iters":200}\n' > "$SD/state.json"
printf -- '- [H ] criar repo na org\n- [H ] assinar contrato\n' > "$SD/CHECKLIST.md"
rm -f "$SD/iterations"
OUT=$(roda)
if bloqueia "$OUT" && grep -q "2 item(ns) '- \[H \]'" <<<"$OUT"; then echo "  ✔ bloqueou e mandou declarar BLOCKED"; else echo "  ✖ liberou: $OUT"; rc=1; fi

echo "── A6: checklist so com on-hold (- [~]) NAO libera a parada"
printf -- '- [~] pergunta parkeada sem resposta\n' > "$SD/CHECKLIST.md"; rm -f "$SD/iterations"
OUT=$(roda)
if bloqueia "$OUT" && grep -q "1 '- \[~\]'" <<<"$OUT"; then echo "  ✔ bloqueou (on-hold conta como aberto)"; else echo "  ✖ liberou: $OUT"; rc=1; fi

echo "── checklist 100% fechado LIBERA"
printf -- '- [x] feito\n- [H x] feito pelo humano\n' > "$SD/CHECKLIST.md"; rm -f "$SD/iterations"
OUT=$(roda)
if ! bloqueia "$OUT"; then echo "  ✔ liberou"; else echo "  ✖ travou sem item aberto: $OUT"; rc=1; fi

echo "── BLOCKED declarado LIBERA (o caminho legitimo do item humano)"
printf -- '- [H ] criar repo na org\n' > "$SD/CHECKLIST.md"; rm -f "$SD/iterations"
echo "faltam 1 item humano: criar repo na org" > "$SD/BLOCKED"
OUT=$(roda)
if ! bloqueia "$OUT"; then echo "  ✔ liberou com BLOCKED escrito"; else echo "  ✖ travou: $OUT"; rc=1; fi

echo
[ $rc -eq 0 ] && echo "✔ overdev-stop.test.sh: todos os casos" || echo "✖ overdev-stop.test.sh: falhou"
exit $rc
