<!--
FONTE ÚNICA — bloco "Precedência e herança (leia antes de divergir)" do SKILL.md.
Herdada pelas skills derivadas da schematize-engineering via `tools/sync-herdados.mjs`.
Editar = editar AQUI + `node tools/sync-herdados.mjs`; o CI roda --check.
Variantes: backend ({{linguagem}}), foraRol ({{intro}}, {{cmd}}), mobile ({{intro}}, {{cmd}}), dominio ({{intro}}, {{cmd}}).
Não escreva aqui o marcador "herdado" literal: este arquivo é a fonte, não um consumidor.
-->

<!-- variante:backend -->
Esta skill é o **recorte {{linguagem}}** da base. Duas regras governam a relação, e elas resolvem sozinhas
quase toda dúvida de "onde está escrito o quê":

1. **Onde esta skill divergir da base, a BASE MANDA.** `schematize-engineering` é a normativa; aqui
   mora a **especialização** — o mecanismo, a lib, a sintaxe, o gate da linguagem. Divergência de
   *piso* entre este arquivo e a base é **defeito desta skill**, não uma variante local aceitável.
   Achou uma? É item de correção, não licença. *(Foi assim que o `argon2id-only` da casa virou
   "argon2id ou PBKDF2" em uma skill só, e o rol de 6 linguagens virou "só Go e Rust" em três.)*
2. **O que não está repetido aqui é HERDADO, não dispensado.** A ausência de um piso neste repo
   nunca significa que ele não vale — significa que ele não muda de forma nesta linguagem. Em
   especial, valem integralmente, sem cópia local:
   - **§28 Archive** — `<projeto>/<projeto>_archive/` é **repositório git próprio, PRIVADO e
     obrigatório**, criticidade 0 (`schematize-archive`; ADR-0005 para a planta canônica).
   - **§39 Índice/MAPA** — enumeração exaustiva (uma entrada por unidade chamável, `M == N`) e o
     **grafo com arestas em ASCII (`A -> B`), NUNCA a seta unicode** — o parser do app lê ASCII.
   - **§35 Definition of Done** e a lista de anti-padrões **§37** (citada por **título**, nunca por
     número: a numeração dos itens diverge entre skills).
   - **IAM** (`schematize-engineering` → `references/iam.md`): identidade ≠ email, ≥2 fatores, ReBAC multi-tenant,
     **alcançabilidade do 2º fator** (o fator de recuperação tem de ser alcançável quando o
     principal cai — senão o 2FA vira bug de bootstrap que tranca o dono para fora), os parâmetros
     mínimos de argon2id, sessão longa e logout irreversível.
   - **Rol sancionado** — Go, Rust, Elixir, C#, Zig, Ruby, por **fit + ADR**
     (`schematize-engineering` → `references/linguagens.md`). Esta skill é **uma** delas, não a
     régua das outras.
   - **Efeito externo** nunca sai de não-produção (`schematize-engineering` →
     `references/efeitos-externos.md`; gate em `scripts/check-external-effects.sh`, distribuído
     aqui — ADR-0008).
<!-- /variante -->

<!-- variante:foraRol -->
{{intro}}

1. **Onde esta skill divergir da base, a BASE MANDA.** Aqui mora a especialização — a lib, o gate, a
   sintaxe da linguagem. Divergência de *piso* é defeito desta skill, não variante local.
2. **O que não está repetido aqui é HERDADO, não dispensado.** Valem integralmente, sem cópia local:
   - **§28 Archive** — `<projeto>/<projeto>_archive/` é **repositório git próprio, PRIVADO e
     obrigatório**, criticidade 0 (`schematize-archive`).
   - **§35 Definition of Done** e a lista de anti-padrões (citada por **título**, nunca por número).
   - **§39 Índice/MAPA** — enumeração exaustiva (uma entrada por unidade chamável, `M == N`) e grafo
     com arestas em ASCII (`A -> B`), nunca a seta unicode.
   - **IAM** (`schematize-engineering` → `references/iam.md`): identidade ≠ email, ≥2 fatores, ReBAC
     multi-tenant, argon2id-only para senha nova, sessão longa e logout irreversível.
   - **Efeito externo** nunca sai de não-produção (`schematize-engineering` →
     `references/efeitos-externos.md`).
   - **Orquestração** (`schematize-engineering` → `references/orquestracao.md` §9): o principal não
     desenvolve (é Claude Opus); executor mais barato que resolve — `haiku`/`sonnet` → Codex Terra → Cursor → `opus` só após falha; visual direto ao Codex; imagem nunca pelo Claude: detecta Codex/Gemini e pergunta ao usuário qual usar (Codex é a sugestão, não automática), nunca API paga.
3. **QA, ops, IAM e índice não têm comando próprio aqui:** vêm da base `/eng-*`. Para trabalho
   contínuo use `/eng-overdev`; para planejar `/eng-plan`; para varrer a base `/eng-scan`; para
   revisão geral `/eng-review` (e `/eng-ops`, `/eng-iam`, `/eng-index`). Os comandos
   `/{{cmd}}-*` cobrem só o piso da linguagem.
