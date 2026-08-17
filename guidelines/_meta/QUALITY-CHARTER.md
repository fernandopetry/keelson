# QUALITY-CHARTER

> A constituição de qualidade — **agnóstica de linguagem**: nada aqui menciona stack;
> cada perfil de linguagem é uma **instância** destes princípios (ver rodapé *Como um
> perfil usa este charter*).
>
> Palavras-chave conforme RFC 2119: **DEVE / NÃO DEVE / DEVERIA / PODE**.
>
> **Versão: 0.6.0** — é esta versão que o campo `charter:` do cabeçalho de
> proveniência de cada perfil referencia.

---

## Régua geral: gerador ≠ avaliador

A prova de que um artigo foi cumprido é **externa e falsificável** — um teste que
cobre o comportamento, uma ferramenta que reprova, um humano revisando com contexto
limpo. Um checklist preenchido por quem escreveu o código **NÃO** é prova. Todo
artigo abaixo traz uma **Régua**: o que, concretamente, demonstra conformidade.

O rigor é **proporcional a complexidade × risco**, não fixo. Mudança trivial não
carrega o mesmo aparato de uma mudança complexa e sensível. Cortar redundância de
verificação é cortar desperdício — não qualidade.

---

## Art. 1 — Correção é provada, não afirmada

Todo comportamento novo ou alterado **DEVE** ter uma prova externa que falharia se
o comportamento regredisse. Quando a mudança tem efeito observável, ela **DEVE** ser
exercitada no ambiente real, não só em teste unitário.

- **Régua:** existe um teste que cobre o comportamento e que **falha** se o código
  for revertido. Mudança sem teste possível (ex.: refactor de legibilidade) → uma
  passada de revisão independente com contexto limpo.

## Art. 2 — Seguro por padrão; negar por padrão

Toda entrada vinda de fora do processo é **não confiável**. Acesso, permissão e
capacidade **DEVEM** ser negados por padrão e liberados explicitamente. Segredos
**NÃO DEVEM** aparecer em código-fonte, em log ou em URL.

- **Régua (o perfil mapeia cada item à linguagem):**
  - toda consulta a dados externos é **parametrizada** (nunca concatenação de entrada);
  - toda saída para outro contexto (HTML, shell, SQL, log) é **escapada** no destino;
  - toda ação verifica **autorização** antes de executar, negando por padrão;
  - segredos vêm de configuração/secret store, **nunca** hardcoded nem logados;
  - dado pessoal (PII) não vai para log nem para telemetria sem necessidade.

## Art. 3 — Não te repita; reúse antes de criar

Antes de escrever helper, validação, conversão, componente ou abstração, você
**DEVE** procurar o equivalente existente e reusá-lo. Um conceito **DEVE** ter uma
única fonte de verdade.

- **Régua:** a mudança não introduz um segundo caminho para algo que já existia;
  quando o conceito se repete, ele foi **extraído**, não copiado. Idealmente um guard
  determinístico reprova a reimplementação de um canônico.

## Art. 4 — Limites claros e responsabilidade única

Cada unidade (função, módulo, camada) **DEVE** ter uma responsabilidade e depender de
**abstrações**, não de detalhes. Efeito colateral (I/O, rede, banco, estado global)
**DEVE** ser explícito e isolável. Uma assinatura com muitos parâmetros é sintoma de
responsabilidade em excesso ou de conceito não agrupado — informações que viajam juntas
**DEVERIAM** ser agrupadas num objeto com nome de domínio (o perfil dá a forma idiomática).
Abstração e indireção (interface, fábrica, camada, padrão de projeto) se justificam por uma
dor **presente** — variação real, isolamento de efeito colateral, testabilidade — nunca por
antecipação. Padrão é vocabulário para uma solução, não um objetivo.

- **Régua:** a unidade pode ser testada sem levantar o mundo inteiro; trocar um detalhe
  (driver, framework, view) não obriga a reescrever a regra de negócio; a assinatura não
  carrega uma lista longa de parâmetros soltos onde um conceito nomeado os agruparia; toda
  indireção nova responde a uma necessidade demonstrável no diff ou numa DEC — não há
  interface/hierarquia sem um motivo real (variante existente, porta de I/O ou teste).

## Art. 5 — Nomear pela intenção

Nomes **DEVEM** revelar propósito, não implementação. O nome **DEVE** cobrir também os
**efeitos colaterais** da unidade: um `login()` que também envia e-mail ou limpa cache
surpreende quem chama — é violação mesmo com o efeito isolado atrás de abstração (Art. 4).
O idioma de código e o idioma de comentário **DEVEM** ser consistentes em toda a base.
Código novo **DEVE** ler como o código vizinho em **convenção e idioma**. Densidade de
comentário **NÃO** se herda do vizinho: segue o Art. 7 — base antiga verbosa não é
licença para verbosidade nova. A verbosidade que já está lá segue a **regra do
escoteiro** (Art. 6): no trecho que a mudança toca, limpe; no resto da base, deixe.

- **Régua:** um revisor entende o que a unidade faz pelo nome, sem ler o corpo; nenhum
  efeito colateral relevante fica fora do que o nome anuncia; não há mistura de
  convenções/idiomas dentro do mesmo arquivo.

