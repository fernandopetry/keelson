# Segurança (core)

> Checklist de segurança **agnóstico de stack** — a base que vale para qualquer
> aplicação. Instancia o **Art. 2** (seguro por padrão; negar por padrão) do
> `../_meta/QUALITY-CHARTER.md`. **Vulnerabilidade é rejeição imediata** no code review
> (gate de segurança).
>
> O *como se resolve na sua linguagem* (função de escape, driver parametrizado, API de
> hash, flags de cookie) **não** entra aqui — fica na seção de segurança do perfil de
> linguagem (`../backend/*.md`, `../frontend/*.md`), que mapeia cada item abaixo à stack.

---

## OWASP Top 10 — superset consolidado (todas as edições)

Esta tabela é a **união** das edições (2003→2025) — os ataques não morrem quando a
categoria muda de nome/posição. Texto integral de cada edição: <https://github.com/OWASP/Top10>.

A coluna **CWE** dá a cada categoria o identificador estável do catálogo MITRE
(<https://cwe.mitre.org/>) — é o que qualquer outro framework de segurança (ASVS, NIST,
checklists de conformidade) usa como chave comum. O achado do gate 8 cita o CWE **desta
tabela** (ou da tabela *Outras vulnerabilidades*), nunca de memória; categoria sem
correspondência aqui sai sem CWE.

| Categoria | CWE | Prevenção (agnóstica) |
|-----------|-----|-----------------------|
| **Broken Access Control** | CWE-284, CWE-862 | Verificar autorização em **toda** ação; **negar por padrão** |
| **Cryptographic Failures** | CWE-327, CWE-916, CWE-319 | Hash de senha com algoritmo dedicado, com sal e custo (ex.: Argon2/bcrypt/scrypt); TLS em trânsito; nunca logar dado sensível |
| **Injection** (inclui XSS) | CWE-89, CWE-79, CWE-78 | Consultas/comandos **parametrizados**; escapar a saída no destino; validar a entrada |
| **Insecure Design** | CWE-602 | Validar sempre no servidor; **nunca** confiar no cliente |
| **Security Misconfiguration** (inclui XXE) | CWE-16, CWE-611, CWE-489 | Debug desligado em produção; cabeçalhos de segurança; parser XML sem entidades externas |
| **Software Supply Chain Failures** (amplia Vulnerable Components) | CWE-1104, CWE-1357, CWE-829 | Lockfile commitado; auditar dependências contra o advisory database do ecossistema (ver seção *Dependências & CVE* abaixo); conferir a procedência do pacote (typosquatting) |
| **Authentication Failures** | CWE-287, CWE-307, CWE-384 | Rate limiting; MFA; sessões seguras |
| **Software/Data Integrity Failures** (inclui deserialização insegura) | CWE-502, CWE-345, CWE-494 | Verificar integridade de uploads e artefatos; CSP; nunca deserializar entrada não confiável |
| **Security Logging & Alerting Failures** | CWE-778, CWE-532 | Logar tentativas de acesso; **nunca** logar senhas/tokens/PII — e saída de agente/ferramenta que tocou credencial (retorno de subagent, evento de ledger, closure, report) **é log** para esta regra: material sensível, mesma classe da saída E2E autenticada (`core/TESTING.md`) |
| **SSRF** | CWE-918 | Validar/allowlist de URLs externas; recusar IPs internos |
| **Mishandling of Exceptional Conditions** | CWE-755, CWE-636, CWE-209 | Erro trata **fail-closed** — exceção nunca deixa recurso em estado permissivo; detalhe interno não chega à resposta |
| **CSRF** | CWE-352 | Token anti-CSRF em mutações autenticadas por cookie; `samesite` no cookie de sessão |

---

## Outras vulnerabilidades

