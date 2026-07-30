# Testes (core)

> Princípios de teste **agnósticos de linguagem**. Instanciam o **Art. 1** (correção é
> provada, não afirmada) e o **Art. 9** (pronto inclui prova) do
> `../_meta/QUALITY-CHARTER.md`. O runner, os atributos e a organização de arquivos
> **concretos** ficam no perfil de linguagem (`../backend/*.md`, `../frontend/*.md`), que
> alimenta o comando `quality.test` de `keelson.config.json`.

---

## Filosofia: prova externa de comportamento

Um teste existe para **provar comportamento**, não implementação. Antes de escrever um,
pergunte: **"qual regra este teste valida?"** Se você não sabe responder, **não escreva o
teste** — ele só vai travar a refatoração sem proteger nada.

A prova precisa ser **externa e falsificável**: um teste que **falharia** se o
comportamento regredisse (Charter — régua "gerador ≠ avaliador").

| ✅ Testar | ❌ Não testar |
|-----------|--------------|
| Regras de negócio | Conexão com infraestrutura |
| Cálculos e decisões críticas | Getters/setters triviais |
| Validações de domínio e invariantes | Se um objeto foi instanciado |
| Casos de borda | Detalhe de implementação de terceiros |

---

## Estrutura AAA

```text
Arrange (preparar) → Act (executar) → Assert (verificar)
```

Cada teste tem **um** Act claro. Quando os blocos ficam longos, separe as três seções
visualmente para que o leitor veja de imediato o que é preparação, o que é a ação sob
teste e o que é a verificação.

---

## Cobrir comportamento, não implementação

- Teste **pela interface pública** da unidade — entradas e saídas observáveis, não
  estado interno. Assim a refatoração que preserva comportamento não quebra o teste.
- **Mocke o que é I/O e colaboradores externos** (portas do domínio); **não mocke** a
  lógica que você está testando. Excesso de mock testa o mock, não o código.
- Prefira **um caso por regra** com nomes que digam a regra (sucesso e falha esperada),
  em vez de um teste gigante que verifica tudo.
- Use **tabela de casos** (parametrização) para varrer entradas equivalentes sem
  duplicar o corpo do teste.

---

## Asserções que provam (anti-tautologia)

Uma asserção só prova algo quando o valor esperado tem **origem independente** do código
sob teste — um teste tautológico ou de asserção fraca **existe, roda e passa**, mas é
incapaz de falhar junto com o comportamento. Quatro regras mecânicas (todas achado
bloqueante no gate 1 — `./CODE-REVIEW.md`):

- **Esperado independente do gerador**: asserção cujo valor esperado é **calculado
  chamando o código de produção** (a própria unidade sob teste ou o helper que ela usa
  para produzir a saída) é tautologia — passa para qualquer comportamento, certo ou
  errado. O esperado é um **literal** ou construído por caminho independente do gerador.
- **Unicidade se prova contando**: requisito "aparece exatamente uma vez" não se prova
  com asserção de "contém" (ela passa com 1 **ou N** ocorrências) — exige **contagem**
  de ocorrências comparada ao esperado.
- **Um caso por ramo de fallback**: cadeia de fallback (`A senão B senão C`) tem um
  teste por ramo. Fixture com todos os campos sempre preenchidos exercita só o primeiro
  ramo e deixa os demais **invisíveis por construção** — o fixture tem a forma **real**
  do dado (campos ausentes/vazios existem em produção), não a forma que o código espera.
- **Quantificador vira tabela**: requisito quantificado ("todos os locales", "cada
  tipo", "os N países") exige um caso por elemento — ou por classe de equivalência
  **demonstrada** — via tabela de casos. Só o caso default testado = AC não coberto.

---

## Fixtures e dados compartilhados (Art. 3)

Schema de teste e construtores de dados são **centralizados**, não declarados inline em
cada teste. Copiar um `CREATE TABLE` ou um builder de linha para dentro do teste é a
mesma violação de DRY dos helpers de produção — e diverge: quando o código passa a ler um
campo novo, as cópias inline ficam desatualizadas e quebram em massa (*schema drift*).

- Precisa de uma tabela/entidade nova no teste → adicione ao **helper central**, nunca
  inline.
- Precisa de um campo novo lido pelo código → edite o helper em **um** lugar.

---

## O dublê não é produção

Testar contra um substituto rápido do ambiente (banco em memória, serviço fake) é ótimo
para velocidade, mas o substituto **não é** o ambiente de produção — dialetos, tipos e
construções divergem. Quando a mudança altera o I/O real (a consulta, o comando, o
contrato externo), o teste no dublê **não dispensa** a verificação de comportamento
contra o ambiente real (o gate de comportamento observável, quando aplicável).

O **toolchain do runner também é dublê**: quando o runtime carrega o código por caminho
diferente do runner (outro transpilador/parser, outra versão de interpretador, outro
loader), a suíte verde **não prova que a aplicação sobe**. Mudança em código carregado
pelo runtime real → prove a carga/boot nele (o comando concreto é do perfil de linguagem
ou da ficha), não só no runner.

---

## Prioridade e exceção obrigatória

| 🥇 Alta | 🥈 Média | 🥉 Baixa |
|---------|----------|----------|
| Domínio (entidades, regras, cálculos) | Adaptadores/repositórios | Camada de entrega e UI |

**Exceção que sobe de prioridade — gate de autorização:** teste de integração provando
a **negação sem a permissão**, na pilha real (detalhe: `./SECURITY.md`, *Prova do 403*).

---

## Verificação forte e única

Escolha a verificação que **prova o comportamento** (teste de integração/E2E) e rode a
suíte relevante **uma vez** ao final. Não prove a mesma coisa em várias ferramentas (lint
+ script de fiação + E2E + suíte repetida) — escolha a mais forte e pare. Rigor
**proporcional a complexidade × risco** (ver `./WORKFLOW.md`).

---

## Verificação que falha não se contorna

Uma verificação que falha — ou que **não consegue rodar** — tem exatamente **duas
saídas**: corrigir a causa (se está no escopo) ou **parar e reportar o bloqueio** a quem
orquestra. Não existe terceira via. Em particular, **erro pré-existente** (teste vermelho,
suíte que não sobe, ambiente quebrado antes de você tocar em qualquer coisa) não é
licença para pular a verificação: "não fui eu que quebrei" explica a origem do vermelho,
não autoriza entregar sem prova.

**Baseline antes de mudar**: quem vai implementar roda a verificação escopada **uma vez
antes de tocar no código** e registra o resultado. Baseline vermelho → parar e reportar
ali, antes de investir em implementação — é nesse momento que reportar é barato. A
comparação final é sempre **contra o baseline**: nenhum vermelho novo.

**São contorno — a mesma violação de gate do furo silencioso** (decisão 4.38):

- Pular hook de verificação no commit (`--no-verify` e equivalentes).
- Estreitar o filtro do runner para **excluir** o teste que falha.
- Flag de "passa sem testes" / suíte vazia contando como verde.
- Desabilitar, deletar ou marcar como skip o teste vermelho.
- Não rodar a verificação e **silenciar** — entregar como se tivesse rodado.

**Silêncio sobre verificação lê-se como verificação aprovada — e essa é a falha que esta
regra existe para impedir.** Todo report declara o **comando literal** executado e o
resultado; "não rodei: <motivo>" é um estado válido desde que explícito — a omissão nunca
é. Os nomes concretos das flags de cada runner ficam no perfil de linguagem; a proibição
é desta doutrina e vale para todos.
