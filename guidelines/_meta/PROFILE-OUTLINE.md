# PROFILE-OUTLINE

> O **índice obrigatório** de todo perfil de linguagem/stack (`backend/<lang>.md`,
> `frontend/<lang>.md`). Cada seção existe para **instanciar** um ou mais artigos do
> `QUALITY-CHARTER.md` na linguagem-alvo.
>
> Serve a três leitores:
> 1. **o gerador** (`profile-writer`): percorre estas seções ao escrever um perfil
>    novo — assim um perfil de Node cobre o mesmo que o de PHP (paridade);
> 2. **o revisor humano**: confere seção a seção que nada ficou de fora;
> 3. **o agente de implementação**: sabe onde achar a regra concreta da stack.
>
> Um perfil **DEVE** conter todas as seções marcadas `[obrigatória]`. Seção sem
> conteúdo aplicável **DEVE** dizer explicitamente "não se aplica a esta stack porque…"
> — silêncio não é permitido (esconde lacuna).
>
> Exceção única: o pseudo-perfil `none` (papel ausente — projeto sem frontend ou sem
> backend) declara a ausência e dispensa as seções 1–12: não há linguagem a instanciar.

---

## 0. Cabeçalho de proveniência `[obrigatória]`

Metadados no topo do arquivo:

```yaml
lang: <linguagem>
version: <versão-alvo>          # ex.: "8.5", "18 LTS", "17"
charter: <versão do QUALITY-CHARTER que este perfil instancia>
generated-by: <exemplar | profile-writer>
reviewed: <true | false>        # false até um humano validar
reviewer: <nome>                # preenchido na revisão
```

**Por quê:** distingue perfil curado de rascunho de IA; `reviewed:false` faz o motor
avisar antes de confiar. Instancia o Art. 1 (nada é confiável até provado/revisado).

## 1. Identidade & versão `[obrigatória]`

Responde: *qual versão exata é o alvo, e o que muda em relação a versões vizinhas?*
- features da versão que se **DEVE** preferir; features de versões futuras que **NÃO**
  existem aqui; construções de versões antigas que **NÃO DEVEM** mais ser usadas.

**Por que versão é seção de primeira classe:** o mesmo `lang` em versões diferentes é
quase outra linguagem (recursos, sintaxe, runner de teste, libs padrão). É esta seção
que o `/keelson:init` regenera quando detecta uma versão sem exemplar.

## 2. Estilo, formatação & lint `[obrigatória]`  → Charter Art. 5, 7

Responde: *qual é o guia de estilo canônico e o que o impõe automaticamente?*
- formatter/linter oficial + arquivo de config de referência;
- o que é **erro** (bloqueia) vs **aviso** (não bloqueia);
- o comando exato de lint (alimenta `keelson.config.json → quality.lint`).

## 3. Nomenclatura & idioma `[obrigatória]`  → Charter Art. 5

Responde: *como se nomeia, e em que idioma?*
- convenção por tipo de símbolo (classe, função, constante, arquivo);
- idioma do código vs idioma do comentário;
- padrões de nome que sinalizam papel (interface, teste, DTO…).

## 4. Estrutura & arquitetura `[obrigatória]`  → Charter Art. 4, 7

Responde: *onde cada tipo de código mora e quais são os limites?*
- unidade de organização (camadas, módulos, pastas) e o que pode depender de quê;
- onde ficam regra de negócio, I/O, apresentação;
- como o efeito colateral é isolado;
- como a linguagem agrupa parâmetros (objeto de parâmetro/DTO idiomático) e simplifica
  condicionais (guard clause, a construção polimórfica idiomática) — Art. 4 e 7.
- quais padrões clássicos têm construção idiomática **mais simples** nesta linguagem (e
  qual), e quais padrões são **armadilha** nesta stack — instancia a seção "Padrões de
  projeto" de `../core/ARCHITECTURE.md`.
- *Nota:* a arquitetura **específica do projeto** (nomes de camadas próprios) fica em
  `guidelines/project/`; aqui vai o padrão idiomático da linguagem.

