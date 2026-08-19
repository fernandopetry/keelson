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

| Categoria | Prevenção (agnóstica) |
|-----------|-----------------------|
| **Broken Access Control** | Verificar autorização em **toda** ação; **negar por padrão** |
| **Cryptographic Failures** | Hash de senha com algoritmo dedicado, com sal e custo (ex.: Argon2/bcrypt/scrypt); TLS em trânsito; nunca logar dado sensível |
| **Injection** (inclui XSS) | Consultas/comandos **parametrizados**; escapar a saída no destino; validar a entrada |
| **Insecure Design** | Validar sempre no servidor; **nunca** confiar no cliente |
| **Security Misconfiguration** (inclui XXE) | Debug desligado em produção; cabeçalhos de segurança; parser XML sem entidades externas |
| **Software Supply Chain Failures** (amplia Vulnerable Components) | Lockfile commitado; auditar dependências contra o advisory database do ecossistema (ver seção *Dependências & CVE* abaixo); conferir a procedência do pacote (typosquatting) |
| **Authentication Failures** | Rate limiting; MFA; sessões seguras |
| **Software/Data Integrity Failures** (inclui deserialização insegura) | Verificar integridade de uploads e artefatos; CSP; nunca deserializar entrada não confiável |
| **Security Logging & Alerting Failures** | Logar tentativas de acesso; **nunca** logar senhas/tokens/PII — e saída de agente/ferramenta que tocou credencial (retorno de subagent, evento de ledger, closure, report) **é log** para esta regra: material sensível, mesma classe da saída E2E autenticada (`core/TESTING.md`) |
| **SSRF** | Validar/allowlist de URLs externas; recusar IPs internos |
| **Mishandling of Exceptional Conditions** | Erro trata **fail-closed** — exceção nunca deixa recurso em estado permissivo; detalhe interno não chega à resposta |
| **CSRF** | Token anti-CSRF em mutações autenticadas por cookie; `samesite` no cookie de sessão |

---

## Outras vulnerabilidades

| Vulnerabilidade | ❌ Errado | ✅ Correto |
|-----------------|-----------|------------|
| **Path Traversal** | Abrir caminho vindo cru da entrada | Validar/normalizar; restringir à raiz permitida |
| **Command Injection** | Interpolar entrada num comando de shell | Evitar shell; passar argumentos escapados/separados |
| **Mass Assignment** | Preencher a entidade com todo o payload | Allowlist explícita de campos |
| **IDOR** | Aceitar um id de recurso sem checar acesso | Verificar que o solicitante pode acessar **aquele** registro |
| **Race Condition** | *Check-then-act* sem exclusão | Transação/lock; operação atômica |
| **Corrida de limite/unicidade** (decisão 4.177) | Fechar com lock de **leitura** sobre a decisão (contagem/CASE lido antes de gravar — em subconsulta, o lock nem alcança a leitura) | Fechar **na escrita**: escrita condicional (o INSERT/UPDATE carrega o predicado; zero linhas afetadas **é** a recusa) ou constraint única. Prova **conta linhas** no fim, N concorrentes contra o motor real — cronometrar espera de lock já aprovou limite furado |
| **Information Disclosure** | Stack trace em produção; erro interno devolvido cru na resposta | Mensagem genérica; sanear o **mesmo** valor no sink de resposta, não só no de log |
| **Clickjacking** | Sem proteção de enquadramento | Negar enquadramento (frame-ancestors/`X-Frame-Options`) |
| **File Upload** | Aceitar qualquer arquivo | Allowlist de tipo/extensão; validar o conteúdo real |
| **Open Redirect** | Redirecionar para destino vindo da entrada | Allowlist de destinos permitidos |
| **Credencial via shell** (decisão 4.236) | Carregar arquivo de ambiente com `source`/`export` — o arquivo vira script: substituição de comando executa e a falha de parse **ecoa o segredo** na mensagem de erro (caso real: senha em texto plano no transcript) | Parser de chave=valor que não interpreta o conteúdo (dotenv/equivalente); a mensagem de erro do parser nunca é repassada |

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
