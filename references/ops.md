# Operação pelo ops — ambientes, instalação e correção (control plane)

> Incidente em prd (severidade, comando, comunicação, postmortem): `schematize-incident → references/papeis-e-comando.md`. Aqui fica só o break-glass auditado.

> O **`<projeto>_ops`** é a **interface única** de operação do sistema. Invariantes desta reference, todos **INEGOCIÁVEIS**: (1) nada chega ao servidor sem passar pelo **fluxo de promoção** (dev local → teste local → GitHub → hml → prd); (2) o ops provisiona num **workspace por aplicação** (`/<app>/`) e todo **redeploy é destrutivo na aplicação, semeado pelo `/<app>/.env` global** — mas **nunca destrói dados**; (3) cada serviço roda **isolado por usuário** (user Linux + systemd hardened); (4) **100%** de instalação/atualização/correção/config passa por uma **ferramenta do ops** — nunca à mão; (5) instalar é **paralelo por padrão** (= `nproc`), e falha no paralelo = **bug de independência** (prioridade máxima). Contexto do ops: `arquitetura.md` §2. Deploy/ambientes: `operacao.md` §21. Test kit do sistema vivo: skill **schematize-qa**.

## 1. Ambientes e o fluxo de promoção (nada direto no servidor)

Ambientes isolados: **dev** (local) · **hml** (homologação/staging) · **prd** (produção). O caminho de qualquer mudança é **fixo e sem atalho**:

```
desenvolvimento local  →  teste local (verde)  →  GitHub (push em main)  →  hml  →  prd
```

- **Nada pula etapa.** Nunca vai direto pra hml ou prd. hml só recebe o que está no GitHub e passou no teste local; prd só recebe o que foi homologado em hml.
- **VETADO editar código direto no servidor (hml/prd).** O servidor é **imutável por edição manual** — recebe apenas **artefato promovido do git** (mesma imagem/commit SHA, §21). "Editei direto no prd pra resolver rápido" é o anti-padrão que esta reference existe pra matar.
- **Canal único de código = git (pisos 22/23).** **VETADO** `scp`, `rsync`, `tar | ssh`, `docker save | load`, `git bundle` ad-hoc, editar arquivo remoto e colar patch na VPS. Só o ops, **na VPS**, busca do remoto git (`clone`/`fetch` de SHA/tag exato, verificado, em diretório novo + troca atômica). Código não pushado não é deploy-ável.
- **Hotfix segue o mesmo fluxo, acelerado:** branch → teste local → git → hml → prd. Urgência **não** autoriza mão no servidor.
- **Única exceção escopada:** a máquina de build/teste dev/hml do piso 29, só para build/teste e dentro do workspace de build (§9); nunca deploy, nunca prd.
- **Precauções concretas:** deploy só aceita artefato com **proveniência git** (commit SHA); filesystem **read-only** em hml/prd; **drift detection** (o ops recusa/alerta divergência com o git); acesso de escrita = **exceção auditada** (break-glass no archive), nunca o fluxo.

## 2. Layout no servidor, seed global e redeploy destrutivo

O ops provisiona num **workspace por aplicação**, espelhando no servidor a contenção de workspace local (`arquitetura.md` §2):

- **`/<app>/` é a raiz da aplicação no servidor.** O ops **cria** essa pasta e **clona os repos dentro** dela: `/<app>/<app>_<contexto>` (ex.: `/payle/payle_core`, `/payle/payle_storage`, `/payle/payle_ops`). Nada de repo espalhado pelo host.
- **`/<app>/.env` é o SEEDER GLOBAL — a fonte única.** Toda a configuração da aplicação inteira parte desse arquivo. É a **única** fonte de verdade de config em runtime; **nenhum serviço tem config à parte** fora do seed. (Segredo real via secret manager referenciado pelo seed — segredo nunca versionado no repo.)
- **Redeploy é DESTRUTIVO na aplicação, a partir do seed.** Todo (re)deploy **clona o SHA/tag exato num diretório NOVO** (`/<app>/releases/<sha>/`, zerado, configurado **exclusivamente** a partir de `/<app>/.env`), **troca o symlink `/<app>/current` de forma atômica** e reinicia/rola os serviços (rolling/blue-green, `operacao.md` §21.1 — sem downtime), mantendo só a release anterior para rollback. Sem patch in-place, sem estado acumulado, sem drift. O estado da app é 100% derivado do seed → **idempotente e reprodutível**: `ops redeploy` sempre entrega o mesmo resultado, do zero.
- **"Destrutivo" é a APLICAÇÃO, nunca os DADOS.** O que é destruído e recriado: o clone dos repos, binários/build, config renderizada, o processo. O que é **preservado**: **dados persistentes** (banco, volumes, uploads, filas), que só mudam por **migration reversível** (com `down` + backup). Apagar dados é comando **separado e gated** (`ops reset`), **só em dev/hml**, com confirmação explícita — **nunca** em prd.

