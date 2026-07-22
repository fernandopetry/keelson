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

As categorias mudam de nome e posição entre edições (2003→2025), mas os ataques não
morrem com elas — esta tabela cobre a **união** das edições, com o mapeamento de cada
categoria. Texto integral de cada edição: <https://github.com/OWASP/Top10>.

| Categoria | Edições | Prevenção (agnóstica) |
|-----------|---------|-----------------------|
| **Broken Access Control** | A01:2021 · A01:2025 | Verificar autorização em **toda** ação; **negar por padrão** |
| **Cryptographic Failures** | A02:2021 · A04:2025 | Hash de senha com algoritmo dedicado, com sal e custo (ex.: Argon2/bcrypt/scrypt); TLS em trânsito; nunca logar dado sensível |
| **Injection** (inclui XSS) | A03:2021 · A05:2025 | Consultas/comandos **parametrizados**; escapar a saída no destino; validar a entrada |
| **Insecure Design** | A04:2021 · A06:2025 | Validar sempre no servidor; **nunca** confiar no cliente |
| **Security Misconfiguration** (inclui XXE) | A05:2021 · A02:2025 | Debug desligado em produção; cabeçalhos de segurança; parser XML sem entidades externas |
| **Software Supply Chain Failures** (amplia Vulnerable Components) | A06:2021 · A03:2025 | Lockfile commitado; auditar dependências contra o advisory database do ecossistema (ver seção *Dependências & CVE* abaixo); conferir a procedência do pacote (typosquatting) |
| **Authentication Failures** | A07:2021 · A07:2025 | Rate limiting; MFA; sessões seguras |
| **Software/Data Integrity Failures** (inclui deserialização insegura) | A08:2021 · A08:2025 | Verificar integridade de uploads e artefatos; CSP; nunca deserializar entrada não confiável |
| **Security Logging & Alerting Failures** | A09:2021 · A09:2025 | Logar tentativas de acesso; **nunca** logar senhas/tokens/PII |
| **SSRF** | A10:2021 · absorvido em A01:2025 | Validar/allowlist de URLs externas; recusar IPs internos |
| **Mishandling of Exceptional Conditions** | A10:2025 | Erro trata **fail-closed** — exceção nunca deixa recurso em estado permissivo; detalhe interno não chega à resposta |
| **CSRF** | categoria própria até 2013 | Token anti-CSRF em mutações autenticadas por cookie; `samesite` no cookie de sessão |

---

## Outras vulnerabilidades

| Vulnerabilidade | ❌ Errado | ✅ Correto |
|-----------------|-----------|------------|
| **Path Traversal** | Abrir caminho vindo cru da entrada | Validar/normalizar; restringir à raiz permitida |
| **Command Injection** | Interpolar entrada num comando de shell | Evitar shell; passar argumentos escapados/separados |
| **Mass Assignment** | Preencher a entidade com todo o payload | Allowlist explícita de campos |
| **IDOR** | Aceitar um id de recurso sem checar acesso | Verificar que o solicitante pode acessar **aquele** registro |
| **Race Condition** | *Check-then-act* sem exclusão | Transação/lock; operação atômica |
| **Information Disclosure** | Stack trace em produção; erro interno devolvido cru na resposta | Mensagem genérica; sanear o **mesmo** valor no sink de resposta, não só no de log |
| **Clickjacking** | Sem proteção de enquadramento | Negar enquadramento (frame-ancestors/`X-Frame-Options`) |
| **File Upload** | Aceitar qualquer arquivo | Allowlist de tipo/extensão; validar o conteúdo real |
| **Open Redirect** | Redirecionar para destino vindo da entrada | Allowlist de destinos permitidos |

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
- **Serializadores de dado sensível:** default **fail-closed** — omitir o dado sensível
  por padrão, ou exigir um parâmetro explícito para incluí-lo. Nunca "inclui tudo a menos
  que peçam para não".
- **Acesso por registro:** ao restringir o acesso a um registro, enumere as superfícies
  pelo **dado exposto** (procure toda consulta/junção/projeção da entidade), incluindo
  subsistemas com permissão própria (e-mail, export, relatórios) — não só a permissão de
  leitura principal.

---

## Segredos, saída e sessão (Art. 2)

- **Segredos** vêm de configuração/secret store — **nunca** hardcoded, **nunca** em log,
  **nunca** em URL. Token de autenticação não mora em armazenamento acessível a script do
  cliente; use transporte seguro (ex.: cookie `httpOnly`/`secure`/`samesite`).
- **Saída** para qualquer contexto (HTML, shell, SQL, log) é **escapada no destino**, no
  formato daquele contexto. Não renderize dado de usuário cru.
- **PII** não vai para log nem para telemetria sem necessidade.

---

## Dependências & CVE (NVD)

Vulnerabilidade **conhecida** tem registro público: o **CVE** (Common Vulnerabilities and
Exposures), catalogado no **NVD** (<https://nvd.nist.gov/>). A checagem é sempre por
**ferramenta** — o auditor do ecossistema consulta um advisory database sincronizado com
o CVE/NVD:

- **Rodar a ferramenta de auditoria do ecossistema** sobre o lockfile — a nomeada no
  perfil ativo (ex.: `composer audit`, `npm audit`, `pip-audit`, `govulncheck`,
  `cargo audit`, `bundler-audit`; `osv-scanner` como genérico).
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
- [ ] Senhas com algoritmo de hash dedicado; sem MD5/SHA1 puros
- [ ] Segredos e tokens fora do código, do log e da URL; sessão em transporte seguro
- [ ] Sem dado sensível/PII em logs
- [ ] Redirecionamentos e uploads restritos por allowlist
- [ ] Mutação autenticada por cookie exige token anti-CSRF
- [ ] Erro/exceção trata fail-closed; sem stack trace/detalhe interno na resposta
- [ ] Dependências auditadas contra o advisory database (CVE), com lockfile commitado
