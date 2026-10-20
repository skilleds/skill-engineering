#!/usr/bin/env bash
# overdev-stop.sh — Stop hook do modo OVERDEV (schematize-engineering, /eng-overdev).
#
# O quê: quando o agente tenta PARAR, checa o CHECKLIST do overdev. Se ainda houver
#        QUALQUER item aberto — nas TRÊS classes da casa, "- [ ]" (máquina), "- [H ]"
#        (humano) e "- [~]" (on-hold/parkeado) — ou o gate de verificação falhar, REJEITA
#        a parada e força a continuação, registrando a tentativa (a "punição"). Assim o
#        agente só fala com o usuário quando o checklist estiver EFETIVAMENTE 100%.
# Onde:  hook `Stop` no settings.json (ver settings.claude.example.json). É INERTE
#        quando não há overdev ativo — seguro registrar global; só engata quando você
#        roda /eng-overdev (que cria .schematize/overdev/state.json mode=active).
#
# Contrato Claude Code (Stop hook): lê JSON no stdin; pra BLOQUEAR imprime
#   {"decision":"block","reason":"..."} e sai 0; pra PERMITIR sai 0 sem decisão.
#
# Estado (control-plane no root do projeto — trate como .git; gitignore).
# Layout novo `.schematize/overdev/` (canônico); `.overdev/` legado ainda aceito ($SD resolve):
#   $SD/state.json   CANÔNICO — {"mode":"active","max_iters":N,"archive":"<path>"}
#   $SD/state        legado KEY=VALUE (mode=active, max_iters=N, archive=<path>) — ainda lido
#   $SD/CHECKLIST.md  checklist nas TRÊS classes da casa:
#                     "- [ ]" máquina · "- [H ]" humano · "- [~]" on-hold · "- [x]"/"- [H x]" feito
#   $SD/iterations   contador de tentativas de parada
#   $SD/gate.sh      (opcional) verificação máquina; exit!=0 => NÃO terminou
#   $SD/DONE         escrito quando tudo verde → permite parar
#   $SD/BLOCKED      bloqueio real que exige o usuário → permite parar (avisando)

# strict-ok: hook do harness — ele NUNCA pode abortar por um comando que falhou (um `grep` sem
# match, um arquivo ausente): abortar aqui vira "hook não decidiu", e o Claude Code trata isso
# como PERMITIR a parada — ou seja, `set -e` aqui DESLIGA a trava do overdev em silêncio.
# (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail
cat >/dev/null 2>&1 || true   # consome o stdin (JSON do harness)

# Resolve o control-plane: layout novo `.schematize/overdev/` primeiro; `.overdev/` legado
# como fallback de compat; senão assume o novo.
if [ -d ".schematize/overdev" ]; then SD=".schematize/overdev"; elif [ -d ".overdev" ]; then SD=".overdev"; else SD=".schematize/overdev"; fi
STATE_JSON="$SD/state.json"; STATE_KV="$SD/state"; CL="$SD/CHECKLIST.md"

# A6b — DOIS formatos estavam documentados (`state` na doc do hook, `state.json` na normativa e na
# auditoria). Quem seguia a doc criava o arquivo que o hook não lia, e a trava do overdev
# simplesmente NÃO EXISTIA — o hook saía 0 em silêncio. Agora: state.json é o CANÔNICO, `state`
# segue aceito por compat, e a ausência dos dois COM overdev montado falha RUIDOSAMENTE.
jget() { # jget <arquivo> <chave>  — leitor de escalar de JSON plano, sem depender de jq
  sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",}]*\)\"\{0,1\}.*/\1/p" "$1" 2>/dev/null | head -1
}
if [[ -f "$STATE_JSON" ]]; then
  mode="$(jget "$STATE_JSON" mode)"; archive="$(jget "$STATE_JSON" archive)"; max="$(jget "$STATE_JSON" max_iters)"
elif [[ -f "$STATE_KV" ]]; then
  mode="$(grep -E '^mode=' "$STATE_KV" | head -1 | cut -d= -f2- || true)"
  archive="$(grep -E '^archive=' "$STATE_KV" | head -1 | cut -d= -f2-)"
  max="$(grep -E '^max_iters=' "$STATE_KV" | head -1 | cut -d= -f2-)"
elif [[ -f "$CL" ]]; then
  # Há CHECKLIST de overdev e NENHUM estado legível: é o modo de falha que apagava a trava.
  printf '{"decision":"block","reason":"OVERDEV montado (%s existe) e SEM estado legivel: nem %s nem %s. Crie %s com {\"mode\":\"active\",\"max_iters\":200} antes de continuar — sem ele a trava do overdev nao existe."}\n' \
    "$CL" "$STATE_JSON" "$STATE_KV" "$STATE_JSON"
  exit 0
else
  exit 0                                                      # inerte: sem overdev nenhum
fi
[[ "$mode" == "active" ]] || exit 0

[[ -n "${archive:-}" ]] || archive="$SD"
mkdir -p "$archive" 2>/dev/null || true
[[ "${max:-}" =~ ^[0-9]+$ ]] || max="${OVERDEV_MAX_ITERS:-200}"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo '?')"

emit_block() { local r="${1//\\/\\\\}"; r="${r//\"/\\\"}"; r="${r//$'\n'/\\n}"; printf '{"decision":"block","reason":"%s"}\n' "$r"; exit 0; }
allow()      { echo "[$ts] $1" >> "$archive/overdev.log" 2>/dev/null || true; exit 0; }