## 3. Isolamento por usuário — um user + systemd por serviço

Cada serviço roda **confinado**, pra que um comprometimento não vaze para os outros nem para o host (**blast radius mínimo**):

- **Um usuário Linux dedicado por serviço/repo.** `payle_core` roda como user `payle_core`; `payle_storage` como user `payle_storage`. **Nunca** dois serviços no mesmo user; **nunca** `root`. A pasta de cada repo pertence ao user do serviço (isolamento a nível de usuário no filesystem).
- **Um systemd unit isolado por serviço**, rodando como o user dedicado, com **hardening**: `User=<svc>`, `NoNewPrivileges=yes`, `ProtectSystem=strict`, `ProtectHome=yes`, `PrivateTmp=yes`, `ReadWritePaths=` só o necessário, `CapabilityBoundingSet=` mínimo.
- **Blast radius contido:** servidor comprometido por um serviço → o atacante mexe **só naquela** aplicação; os outros serviços (users/units/pastas distintos) e o host seguem protegidos. É defesa em profundidade por design.
- **Automatizado pelo ops, SEMPRE.** Criar o user, ajustar permissão da pasta, gerar o systemd unit hardened e fazer o wiring é **feito pelo ops** (`ops install`/`ops redeploy`) — **nunca à mão**. É parte do provisionamento, não um passo manual esquecível.

## 4. O ops é a interface única (100% das operações)

**Toda** operação sobre o servidor — instalar, subir, atualizar, configurar, migrar, corrigir, reverter, diagnosticar — passa por um **comando do `<projeto>_ops`**. **Zero** exceção:

- **Proibido** `scp`/`rsync`/`tar|ssh` de código para o servidor (piso 23), `ssh servidor` + comando ad-hoc, editar arquivo no servidor, `docker`/`kubectl`/`systemctl` na mão, script solto. Se **não existe** comando de ops pra aquilo, **cria o comando no ops** — não faz por fora. O que não está no ops não aconteceu (e não é reproduzível).
- **Autonomia e completude (requisito, não meta):** o ops é uma **aplicação/CLI coesa, idempotente e autodescritiva** que instala e opera o sistema inteiro **sem depender da IA**. Um humano — o próprio usuário — provisiona um servidor **do zero** só com o ops. `ops install` sobe tudo; `ops redeploy` recria do seed; `ops doctor` diagnostica tudo.
- **Superfície mínima** (idempotentes, com `--help` e saída machine-readable): `bootstrap` (cria `/<app>/` e clona os repos) · `install`/`up` · `redeploy` (destrutivo, do seed §2) · `update` · `config` (do `/<app>/.env`) · `migrate` (reversível) · `health`/`doctor` · `rollback` · `logs`/`troubleshoot` · `reset` (destrói dados — gated, dev/hml) · `test` (test kit — skill **schematize-qa**).
- **Correção/hotfix é `ops update`/`ops redeploy`/`ops rollback`** — nunca mão no servidor (§1). O ops sobe com observabilidade integrada (§16) e **grava o archive** de cada operação (§28).

## 5. Instalação SEMPRE paralela (= nº de cores)

Instalar/subir/recriar um sistema **não pode** levar 20 min em série.

- O ops instala/sobe/recria **módulos e microserviços em paralelo**, grau = **`nproc`** (default; `--jobs N`/`OPS_JOBS` sobrepõe).
- É o análogo em runtime do fan-out de orquestração (`references/orquestracao.md`): decompõe por **serviço independente** e dispara em ondas de `nproc`, com relatório de progresso.
- **Serialização só onde há dependência real e declarada** (ex.: migração de schema antes do serviço que a consome) — o **mínimo**, explícito no grafo de instalação, nunca "serializa tudo por via das dúvidas".

## 6. Independência é invariante — falha no paralelo = bug (PRIORIDADE MÁXIMA)

Se a instalação/subida **paralela falha** (race, porta/arquivo/lock disputado, um serviço que não sobe sem outro, ordem implícita), isso **prova** que os serviços **não são completamente independentes** — fere **independência de runtime** (`CLAUDE.md` piso 10, `arquitetura.md` §2) e **sem monólito distribuído** (piso 6).