| Vulnerabilidade | CWE | ❌ Errado | ✅ Correto |
|-----------------|-----|-----------|------------|
| **Path Traversal** | CWE-22 | Abrir caminho vindo cru da entrada | Validar/normalizar; restringir à raiz permitida |
| **Command Injection** | CWE-78 | Interpolar entrada num comando de shell | Evitar shell; passar argumentos escapados/separados |
| **Mass Assignment** | CWE-915 | Preencher a entidade com todo o payload | Allowlist explícita de campos |
| **IDOR** | CWE-639 | Aceitar um id de recurso sem checar acesso | Verificar que o solicitante pode acessar **aquele** registro |
| **Race Condition** | CWE-367 | *Check-then-act* sem exclusão | Transação/lock; operação atômica |
| **Corrida de limite/unicidade** (decisão 4.177) | CWE-362 | Fechar com lock de **leitura** sobre a decisão (contagem/CASE lido antes de gravar — em subconsulta, o lock nem alcança a leitura) | Fechar **na escrita**: escrita condicional (o INSERT/UPDATE carrega o predicado; zero linhas afetadas **é** a recusa) ou constraint única. Prova **conta linhas** no fim, N concorrentes contra o motor real — cronometrar espera de lock já aprovou limite furado |
| **Information Disclosure** | CWE-209 | Stack trace em produção; erro interno devolvido cru na resposta | Mensagem genérica; sanear o **mesmo** valor no sink de resposta, não só no de log |
| **Clickjacking** | CWE-1021 | Sem proteção de enquadramento | Negar enquadramento (frame-ancestors/`X-Frame-Options`) |
| **File Upload** | CWE-434 | Aceitar qualquer arquivo | Allowlist de tipo/extensão; validar o conteúdo real |
| **Open Redirect** | CWE-601 | Redirecionar para destino vindo da entrada | Allowlist de destinos permitidos |
| **Credencial via shell** (decisão 4.236) | CWE-532 | Carregar arquivo de ambiente com `source`/`export` — o arquivo vira script: substituição de comando executa e a falha de parse **ecoa o segredo** na mensagem de erro (caso real: senha em texto plano no transcript) | Parser de chave=valor que não interpreta o conteúdo (dotenv/equivalente); a mensagem de erro do parser nunca é repassada |

---

## Padrões de autorização (negar por padrão)

Estes padrões são **agnósticos** — o mecanismo concreto está no perfil, mas a regra vale
para qualquer stack:

- **Permissão por rota/ação:** a permissão exigida **DEVE** ser lida da fonte que de fato
  a carrega, com a verificação de autorização rodando **depois** de a rota ser resolvida.
  Uma leitura errada que devolva "nenhuma permissão exigida" **DEVE** falhar fechado
  (negar) — nunca liberar tudo em silêncio.
- **Prova do 403:** todo gate de autorização exige teste de integração provando **negação
  sem a permissão** (não só sucesso com ela), exercitando a pilha real de middleware na
  ordem de produção (ver `./TESTING.md`).
- **Catálogo consistente:** o código de permissão é idêntico entre a definição no código,
  o armazenamento persistido (permissões + concessões aos papéis) e a checagem no cliente.
  O armazenamento **deployado** é a fonte da verdade. Uma rede de proteção compara os três.
- **Escopo de tenant/instância:** o identificador de tenant tem **ponto único** de
  população, vindo da **sessão do lado do servidor** — nunca de header, query ou path.
  Leitores negam por padrão quando ele está ausente (nunca um default permissivo como
  "assume o tenant 1").
- **Leitura em lote devolve mapa parcial — ausência é negação (decisão 4.176):** quando
  o escopo (tenant, dono, permissão) é aplicado **no próprio filtro** da consulta em
  lote, o id fora do escopo simplesmente não volta — o "não" é implícito, e nada obriga
  o consumidor a tratá-lo. O consumidor trata chave ausente do mapa como **negação**
  (pula ou lança), nunca como default de negócio — `?? default` sobre mapa indexado é
  permissivo por construção. O teste do consumidor cobre o **mapa incompleto**; havendo
  chunking, o vetor fora de escopo entra no **segundo** lote, com um controle dentro do
  escopo no mesmo lote — sem o controle, o teste passa por vacuidade com o lote inteiro
  descartado.
- **Serializadores de dado sensível:** default **fail-closed** — omitir o dado sensível
  por padrão, ou exigir um parâmetro explícito para incluí-lo. Nunca "inclui tudo a menos
  que peçam para não".
- **Acesso por registro:** ao restringir o acesso a um registro, enumere as superfícies
  pelo **dado exposto** (procure toda consulta/junção/projeção da entidade), incluindo
  subsistemas com permissão própria (e-mail, export, relatórios) — não só a permissão de
  leitura principal.
- **Guarda no sink, não na superfície:** exigência de step-up (senha, reautenticação,
  MFA) para uma operação sensível mora no ponto que **escreve/efetiva** o dado (o use
  case/endpoint de gravação), não na tela nem no passo que a UI chama primeiro. Ao
  proteger a operação, enumere **todos os caminhos que gravam** o dado protegido (rotas,
  use cases, jobs, comandos) e prove a recusa em **cada um** — a superfície que a UI
  percorre é sempre subconjunto da superfície real. Espelho do "Acesso por registro"
  acima, para o lado da **escrita**.

---

## Dependências & CVE (NVD)

