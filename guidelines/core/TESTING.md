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
comportamento regredisse. Um checklist preenchido por quem escreveu o código **não** é
prova (Charter — régua "gerador ≠ avaliador").

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

---

## Prioridade e exceção obrigatória

| 🥇 Alta | 🥈 Média | 🥉 Baixa |
|---------|----------|----------|
| Domínio (entidades, regras, cálculos) | Adaptadores/repositórios | Camada de entrega e UI |

**Exceção que sobe de prioridade:** todo **gate de autorização** exige teste de
integração provando a **negação sem a permissão** (não só o sucesso com ela),
exercitando a pilha real na ordem de produção. Ver `./SECURITY.md`.

---

## Verificação forte e única

Escolha a verificação que **prova o comportamento** (teste de integração/E2E) e rode a
suíte relevante **uma vez** ao final. Não prove a mesma coisa em várias ferramentas (lint
+ script de fiação + E2E + suíte repetida) — escolha a mais forte e pare. Rigor
**proporcional a complexidade × risco** (ver `./WORKFLOW.md`).