- **Corrigir a independência é PRIORIDADE MÁXIMA** — acima de entregar feature. É defeito arquitetural que a instalação paralela apenas **revelou**.
- **O ops NÃO contorna serializando "pra funcionar".** Serializar pra mascarar a dependência é **proibido** — esconde o defeito. O ops **expõe** a colisão (relatório: o que disputou o quê, quem esperou quem) e a correção real é feita: **cada serviço sobe sozinho**, sem exigir outro no boot, com **degradação graciosa** (outbox/retry/fila; piso 10). Só depois o paralelo volta a `nproc`.

## 7. Integração com o resto da casa

| Tema | Onde |
|---|---|
| `<projeto>_ops` como control plane (bootstrap/update/manutenção) | `arquitetura.md` §2 |
| Deploy, ambientes, artefato imutável, rollback, preview | `operacao.md` §21 |
| Test kit do sistema vivo (roda pelo ops) | skill **schematize-qa** |
| Observabilidade integrada do ops | `observabilidade.md` §16 |
| Independência de runtime / sem monólito distribuído | `CLAUDE.md` pisos 10 e 6 |
| Segredo nunca versionado (o seed referencia o secret manager) | `seguranca.md` |
| Paralelização (o análogo em execução do agente) | `references/orquestracao.md` |
| Archive de cada operação | `operacao.md` §28 (`<projeto>/<projeto>_archive/`) |

## 8. Contrato de gate da IA (pisos 22, 23 e 24)

> O ops é a **única porta** da IA para a VPS. A IA pode delirar; por isso ela nunca tem mão direta, só operações nomeadas, tipadas e auditadas.

### 8.1 Bootstrap (o único contato direto permitido)
1. Atualizações automáticas do SO (`unattended-upgrades`/apt no Debian) — configuradas uma vez, sem a IA decidir pacote a pacote.
2. Instalar o mínimo para rodar o ops (`git` e afins) e executar **`git clone` do repo do ops**. **Nada mais** por `ssh` direto.
3. A partir daí: a IA invoca o ops pelo **canal único**: `ssh` com chave exclusiva do agente e `command=` forçado no `authorized_keys` (só executa o CLI do ops — `ssh vps "ops <op> …"` é a ÚNICA forma permitida; shell interativo e comando livre vetados) **ou** API do ops com mTLS, identidade `agent`; o ops clona/atualiza os demais repos do git (`/<app>/<app>_<ctx>`).

### 8.2 Catálogo mínimo de capacidades do ops
- **Leitura (rica e segura):** logs por serviço com filtro/tail · status/health · métricas · sistema (CPU/RAM/disco/rede/portas/processos/systemd) · versões (SHA em execução por serviço) · config renderizada **com segredo mascarado** · conexões · filas · jobs · diff/drift vs git · banco **somente-leitura** por **queries nomeadas e versionadas no git** (nunca SQL livre).
- **Escrita (tipada):** deploy/redeploy (de SHA/tag) · rollback · restart · migrate (só migrations versionadas) · backup/restore · rotacionar segredo · reset (só dev/hml). Cada operação tem schema de parâmetros validado.

### 8.3 Anatomia dos guardrails
- **Allowlist de operações tipadas, deny-by-default**; parâmetro fora do schema é recusado.
- **Dry-run/plan antes do apply**; o apply referencia o plano aprovado.
- **Confirmação humana** para destrutivo/irreversível; o agente não se autoconfirma.
- **Rate-limit e teto de blast radius** (nº de serviços/linhas/hosts por operação).
- **Escopo por ambiente**: prd mais restrito que hml/dev.
- **Identidade do chamador** (`agent` vs `human`) em toda chamada; permissões distintas.
- **Kill-switch** que suspende toda escrita do agente; **rollback** para toda operação de escrita.
- **Migrations só as versionadas no git**; a IA não passa SQL.

### 8.4 Log de auditoria
Append-only (fora do alcance do agente), uma linha por chamada: `quem` (identidade) · `quê` (operação) · `quando` · `parâmetros` (segredo mascarado) · `resultado` · `diff` (antes/depois, quando escreve) · `plano`/`confirmação` referenciados · `trace_id`. Sem linha de auditoria, a operação não aconteceu.

### 8.5 Falta comando → implementa no repo do ops
1. A IA percebe que a operação não existe; **não** contorna por `ssh`.
2. Implementa o comando **no repo do ops** (tipado, com guardrails, teste e doc).
3. Commit + push (piso 22) e review; 4. **deploy do próprio ops via ops/git** (piso 23); 5. só então usa o comando novo.

### 8.6 Break-glass
Acesso humano, auditado e registrado no archive, continua existindo. **Nunca para a IA.**

Comando: **`/<slug>-ops`** (ex.: `/eng-ops`, `/go-ops`) — audita/scaffolda o ops, verifica o fluxo de ambientes, o layout `/<app>/` + seed, o isolamento por usuário, a paralelização (`nproc`) e a independência.

