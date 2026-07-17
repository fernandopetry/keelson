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

## OWASP Top 10 — checklist rápido

| # | Vulnerabilidade | Prevenção (agnóstica) |
|---|-----------------|-----------------------|
| A01 | **Broken Access Control** | Verificar autorização em **toda** ação; **negar por padrão** |
| A02 | **Cryptographic Failures** | Hash de senha com algoritmo dedicado, com sal e custo (ex.: Argon2/bcrypt/scrypt); TLS em trânsito; nunca logar dado sensível |
| A03 | **Injection** | Consultas/comandos **parametrizados**; escapar a saída no destino; validar a entrada |
| A04 | **Insecure Design** | Validar sempre no servidor; **nunca** confiar no cliente |
| A05 | **Security Misconfiguration** | Debug desligado em produção; cabeçalhos de segurança |
| A06 | **Vulnerable Components** | Auditar dependências com a ferramenta do ecossistema; manter atualizado |
| A07 | **Auth Failures** | Rate limiting; MFA; sessões seguras |
| A08 | **Data Integrity Failures** | Verificar integridade de uploads e artefatos; CSP |
| A09 | **Logging Failures** | Logar tentativas de acesso; **nunca** logar senhas/tokens/PII |
| A10 | **SSRF** | Validar/allowlist de URLs externas; recusar IPs internos |

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
  cliente; use transporte seguro (ex.: cookie `httpOnly`/`secure`).
- **Saída** para qualquer contexto (HTML, shell, SQL, log) é **escapada no destino**, no
  formato daquele contexto. Não renderize dado de usuário cru.
- **PII** não vai para log nem para telemetria sem necessidade.

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
- [ ] Dependências auditadas
