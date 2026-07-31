<!-- ============================================================= -->
<!-- keelson — bloco gerenciado. Gerado por /keelson:init.          -->
<!-- Edite keelson.config.json, não este bloco.                    -->
<!-- ============================================================= -->

## Keelson — padrão de qualidade e fluxo (spec-driven development)

### Fonte da verdade

- **Ficha do projeto:** `keelson.config.json` na raiz — paths de código, comandos de
  qualidade, perfil de linguagem e gates ativos. **Antes de qualquer tarefa, leia a
  ficha** e use os valores dela; nunca assuma caminhos ou comandos fixos.
- **Constituição de qualidade:** o `QUALITY-CHARTER` do plugin — artigos agnósticos
  de linguagem.
- **Perfil de linguagem ativo:** conforme `profile` da ficha — o backend e (se houver)
  o frontend; o campo `file` diz onde ele mora (prefixo `plugin:` → perfil embarcado do
  keelson; caminho relativo → perfil do projeto). Instancia o Charter na linguagem/versão
  deste projeto.
- **Guidelines específicos deste projeto:** `guidelines/project/` (têm precedência
  sobre os perfis do plugin no mesmo nome; caso contrário, somam).
- **Integração com Jira (opcional):** se a ficha tem `jira.enabled: true`, o ciclo espelha
  SPEC/funcionalidades/TASKs em issues via conector MCP Atlassian — config por ID no bloco
  `jira` e no mapa `jira.mapFile`. É **best-effort** (nunca bloqueia — mas sempre conta:
  o fecho do ciclo reconcilia o slug e o relatório de entrega traz a linha de estado do
  tracker) e **sem segredos**.

### Como trabalhar

- **Modo padrão = autônomo** (`/keelson:auto` — não precisa digitar o comando): pedido
  não-trivial em linguagem natural entra no ciclo `specify → plan → tasks → implement`
  conduzido pelo **time** keelson (po, developer, code-reviewer, qa, security-engineer),
  sob o contrato Diretor–PO: o brief é emitido na largada (janela de veto — o fluxo
  segue sem esperar), o PO valida SPEC e entrega **contra o brief**, e a entrega fecha
  com o **relatório de aceitação do PO**. Você é o **Diretor**: veto, PR, merge e
  deploy são seus — a autonomia termina no push da branch. Aprovação etapa a etapa é
  opt-in (`/keelson:guided`). Rigor **proporcional a complexidade × risco** (ver Charter).
- **Mudança pontual = modo sob demanda** (decisão 4.75): ajuste localizado de código,
  sem decisão de produto, não precisa do ciclo — mas **a main session (Tech Lead) não
  escreve o código**: destila um briefing curto (o quê, onde, critério de aceite),
  delega ao `developer` e passa o diff pelo `code-reviewer` (régua avulsa);
  `security-engineer` em mudança sensível e `qa` quando há comportamento observável —
  mesmos gatilhos do ciclo. Invocar um agent **não puxa o ciclo**: cada um devolve a
  sua tarefa e para; a orquestração é sempre do Tech Lead, e commit só a pedido do
  Diretor. Só o trivial não-comportamental (typo de comentário/doc) pode ser inline,
  declarado.
- **Varredura ampla → `code-scout`**: pergunta que exige varrer a codebase (entender
  um fluxo, mapear consumidores, "de onde vem este dado?") é delegada ao `code-scout`,
  que devolve conclusão ancorada em `arquivo:linha` — os arquivos lidos não entram no
  contexto da sessão. Lookup pontual (um grep) segue inline.
- **Definição de pronto (gates):** ACs cobertos por prova · testes passando · lint
  limpo · escopo respeitado · decisões respeitadas · aderência ao Charter + perfil ·
  code review · **segurança** e **comportamento verificado** (condicionais aos gates
  da ficha) · **aceitação do PO** contra o brief (rotas com brief/espelho).
- A prova de pronto é **externa e falsificável** (um teste que cobre o comportamento),
  nunca um autochecklist — **gerador ≠ avaliador**.

### Comandos

Comandos `/keelson:*` — veja as descriptions na listagem de skills da sessão.
Humanos-only (não aparecem na listagem): `/keelson:guided` (ciclo com checkpoints) ·
`/keelson:refine` (lapidar ideia) · `/keelson:audit` (auditoria de dependências) ·
`/keelson:review` (code review de um diff avulso, sem artefato SDD) ·
`/keelson:verify-handoff` (fechar gate de tela remoto) ·
`/keelson:update` (atualizar o plugin instalado — vale após reiniciar a sessão) ·
`/keelson:postmortem` (postmortem de fim de sessão — relê as interações e produz a
mensagem ao mantenedor do plugin).

<!-- ============================================================= -->
<!-- fim do bloco keelson                                          -->
<!-- ============================================================= -->