<!-- /variante -->

<!-- variante:dominio -->
{{intro}}

1. **Onde esta skill divergir da base, a BASE MANDA.** Aqui mora a especialização do domínio ou da
   ferramenta — o como, o padrão, o gate. Divergência de *piso* é defeito desta skill, não variante local.
2. **O que não está repetido aqui é HERDADO, não dispensado.** Esta skill herda os pisos da base e
   os comandos dela cobrem o **domínio**, não o piso geral. Valem integralmente, sem cópia local:
   - **§28 Archive** — `<projeto>/<projeto>_archive/` é **repositório git próprio, PRIVADO e
     obrigatório**, criticidade 0 (`schematize-archive`).
   - **§35 Definition of Done** e a lista de anti-padrões (citada por **título**, nunca por número).
   - **§39 Índice/MAPA** — enumeração exaustiva (uma entrada por unidade chamável, `M == N`) e grafo
     com arestas em ASCII (`A -> B`), nunca a seta unicode.
   - **IAM** (`schematize-engineering` → `references/iam.md`): identidade ≠ email, ≥2 fatores, ReBAC
     multi-tenant, argon2id-only para senha nova, sessão longa e logout irreversível.
   - **Efeito externo** nunca sai de não-produção (`schematize-engineering` →
     `references/efeitos-externos.md`).
   - **Orquestração** (`schematize-engineering` → `references/orquestracao.md` §9): o principal não
     desenvolve (é Claude Opus); executor mais barato que resolve — `haiku`/`sonnet` → Codex Terra → Cursor → `opus` só após falha; visual direto ao Codex; imagem nunca pelo Claude: detecta Codex/Gemini e pergunta ao usuário qual usar (Codex é a sugestão, não automática), nunca API paga.
3. **QA, ops, IAM e índice não têm comando próprio aqui:** vêm da base `/eng-*`. Para trabalho
   contínuo use `/eng-overdev`; para planejar `/eng-plan`; para varrer a base `/eng-scan`; para
   revisão geral `/eng-review` (e `/eng-ops`, `/eng-iam`, `/eng-index`). Os comandos
   `/{{cmd}}-*` cobrem o domínio desta skill; o piso geral é o da base.
<!-- /variante -->

<!-- variante:mobile -->
{{intro}}

1. **Onde esta skill divergir da base, a BASE MANDA.** Aqui mora a especialização — a lib, o gate, a
   sintaxe da linguagem. Divergência de *piso* é defeito desta skill, não variante local.
2. **O que não está repetido aqui é HERDADO, não dispensado.** Valem integralmente, sem cópia local:
   - **§28 Archive** — `<projeto>/<projeto>_archive/` é **repositório git próprio, PRIVADO e
     obrigatório**, criticidade 0 (`schematize-archive`).
   - **§35 Definition of Done** e a lista de anti-padrões (citada por **título**, nunca por número).
   - **§39 Índice/MAPA** — enumeração exaustiva (uma entrada por unidade chamável, `M == N`) e grafo
     com arestas em ASCII (`A -> B`), nunca a seta unicode.
   - **IAM** (`schematize-engineering` → `references/iam.md`): identidade ≠ email, ≥2 fatores, ReBAC
     multi-tenant, argon2id-only para senha nova, sessão longa e logout irreversível.
   - **Efeito externo** nunca sai de não-produção (`schematize-engineering` →
     `references/efeitos-externos.md`).
   - **Orquestração** (`schematize-engineering` → `references/orquestracao.md` §9): o principal não
     desenvolve (é Claude Opus); executor mais barato que resolve — `haiku`/`sonnet` → Codex Terra → Cursor → `opus` só após falha; visual direto ao Codex; imagem nunca pelo Claude: detecta Codex/Gemini e pergunta ao usuário qual usar (Codex é a sugestão, não automática), nunca API paga.
3. **Delegado à `schematize-mobile`, por nome:** IAM mobile (public client OIDC/PKCE, passkeys,
   Keychain/Keystore), ops, offline/sync, push, testes no device e entrega nas lojas
   (`schematize-mobile` → `references/testes-mobile.md`, `schematize-mobile` →
   `references/entrega-lojas.md`; comandos `/mobile-auth`, `/mobile-offline`, `/mobile-test`,
   `/mobile-release`). **Dependência:** instale a `schematize-mobile` junto; sem ela esses
   arquivos não existem no seu ambiente e o piso de app fica sem dono.
4. **QA, ops, IAM e índice não têm comando próprio aqui:** vêm da base `/eng-*`. Para trabalho
   contínuo use `/eng-overdev`; para planejar `/eng-plan`; para varrer a base `/eng-scan`; para
   revisão geral `/eng-review` (e `/eng-ops`, `/eng-iam`, `/eng-index`). Os comandos
   `/{{cmd}}-*` cobrem só o piso da linguagem.
<!-- /variante -->