## Art. 6 — Escopo restrito; reversibilidade calibra o rigor

Uma mudança **DEVE** alterar o mínimo necessário para o seu objetivo. Quanto mais
**difícil de reverter** o efeito (dado destruído, config de produção, contrato
público), mais alto o rigor e mais necessária a **confirmação humana** antes de aplicar.

**Regra do escoteiro** — o trecho que a mudança **já toca** DEVE ficar melhor do que
foi encontrado: comentário que reprova no teste do Art. 7, comentário que **mente**
sobre o código atual, código morto, nome local enganoso e barato de corrigir. Três
condições tornam a limpeza legítima — e a distinguem de desvio de escopo: **distância
de leitura** (a unidade editada e sua vizinhança no mesmo arquivo), **comportamento
preservado**, **declarada item a item** no report. Faltou qualquer uma → não é
escoteiro, é escopo novo: registre como pendência e siga.

- **Por quê:** quem já está no trecho é o leitor mais barato que ele jamais terá —
  limpeza adiada para "outra task" é adiada para nunca.
- **Régua:** o diff se explica por um objetivo mais a limpeza declarada do trecho
  tocado; ações destrutivas ou de difícil reversão passaram por decisão humana
  registrada antes de executar.

## Art. 7 — Legível para o próximo humano

Clareza **DEVE** vencer esperteza. Complexidade acidental **DEVE** ser removida antes
de comentada: aninhamento profundo pede **guard clause** e **extração de método
nomeado**; despacho repetido pela mesma variante/tipo pede **polimorfismo** (o perfil
dá a construção idiomática).

Comentário obedece a **um único teste: apagá-lo perde informação que o código não
devolve?**

- **Perde → DEVE existir.** É o contexto irrecuperável pela leitura: o porquê de uma
  decisão (uma linha, com âncora — `DEC-03`, `FR-07`), a armadilha ou workaround
  (porquê + condição de remoção), o invariante que tipo e nome não expressam, o caminho
  já tentado que falhou.
- **Não perde → NÃO DEVE existir.** Paráfrase, assinatura repetida, template ritual.

Exceção idiomática mora no perfil: onde a sintaxe não carrega tipo/contrato (ex.:
docblock como única declaração de tipo), o comentário que o carrega é obrigatório.

- **Por quê:** o próximo leitor — humano ou agente sem a conversa que gerou o código —
  reconstrói o *como* lendo; a decisão e a armadilha, não. E comentário é afirmação que
  ninguém compila: quando envelhece, vira mentira com cara de garantia.
- **Régua:** intenção entendida em uma leitura; todo comentário passa no teste de
  apagar; nenhum bloco de comentário maior que o trecho que explica.

## Art. 8 — Eficiência consciente, medida — não presumida

O custo (tempo, memória, chamadas de I/O) **DEVE** ser proporcional ao trabalho.
Padrões de custo patológico conhecidos (consultas em laço, trabalho O(n²) evitável,
recomputo) **NÃO DEVEM** ser introduzidos. Otimização além disso **DEVE** ser guiada
por medição, não por palpite.

- **Por quê:** o gargalo real quase nunca é onde a intuição aponta; otimizar no escuro
  troca legibilidade por nada.
- **Régua:** não há consulta/round-trip dentro de laço sobre dados de tamanho variável;
  qualquer otimização não óbvia cita a medição que a justifica.

## Art. 9 — "Pronto" inclui prova e registro

Uma tarefa só está **pronta** quando: os critérios de aceite estão cobertos por prova
(Art. 1), as verificações automáticas passam, o escopo foi respeitado, a segurança foi
avaliada quando aplicável (Art. 2), o comportamento foi verificado quando observável, e
a mudança está **documentada** onde o próximo vai procurar.

- **Régua:** existe a definição de pronto (os gates) e ela foi satisfeita de forma
  verificável; a documentação canônica reflete a mudança.

## Art. 10 — A interface tem o mesmo padrão do código que a serve

O que o usuário vê e opera **DEVE** refletir o rigor aplicado ao restante do sistema.
Padrões de interface descuidada conhecidos (estado não tratado, componente que
reinventa padrão existente do produto, ação sem resposta perceptível, piso de
acessibilidade furado) **NÃO DEVEM** ser introduzidos. Refinamento além disso **DEVE**
ser ancorado na consistência com o produto, não no gosto de quem revisa.

- **Por quê:** o usuário julga o sistema inteiro pela superfície que toca; backend
  impecável atrás de uma tela descuidada é percebido como sistema descuidado.
- **Régua:** toda vista de dados nova trata vazio/carregando/erro; nenhum componente
  reinventa padrão que o produto já tem; toda ação do usuário tem resposta perceptível.

---

### Como um perfil usa este charter

O perfil de uma linguagem **não reescreve** estes artigos — ele os **instancia**.
Para cada artigo, o perfil responde: *"na minha linguagem/versão, isto se cumpre
assim, com esta ferramenta, com esta armadilha a evitar"*. O `PROFILE-OUTLINE.md`
define as seções onde essas respostas moram, garantindo que todo perfil cubra os
mesmos artigos — é o que dá **paridade de qualidade** entre PHP, Node, React e o que
vier.
