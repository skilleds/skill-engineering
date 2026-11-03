---
description: schematize-engineering — audita/scaffolda o <projeto>_ops (interface única) e verifica o fluxo de ambientes, a instalação paralela (nproc) e a independência dos serviços
argument-hint: "[bootstrap | audit | install]"
---

Governe a operação do sistema pelo **`<projeto>_ops`** (`references/ops.md`). Plan-first: **audita, mostra o plano, pede aprovação, então executa** — e **nada toca o servidor fora do ops**.

## 1. Fluxo de ambientes (verifique primeiro)
Confirme que o pipeline força **dev local → teste local → GitHub → hml → prd** e que **nada vai direto pra hml/prd**:
- Deploy só aceita **artefato com proveniência git** (commit SHA); artefato sem origem no git é recusado.
- hml/prd com filesystem **read-only** (sem edição manual); **drift detection** ligado (o ops recusa/alerta divergência com o git).
- **VETADO editar código direto no servidor.** Achou edição manual → trate como incidente (archive), não como fluxo.

## 1.5. Layout, seed e redeploy destrutivo
Verifique/scaffolde (`references/ops.md` §2):
- O ops provisiona em **`/<app>/`** e **clona os repos dentro** (`/<app>/<app>_<ctx>`, ex. `/payle/payle_core`). Repo fora de `/<app>/` é achado.
- **`/<app>/.env` é o seeder global** — fonte única de config; nenhum serviço com config à parte fora do seed.
- **Redeploy é destrutivo na app:** `ops redeploy` clona o SHA exato num diretório **novo** (`/<app>/releases/<sha>/`, só com o seed), troca o symlink `current` de forma atômica e reinicia/rola sem downtime (sem patch in-place, sem drift). Prove idempotência: dois redeploys seguidos → mesmo estado.
- **Dados NUNCA no destrutivo:** banco/volumes/uploads preservados (migration reversível). Apagar dado é `ops reset`, **gated a dev/hml**, com confirmação — nunca prd.

## 1.6. Isolamento por usuário
Verifique/scaffolde (`references/ops.md` §3):
- **Um user Linux dedicado por serviço** (`payle_core`→user `payle_core`), nunca dois no mesmo user, nunca `root`; a pasta do repo pertence ao user.
- **Um systemd unit hardened por serviço** (`User=`, `NoNewPrivileges`, `ProtectSystem=strict`, `ProtectHome`, `PrivateTmp`, `ReadWritePaths` mínimo). Comprometer um serviço não alcança os outros nem o host.
- **Tudo criado pelo ops** (user, permissão, unit) — nunca à mão.

## 2. O ops é a interface única (100%)
Verifique/scaffolde a CLI do `<projeto>_ops` com comandos **idempotentes**, `--help` e saída machine-readable, cobrindo **todo** o ciclo sem depender da IA:
`bootstrap` · `install`/`up` · `update` · `config` · `migrate` (reversível) · `health`/`doctor` · `rollback` · `logs`/`troubleshoot` · `test` (test kit — schematize-qa).
- Se alguma operação de servidor **não** tem comando de ops, o gap é o achado: **crie o comando** — não faça por fora (`ssh` ad-hoc, editar arquivo, `docker`/`kubectl` na mão são vetados).
- Meta de completude: **`ops install` provisiona um servidor do zero** sozinho.

## 2.5. O ops como gate da IA (pisos 22–24; `references/ops.md` §8)
Audite o contrato — achado = BLOQUEIA:
- **Código só do git:** `bash .claude/skills/schematize-engineering/scripts/check-deploy-git.sh .` verde (sem scp/rsync/sftp/`kubectl cp`/`| ssh`/git bundle/SQL ou docker remoto; remote + árvore limpa + HEAD == upstream).
- **Canal único da IA:** `ssh` com chave exclusiva do agente e `command=` forçado ao CLI do ops (ou API com mTLS); shell interativo e comando livre recusados.
- **Allowlist de operações tipadas**, deny-by-default, parâmetros validados; **dry-run/plan** antes do apply; **confirmação humana** em destrutivo/irreversível; **rate-limit** e teto de blast radius; **log de auditoria append-only** (quem/quê/quando/parâmetros/resultado/diff); **kill-switch**; rollback.
- **Zero SQL livre:** banco somente por queries nomeadas e versionadas no git (leitura) e migrations versionadas (escrita); resultado de leitura com PII mascarado.
- **Falta comando?** implementa-se NO REPO do ops (via git); `ssh` ad-hoc continua vetado.
- **CI remoto fora de commit/PR:** `scripts/check-ci-triggers.sh` verde (piso 27).

## 3. Instalação paralela (= nproc)
A instalação/subida roda **em paralelo**, grau = **`nproc`** (default; `--jobs N`/`OPS_JOBS` sobrepõe). Decomponha por **serviço independente** e dispare em ondas de `nproc`. Serialização só onde há dependência **real e declarada** (ex.: migração antes do consumidor), mínima e explícita.

## 4. Independência (invariante — prioridade máxima)
Rode a instalação **em paralelo de propósito** para provar independência. Se **qualquer** erro só acontece em paralelo (race, porta/lock/arquivo disputado, serviço que não sobe sem outro):
- **PARE a feature.** É bug de **independência de runtime** (piso 10 / §2), não de instalação.
- O ops **expõe** a colisão (relatório: o que disputou o quê, quem esperou quem). **Proibido serializar pra mascarar.**
- Corrija: cada serviço sobe **sozinho**, sem exigir outro no boot, com degradação graciosa (outbox/retry/fila). Só então o paralelo volta a `nproc`.

## 5. Saída
Grave o plano/relatório em `<projeto>/<projeto>_archive/` (§28): estado do fluxo de ambientes, cobertura de comandos do ops (o que falta), tempo de install e grau de paralelismo, e qualquer colisão de independência encontrada (com a correção priorizada). Confirme ao usuário: fluxo ok? ops cobre 100%? install paralela em `nproc`? independência provada?
