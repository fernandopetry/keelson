# QUALITY-CHARTER

> A constituição de qualidade — **agnóstica de linguagem**.
> Nada aqui menciona PHP, Vue, Node ou qualquer stack. Cada perfil de linguagem
> (`backend/*.md`, `frontend/*.md`) é uma **instância** destes princípios: pega cada
> artigo abaixo e responde "como isto se cumpre na minha linguagem/versão".
>
> Palavras-chave conforme RFC 2119: **DEVE / NÃO DEVE / DEVERIA / PODE**.
>
> **Versão: 0.1.0** — é esta versão que o campo `charter:` do cabeçalho de
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

- **Por quê:** quem escreve o código é o pior juiz de que ele funciona; a confiança
  vem de um oráculo independente, não da intenção do autor.
- **Régua:** existe um teste que cobre o comportamento e que **falha** se o código
  for rerevertido. Mudança sem teste possível (ex.: refactor de legibilidade) → uma
  passada de revisão independente com contexto limpo.

## Art. 2 — Seguro por padrão; negar por padrão

Toda entrada vinda de fora do processo é **não confiável**. Acesso, permissão e
capacidade **DEVEM** ser negados por padrão e liberados explicitamente. Segredos
**NÃO DEVEM** aparecer em código-fonte, em log ou em URL.

- **Por quê:** a falha de segurança padrão-inseguro é silenciosa até virar incidente;
  o custo de negar-por-padrão é baixo e o de vazar é irreversível.
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

- **Por quê:** duplicação é dívida que diverge — o bug corrigido num lugar sobrevive
  nos outros; a regra mudada num lugar mente nos demais.
- **Régua:** a mudança não introduz um segundo caminho para algo que já existia;
  quando o conceito se repete, ele foi **extraído**, não copiado. Idealmente um guard
  determinístico reprova a reimplementação de um canônico.

## Art. 4 — Limites claros e responsabilidade única

Cada unidade (função, módulo, camada) **DEVE** ter uma responsabilidade e depender de
**abstrações**, não de detalhes. Efeito colateral (I/O, rede, banco, estado global)
**DEVE** ser explícito e isolável.

- **Por quê:** limites nítidos tornam a mudança local, o teste possível e o raciocínio
  barato; acoplamento difuso faz o oposto.
- **Régua:** a unidade pode ser testada sem levantar o mundo inteiro; trocar um detalhe
  (driver, framework, view) não obriga a reescrever a regra de negócio.

## Art. 5 — Nomear pela intenção

Nomes **DEVEM** revelar propósito, não implementação. O idioma de código e o idioma de
comentário **DEVEM** ser consistentes em toda a base. Código novo **DEVE** ler como o
código vizinho — mesma convenção, mesma densidade de comentário, mesmo idioma.

- **Por quê:** o código é lido muito mais vezes do que escrito; o nome é a documentação
  que nunca desatualiza se disser a intenção.
- **Régua:** um revisor entende o que a unidade faz pelo nome, sem ler o corpo; não há
  mistura de convenções/idiomas dentro do mesmo arquivo.

## Art. 6 — Escopo restrito; reversibilidade calibra o rigor

Uma mudança **DEVE** alterar o mínimo necessário para o seu objetivo. Quanto mais
**difícil de reverter** o efeito (dado destruído, config de produção, contrato
público), mais alto o rigor e mais necessária a **confirmação humana** antes de aplicar.

- **Por quê:** diffs pequenos são revisáveis e reversíveis; misturar objetivos esconde
  o que importa e multiplica o risco.
- **Régua:** o diff se explica por um objetivo; ações destrutivas ou de difícil reversão
  passaram por decisão humana registrada antes de executar.

## Art. 7 — Legível para o próximo humano

Clareza **DEVE** vencer esperteza. Comentário **DEVE** explicar o *porquê* (a decisão,
a armadilha), não parafrasear o *como*. Complexidade acidental **DEVE** ser removida
antes de comentada.

- **Por quê:** o próximo a manter isto — talvez você em seis meses, talvez um dos 70 —
  paga o custo da esperteza sem o contexto que a gerou.
- **Régua:** um dev do time, sem contexto prévio, entende a intenção do trecho em uma
  leitura; os comentários respondem "por que", não "o que".

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

- **Por quê:** código sem prova, sem revisão e sem registro é trabalho não terminado
  que parece terminado — a pior categoria.
- **Régua:** existe a definição de pronto (os gates) e ela foi satisfeita de forma
  verificável; a documentação canônica reflete a mudança.

---

### Como um perfil usa este charter

O perfil de uma linguagem **não reescreve** estes artigos — ele os **instancia**.
Para cada artigo, o perfil responde: *"na minha linguagem/versão, isto se cumpre
assim, com esta ferramenta, com esta armadilha a evitar"*. O `PROFILE-OUTLINE.md`
define as seções onde essas respostas moram, garantindo que todo perfil cubra os
mesmos artigos — é o que dá **paridade de qualidade** entre PHP, Node, React e o que
vier.