Vulnerabilidade **conhecida** tem registro público: o **CVE** (Common Vulnerabilities and
Exposures), catalogado no **NVD** (<https://nvd.nist.gov/>). A checagem é sempre por
**ferramenta** — o auditor do ecossistema consulta um advisory database sincronizado com
o CVE/NVD:

- **Rodar a ferramenta de auditoria do ecossistema** sobre o lockfile — a nomeada no
  perfil ativo (genérico: `osv-scanner`).
- Achado de dependência vulnerável **cita o CVE/advisory ID** vindo da saída da
  ferramenta. **Nunca** afirmar ou descartar um CVE de memória — sem ferramenta, não há
  resposta confiável.
- Sem ferramenta disponível para o ecossistema → a lacuna **DEVE** ser reportada
  ("auditoria de dependências indisponível"), nunca silenciada.
- Lockfile **commitado**; mudança de dependência é sensível por definição (gatilho do
  gate de segurança).
- **Quando roda**: no gate, apenas quando a mudança toca dependências (manifesto/
  lockfile) — e uma vez na entrega. CVE publicado **depois** de a dependência entrar não
  aparece em diff nenhum: esse caso exige auditoria **fora do ciclo de task** — manual em
  momento oportuno (`/keelson:audit`) e, para cobertura contínua, alertas do repositório
  (Dependabot/Renovate) ou CI agendada, que não são papel do gate.

---

## Checklist final

- [ ] Toda consulta/comando a dados externos é **parametrizada** (sem concatenar entrada)
- [ ] Toda saída é escapada no contexto de destino; nada de renderização crua de PII
- [ ] Toda ação verifica autorização **antes** de executar, negando por padrão
- [ ] Gate de autorização tem teste provando a **negação** sem a permissão
- [ ] Step-up/reautenticação exigido no **ponto de escrita**, com recusa provada em **todos** os writers do dado (não só no caminho da UI)
- [ ] Senhas com algoritmo de hash dedicado; sem MD5/SHA1 puros
- [ ] Segredos vêm de configuração/secret store — nunca hardcoded, em log ou em URL
- [ ] Token de autenticação fora de armazenamento acessível a script do cliente; transporte seguro (ex.: cookie `httpOnly`/`secure`/`samesite`)
- [ ] Sem dado sensível/PII em logs nem em telemetria
- [ ] Arquivo de ambiente/credencial lido por parser que não interpreta shell — nunca `source`/`export`; erro do parser não ecoa o conteúdo
- [ ] Redirecionamentos e uploads restritos por allowlist
- [ ] Mutação autenticada por cookie exige token anti-CSRF
- [ ] Erro/exceção trata fail-closed; sem stack trace/detalhe interno na resposta
- [ ] Dependências auditadas contra o advisory database (CVE), com lockfile commitado

---

## Veredito de aprovação (gate 8) — decisão 4.264

**APROVADO sem achado viaja com inventário contável.** "Nenhuma vulnerabilidade" sem
denominador é indistinguível de "não olhei": o report de aprovação enumera cada categoria
do checklist **aplicável ao diff da rodada** com a superfície conferida — `arquivo:linha`
ou contagem — escopado ao diff e ao escopo sensível declarado, nunca ao repositório
inteiro. O inventário é **fato que acompanha o veredito, nunca o decide sozinho** (o
julgamento segue do revisor — número não vira oráculo); enumeração produzida por comando
carrega controle positivo no mesmo universo (mesma régua da evidência mecânica de
ausência do avaliador — `core/CODE-REVIEW.md`, 4.186). Aprovação sem inventário é
**report inválido** para quem o aceita.

---

---
name: security-engineer
description: "Gate 8 (segurança) de /keelson:implement, :review, :merge e modo sob demanda (4.75): revisa o diff contra core/SECURITY.md + §6 do perfil ativo. Roda com gates.security e mudança sensível — lista canônica: auth, autorização, injeção/consulta, upload, dados pessoais, crypto, sessão/cookies, endpoints, redirect, exec, dependências."
tools: Read, Bash, Glob, Grep
model: opus
---

# Subagent: security-engineer

Você é um Application Security Engineer focado em **revisar segurança** do código que outro agente escreveu, usando o **Gabarito** abaixo como referência objetiva. Você **não implementa** código.

**Princípio inviolável** (QUALITY-CHARTER, Art. 2 — seguro por padrão): vulnerabilidade = **REJEIÇÃO IMEDIATA**.

**Negar por padrão**: na dúvida sobre controle de acesso, assuma inseguro até prova em contrário.

## Input esperado

- **Briefing destilado da main session** (preferencial): ACs vinculados literais, DECs que tocam o escopo, arquivos modificados (`git diff --name-only`), `sensitiveGlobs` da ficha
- **Modo wave (ciclo — decisão 4.90)**: o diff é o **acumulado da wave**, com mapa TASK→arquivos — a interação entre TASKs é parte do seu escopo (um writer novo numa TASK + uma guarda relaxada noutra é exatamente o que a revisão isolada não vê); achado roteado à TASK de origem
- Report do `developer` (YAML) e/ou lista de arquivos modificados; (opcional) `git diff` da mudança
- TASK/PLAN completos só para conferência pontual

## Gabarito (leia em runtime — fonte única, não trabalhe de memória)

1. **`${CLAUDE_PLUGIN_ROOT}/guidelines/core/SECURITY.md`** — superset OWASP multi-edição (nomes canônicos), demais vulnerabilidades, padrões agnósticos e a política de *Dependências & CVE*. O checklist é o desse arquivo.
2. **Seção de segurança (seção 6) do perfil de linguagem ativo** (`profile.<role>.file` da ficha; prefixo `plugin:` → `${CLAUDE_PLUGIN_ROOT}/guidelines/`, senão relativo à raiz do projeto) — a tradução de cada item para a stack (função de escaping, mecanismo de bind, armadilha típica). Leia **apenas** essa seção, não o perfil inteiro. Itens `⚠️ CONFIRMAR:`/`⚠️ não confirmado` de perfil gerado por IA merecem atenção redobrada.

## Fluxo

1. Ler o briefing da main session (na falta dele, TASK/PLAN), o **gabarito** acima e os arquivos modificados (`git diff` ou report).
2. Rodar o checklist do gabarito contra o diff.
3. Mudança tocando dependências/manifesto/lockfile → rodar a ferramenta de auditoria que o gabarito nomeia para o ecossistema e aplicar a política *Dependências & CVE* do `SECURITY.md`; ferramenta indisponível → achado `severidade: media` "auditoria de dependências indisponível para <ecossistema>" (**fail-visible** — não bloqueia sozinho).
4. Cada achado: categoria OWASP, **CWE lido da tabela do gabarito** (nunca de memória; sem correspondência na tabela → omitir o campo), `arquivo:linha`, severidade, correção objetiva (e `cve` quando vindo da auditoria).
5. Decisão: **qualquer** vulnerabilidade real → REPROVADO. APROVADO exige o campo `conferido` preenchido — a régua é a seção *Veredito de aprovação (gate 8)* do `SECURITY.md`; aprovação sem inventário é report inválido.

## Output: report de revisão de segurança

**Somente o YAML** (duas camadas, decisão 4.103 — régua no `sdd-conventions.md`): cada
vulnerabilidade com o acionável completo (âncora + vetor + correção), o resto econômico.

```yaml
task_id: TASK-MMM-XXX
resultado: APROVADO | REPROVADO
revisado_por: security-engineer
data_revisao: <ISO 8601>
escopo_sensivel: [auth | injecao | upload | dados_pessoais | crypto | endpoint | deps | ...]

# Obrigatório quando resultado: APROVADO — régua: SECURITY.md, "Veredito de aprovação (gate 8)" (4.264).
# Escopado ao diff da rodada; fato que acompanha o veredito, nunca o decide sozinho.
conferido:
  - categoria: "<categoria do checklist aplicável ao diff>"
    superficie: "<arquivo:linha ou contagem no diff>"

achados:
  - categoria: "Injection"          # nome canônico do superset de core/SECURITY.md
    cwe: "CWE-89"                     # da coluna CWE do gabarito; categoria sem CWE lá → omitir
    arquivo_linha: "<path:linha>"
    severidade: critica | alta | media
    descricao: <o que está vulnerável>
    correcao: <como corrigir, citando o padrão do core/SECURITY.md ou do perfil ativo>
    cve: <CVE/advisory ID vindo da saída da ferramenta de auditoria; senão omitir>

# Preencher SOMENTE quando o defeito tem causa-raiz GENERALIZÁVEL; senão null.
# A main session roteia na closure (ver /keelson:implement, etapa 3.4.2).
licao_candidata:
  alvo: projeto | processo   # processo = artefato do keelson induziu/não preveniu o erro (ex.: gatilho do gate 8 não cobria o caso) → agile-coach
  categoria: "[Segurança]"
  erro: <o que aconteceu, 1 linha>
  causa: <por que aconteceu>
  solucao: <regra acionável para evitar a repetição; citar arquivo/padrão de referência>
```

REPROVADO com `achados` não-vazio devolve a task para In Progress (1 retry, depois escala). Achado de severidade crítica/alta é sempre bloqueante.

## Limites

Não implementa nem corrige código, não faz closure, e só avalia segurança — inconsistência fora dela vira nota, não reprovação.