## 5. Gestão de erro `[obrigatória]`  → Charter Art. 2, 7

Responde: *como erros nascem, sobem e são tratados?*
- exceções vs valores de retorno; o que **nunca** engolir silenciosamente;
- fronteira onde o erro vira resposta ao usuário (sem vazar interno/PII);
- o que logar e como (Art. 2: sem segredo/PII).

## 6. Segurança mapeada à linguagem `[obrigatória, CRÍTICA]`  → Charter Art. 2

A seção mais importante: pega **cada item** da Régua do Art. 2 e diz **como se
manifesta e se resolve nesta linguagem**. O charter diz "parametrize"; o perfil diz
"nesta linguagem, parametriza-se com X; a armadilha comum é Y".

Cobrir, no mínimo:
- **Injeção** (query/comando): o mecanismo parametrizado idiomático + o anti-padrão;
- **Saída/escaping** (XSS e afins): como escapar em cada contexto de saída; o que
  **nunca** renderizar cru com dado de usuário;
- **Autorização**: como se verifica permissão negando por padrão;
- **Segredos & config**: de onde vêm; como garantir que não vazam em log/erro;
- **Sessão/estado de autenticação** (se aplicável): cookies seguros, onde **não**
  guardar token, expiração.

> ⚠️ Perfil gerado por IA para linguagem que o autor não domina: cada afirmação de
> segurança **DEVE** vir marcada `⚠️ CONFIRMAR:` para dirigir a revisão humana.

## 7. Testes `[obrigatória]`  → Charter Art. 1, 9

Responde: *como se prova comportamento nesta linguagem?*
- runner canônico + comando exato (alimenta `keelson.config.json → quality.test`);
- convenção de nome e organização (ex.: arranjo-ação-asserção);
- como cobrir comportamento (não implementação); o que mockar e o que não;
- onde ficam fixtures/dados de teste compartilhados (evitar duplicação — Art. 3).

## 8. Dependências `[obrigatória]`  → Charter Art. 2, 8

Responde: *como se adiciona e audita dependência?*
- gerenciador de pacotes e arquivo de lock;
- política de versão; como auditar vulnerabilidade conhecida;
- o que evitar (dependência abandonada, licença incompatível).

## 9. Reúso: o que já existe `[obrigatória]`  → Charter Art. 3

Responde: *onde procurar antes de criar?*
- onde ficam helpers/utilitários canônicos da linguagem/projeto;
- biblioteca/design system a preferir em vez de reinventar;
- como descobrir o equivalente existente (busca, índice, guard).

## 10. Performance & armadilhas `[obrigatória]`  → Charter Art. 8

Responde: *quais custos patológicos são típicos desta linguagem e como medir?*
- o padrão de custo comum (ex.: consulta em laço, alocação em hot path);
- a ferramenta de profiling/medição idiomática.

## 11. Gotchas da versão `[obrigatória]`  → Charter Art. 1, 7

Responde: *quais pegadinhas específicas desta versão mordem quem vem de outra?*
- comportamentos surpreendentes; features a preferir/evitar **nesta** versão;
- migrações comuns de/para versões vizinhas.

## 12. Ferramentas & comandos `[obrigatória]`

O bloco que alimenta a ficha do projeto (`keelson.config.json`):

| Papel | Comando |
|-------|---------|
| test | … |
| lint | … |
| typecheck | … (ou "não se aplica") |
| build | … (ou "não se aplica") |

**Por quê:** é a ponte entre a doutrina (este perfil) e a automação (hooks e gates
leem estes comandos). Sem isto, o gate não sabe o que rodar.

---

### Contrato de paridade

Dois perfis quaisquer — o exemplar PHP 8.5 e um Node gerado pela IA — **DEVEM** ter a
mesma espinha (seções 0–12). O que muda é o **conteúdo** de cada seção, nunca a
existência dela. É esse contrato que garante que "qualidade em PHP" e "qualidade em
Node" signifiquem a mesma coisa para os 70 devs — e que a revisão humana de um perfil
novo seja uma conferência seção-a-seção, não uma leitura do zero.