> Regra de bolso: **nada toca o servidor fora do ops (a IA, nem com ssh); código só chega via git (nunca scp/rsync); nada chega ao servidor sem git + teste local; todo redeploy nasce do `/<app>/.env` (destrói a app, preserva os dados); cada serviço tem seu user.** Instalar é paralelo por padrão; se o paralelo quebra, o bug é de independência — a correção mais urgente que existe.

## 9. Máquina de build/teste (dev/hml) — exceção escopada do piso 29

> **FLAG PARA O USUÁRIO:** esta seção abre UMA exceção às regras absolutas dos pisos 14/23/24 (ponte direta e alteração na máquina). Ela é curta de propósito, para o escopo poder ser apertado. Fora do que está escrito aqui, os pisos 14/23/24 valem inteiros.

**Regra.** Se o projeto tem máquina **dev e/ou hml** (hml, **nunca staging**) com papel de build/teste, o agente **evita buildar local** e roda ali tudo o que for possível (build, testes unitários/integração, imagens, benchmarks); o local só edita e roda gates baratos. Sem essa máquina: build local, sem cerimônia. Em ambos os casos vale a higiene (abaixo).

### 9.1 Inventário `<projeto>_ops/maquinas.yml` (na falta, `<projeto>_archive/maquinas.yml`)
```yaml
maquinas:
  - nome: build-dev-1
    host: 10.0.0.5            # ssh configurado por chave; nunca senha no arquivo
    env: dev                  # dev | hml  (prd e staging reprovam no gate)
    papel: build-teste
    ponte_direta: true        # liga a exceção do piso 29, só para esta máquina
    workspace: /var/tmp/schematize-build/<projeto>/   # único lugar onde a ponte escreve
    limite_disco_pct: 80      # acima disso higieniza ANTES de novo build
    limite_cpu: 4             # nº de jobs paralelos (governador de concorrência)
```
Lint: `scripts/check-build-host.sh maquinas.yml` (+ teste). Sem entradas, o arquivo não deve existir.

### 9.2 Fluxo
1. **Detectar** — ler o inventário; sem máquina dev/hml → build local (e higiene local no fim).
2. **Higienizar se preciso** — disco da máquina acima de `limite_disco_pct`: `higiene.sh --workspace <ws> --if-above <pct> --apply` antes de começar.
3. **Sync** — `rsync`/`scp` da árvore de trabalho **apenas para o `workspace`** da máquina (nunca fora dele; nunca `.env`/segredo real de prd).
4. **Build/teste remoto** — `ssh` rodando build e testes dentro do workspace; paralelismo ≤ `limite_cpu`.
5. **Coletar** — trazer só o resultado (logs, relatórios, números); artefato de build fica lá e é descartável.
6. **Higienizar** — `higiene.sh --workspace <ws> [--keep-last N] [--docker]`, conferir o dry-run, depois `--apply`; o mesmo no local se buildou local. Medir disco antes/depois.
7. **Registrar** — no relatório de 30 min (`orquestracao.md` §9.8): o que foi enviado, o que rodou, disco antes/depois e "recursos liberados".

### 9.3 Limites da exceção (sem alargar)
- **Permitido:** ponte direta (rsync/scp/ssh), sync da árvore de trabalho e comando mutável **somente para build/teste, dentro do workspace remoto**.
- **Continua VETADO:** qualquer ponte direta a **prd**; deploy "oficial" de dev/hml por ponte (só do git, via ops, pisos 23/24); segredo real de prd na máquina; tocar dados, volumes, banco, uploads ou `.env` de serviços ali existentes; efeito externo real (piso 18).
- **NÃO é promovível:** o que o build produziu por ponte não vira artefato de hml/prd. Promover = commit + push + **build limpo a partir do git** (SHA verificado).

### 9.4 Higiene (`scripts/higiene.sh`)
Dry-run por padrão (lista caminho e tamanho); `--apply` explícito; escopo = `--workspace` + `--allow` (nada fora); `--keep-last N` poupa o cache mais recente; `--expire-days N` remove workspaces filhos vencidos; `--docker` limpa containers parados, imagens dangling, build cache e volumes **anônimos**; `--if-above PCT` só roda acima do limiar; log em `<ws>/.higiene.log` (ISO, ação, caminho, bytes). Apaga: `target/`, `build`, `dist`, `.next`, `node_modules/.cache`, `__pycache__`, `.pytest_cache`, `.gradle`, `obj`/`bin`, `_build`/`deps`, `zig-cache`. **Nunca** apaga volume nomeado, banco, uploads, `.env*`, `*_archive`, `.git`, caminho versionado no git, repo com commit não pushado ou árvore suja, symlink, nem nada fora do escopo.