[[ -f "$SD/DONE" ]]    && allow "DONE — checklist 100%, parada permitida."
[[ -f "$SD/BLOCKED" ]] && allow "BLOCKED — $(head -1 "$SD/BLOCKED" 2>/dev/null)"

# Budget (guardrail anti-loop-infinito; alto e configurável — não é 'desistir').
it="$(cat "$SD/iterations" 2>/dev/null || echo 0)"; [[ "$it" =~ ^[0-9]+$ ]] || it=0
it=$((it+1)); echo "$it" > "$SD/iterations" 2>/dev/null || true
if (( it > max )); then
  echo "budget de $max ciclos atingido em $ts — pare e reporte o progresso e o que falta." > "$SD/BLOCKED"
  allow "BUDGET ($max) atingido após $it ciclos."
fi

# Verificação: itens abertos no checklist + gate de máquina (se houver).
# (grep -c imprime 0 e sai 1 quando não acha — NÃO use '|| echo 0', vira "0\n0".)
# A6 — a casa tem TRÊS classes de item aberto e o hook contava UMA. Checklist inteiro de itens
# humanos (ou de perguntas parkeadas) dava open=0 e LIBERAVA a parada, com o trabalho intocado.
conta() { local re="$1" n=0; [[ -f "$CL" ]] && n="$(grep -cE "$re" "$CL" 2>/dev/null)"; [[ "$n" =~ ^[0-9]+$ ]] || n=0; echo "$n"; }
open_maq="$(conta '^[[:space:]]*- \[ \]')"       # máquina fecha
open_hum="$(conta '^[[:space:]]*- \[H \]')"      # só humano fecha
open_hold="$(conta '^[[:space:]]*- \[~\]')"      # on-hold: pergunta parkeada, CONTA como aberto
open=$(( open_maq + open_hum + open_hold ))
gate_ok=1; gate_msg=""
if [[ -x "$SD/gate.sh" ]]; then
  if ! out="$(bash "$SD/gate.sh" 2>&1)"; then gate_ok=0; gate_msg=" | gate.sh FALHOU: $(echo "$out" | tail -1)"; fi
fi

if [[ ! -f "$CL" ]]; then
  emit_block "OVERDEV ativo mas sem $CL. Gere o CHECKLIST exaustivo do objetivo primeiro (um item verificável por linha, '- [ ]'), grave em $CL e em $archive/OBJETIVO.md, e comece."
fi

if (( open == 0 )) && (( gate_ok == 1 )); then
  allow "checklist 100% (maquina+humano+on-hold) e gate verde — pode declarar concluido (crie $SD/DONE)."
fi

# Máquina zerada mas sobra item HUMANO ou pergunta PARKEADA: o agente não pode fechar sozinho —
# e também não pode simplesmente parar como se tivesse acabado. Ele tem de declarar o bloqueio.
if (( open_maq == 0 )) && (( gate_ok == 1 )); then
  echo "[$ts] PARADA rejeitada: 0 itens de maquina, mas $open_hum humano(s) e $open_hold on-hold" >> "$archive/premature-stops.log" 2>/dev/null || true
  pend_h="$(grep -nE '^[[:space:]]*- \[(H |~)\]' "$CL" 2>/dev/null | head -n 8 | sed 's/"/\x27/g' || true)"
  emit_block "MODO OVERDEV — nao ha item de maquina aberto, mas o checklist NAO esta fechado: $open_hum item(ns) '- [H ]' (humano) e $open_hold '- [~]' (pergunta parkeada, conta como ABERTO). \
Parar aqui seria declarar pronto o que nao esta. Faca UMA das duas: (a) se algum '- [~]' na verdade da pra resolver sozinho, resolva e feche; (b) escreva $SD/BLOCKED listando exatamente os itens humanos e as perguntas parkeadas que precisam do usuario — ai a parada e permitida e o usuario ve o que falta. Itens:\n$pend_h"
fi

# Ainda há trabalho → REJEITA a parada (a 'punição') e re-injeta o que falta.
echo "[$ts] PARADA PREMATURA rejeitada (ciclo $it/$max): $open aberto(s) = $open_maq maquina + $open_hum humano + $open_hold on-hold$gate_msg" >> "$archive/premature-stops.log" 2>/dev/null || true
pend="$(grep -nE '^[[:space:]]*- \[ \]' "$CL" 2>/dev/null | head -n 8 | sed 's/"/\x27/g' || true)"
emit_block "MODO OVERDEV — NÃO PARE E NÃO DIGA QUE TERMINOU. Faltam $open item(ns) do checklist ($open_maq de maquina, $open_hum humanos, $open_hold parkeados)$gate_msg (ciclo $it/$max). \
NÃO fale com o usuário ainda. Abra $CL, pegue o PRÓXIMO item aberto, implemente de verdade, VERIFIQUE (rode o gate/teste), e só então marque '- [x]'. Itens abertos agora:\n$pend\n\
Só é permitido parar quando: (a) TODOS os itens '- [x]' e o gate passa → crie $SD/DONE; ou (b) bloqueio real que exige o usuário (segredo/credencial faltando, decisão irreversível, dependência externa, ambiguidade que muda o resultado) → crie $SD/BLOCKED com o motivo e a pergunta. Nada de 'acho que tá bom' nem entregar micro-função como se fosse o todo. Continue agora."
