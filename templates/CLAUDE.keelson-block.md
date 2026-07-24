<!-- ============================================================= -->
<!-- keelson — bloco gerenciado. Gerado por /keelson:init.          -->
<!-- Edite keelson.config.json, não este bloco.                    -->
<!-- ============================================================= -->

## Keelson — padrão de qualidade e fluxo (spec-driven development)

Este projeto usa o **keelson**. O contrato de qualidade e o processo vêm do plugin;
o que é específico deste projeto vive na **ficha** e nos guidelines locais.

### Fonte da verdade

- **Ficha do projeto:** `keelson.config.json` na raiz — paths de código, comandos de
  qualidade, perfil de linguagem e gates ativos. **Antes de qualquer tarefa, leia a
  ficha** e use os valores dela; nunca assuma caminhos ou comandos fixos.
- **Constituição de qualidade:** o `QUALITY-CHARTER` do plugin — nove artigos
  agnósticos de linguagem, sempre válidos.
- **Perfil de linguagem ativo:** conforme `profile` da ficha — o backend e (se houver)
  o frontend; o campo `file` diz onde ele mora (prefixo `plugin:` → perfil embarcado do
  keelson; caminho relativo → perfil do projeto). Instancia o Charter na linguagem/versão
  deste projeto.
- **Guidelines específicos deste projeto:** `guidelines/project/` (têm precedência
  sobre os perfis do plugin no mesmo nome; caso contrário, somam).
- **Integração com Jira (opcional):** se a ficha tem `jira.enabled: true`, o ciclo espelha
  SPEC/funcionalidades/TASKs em issues via conector MCP Atlassian — config por ID no bloco
  `jira` e no mapa `jira.mapFile`. É **best-effort** (nunca bloqueia) e **sem segredos**.
  Desligada por padrão.

### Como trabalhar

- **Mudança não-trivial** → siga o ciclo `/keelson:specify → :plan → :tasks →
  :implement`. Rigor **proporcional a complexidade × risco** (ver Charter).
- **Definição de pronto (gates):** ACs cobertos por prova · testes passando · lint
  limpo · escopo respeitado · decisões respeitadas · aderência ao Charter + perfil ·
  code review · **segurança** (quando `gates.security` e a mudança é sensível) ·
  **comportamento verificado** (quando o efeito é observável; tela exige `gates.screenVerify`).
- A prova de pronto é **externa e falsificável** (um teste que cobre o comportamento),
  nunca um autochecklist — **gerador ≠ avaliador**.

### Comandos

`/keelson:init` (configurar/reparar a ficha) · `/keelson:specify` · `/keelson:plan` ·
`/keelson:tasks` · `/keelson:implement` · `/keelson:auto` (ciclo autônomo, default) ·
`/keelson:guided` (ciclo com checkpoints) · `/keelson:refine` · `/keelson:triage` ·
`/keelson:integrate` · `/keelson:jira-sync` (reconciliar com o Jira, se ativo) ·
`/keelson:migrate-legacy` (slug legado) · `/keelson:rebuild-index` ·
`/keelson:status` (consulta de estado) · `/keelson:verify-handoff` (fecha o gate de tela remoto) ·
`/keelson:audit` (auditoria manual de dependências — CVE/NVD).

<!-- ============================================================= -->
<!-- fim do bloco keelson                                          -->
<!-- ============================================================= -->
