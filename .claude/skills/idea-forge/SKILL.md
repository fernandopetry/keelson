---
name: idea-forge
description: "Ferramenta do MANTENEDOR (fora do pacote — decisão 4.182): refina uma ideia de melhoria do keelson ANTES de virar leva de desenvolvimento — parte da ideia crua do Diretor, esclarece por perguntas dirigidas, conecta com o que já existe (decisões, inbox, learning-log, doutrina) e entrega um mini-brief julgado, pronto para virar leva ou ser descartado com motivo. Report-only: não edita doutrina nem código. Ativar quando o Diretor trouxer uma ideia, hipótese ou vontade de melhoria do keelson ainda sem forma — 'e se o keelson…', 'queria que…', 'faz sentido…?'."
---

# Skill: idea-forge

Você recebeu uma ideia crua do Diretor para melhorar o keelson. Esta skill forja a ideia em decisão informada — o análogo de mantenedor do `/keelson:brief` do consumidor. Ela **não implementa nada**: o produto é um mini-brief julgado; a leva de aplicação é sessão própria, com o fluxo normal do repo (4.181, 4.63, bump se couber).

A ordem importa: **conectar antes de perguntar** (o repo responde metade das perguntas) e **perguntar antes de julgar** (parecer sobre ideia mal-entendida é retrabalho).

## Sequência

1. **Capture e devolva.** Reformule a ideia em 1–3 frases — problema percebido e resultado desejado, separados — e confirme com o Diretor antes de gastar pesquisa. Se a ideia chegou como solução ("criar um comando X"), extraia também o problema por trás dela; a solução proposta é hipótese, não requisito.

2. **Conecte com o que existe.** Antes de qualquer pergunta ao Diretor, varra o repo pelas quatro fontes de colisão, com âncora (arquivo/§) para cada achado:
   - `docs/_meta/decisions.md` — já foi decidido, recusado ou adiado-com-gatilho? Recusa anterior não mata a ideia: mudou o contexto que motivou a recusa?
   - `docs/_meta/proposal-inbox.md` e `docs/_meta/learning-log.md` — já chegou parecido de campo? Reincidência fortalece a ideia (escada 4.149).
   - Doutrina e tooling (`guidelines/`, `commands/`, `agents/`, `skills/`, `docs/_meta/conventions/`, `.claude/`) — já existe mecanismo que cobre parte disso? Quem é o dono único da regra vizinha?
   - Memória de levas da sessão (quando disponível) — a área tem pendência "observar X" aberta que a ideia toca?

   Busca que toca mais de um artefato ou raio não-óbvio → delegue ao `impact-scout`; lookup de um grep fica inline.

3. **Esclareça por perguntas dirigidas.** Pergunte só o que a pesquisa não respondeu, uma rodada por vez (2–4 perguntas, cada uma com opções e default recomendado). O alvo é fechar quatro lacunas:
   - **Dor observável** — que episódio concreto motivou a ideia? (relato > opinião; episódio vira exemplo na decisão)
   - **Gatilho** — quando o mecanismo dispararia, e quem o aciona (Diretor, comando, hook, consumidor)?
   - **Teste falsificável** — como saberemos que funcionou? O que o mecanismo deve *recusar*? Ideia sem teste ainda é vontade.
   - **Fronteira** — o que fica explicitamente fora?

4. **Julgue.** Emita parecer com um veredito do catálogo, sempre com o porquê ancorado nos achados do passo 2:
   - `avançar` — nova de verdade, dor real, sem colisão;
   - `absorver` — mecanismo existente cobre com ajuste menor (nomeie o dono a ajustar);
   - `já-coberta` — existe e resolve; aponte onde (a ideia pode revelar problema de *descoberta*, não de falta);
   - `adiar-com-gatilho` — real mas sem reincidência/custo que justifique agora (nomeie o gatilho que a reativa, padrão 4.182);
   - `recusar` — colide com decisão vigente ou o teste da régua 4.160 (no-op/sedimento) reprova; cite a decisão.

   Aplique à ideia os mesmos testes que a doutrina aplicaria depois: régua 4.160 (a frase/mecanismo muda comportamento vs. o default?), dono único (não nasce segunda cópia de regra), e escada 4.149 (1ª ocorrência observa, reincidência mecaniza).

5. **Entregue o mini-brief.** Para veredito `avançar` ou `absorver`, feche com o artefato que a leva de desenvolvimento consome:
   - **Problema** (com o episódio-motivação) · **Proposta** (1 parágrafo) · **Teste falsificável** · **Fora de escopo**
   - **Conexões** — decisões/artefatos relacionados, com âncora
   - **Classificação** — doutrina embarcada (bump + CHANGELOG; re-init?) ou tooling de mantenedor (sem bump, §4.x)
   - **Donos tocados** — arquivos prováveis e guardas mecânicas a rodar
   - **Riscos com mitigação sugerida** (4.188) — "sem mitigação conhecida" é resposta válida e sobe ao Diretor

   Demais vereditos: parecer de 3–6 linhas com âncoras basta. Ideia vinda de material de consumidor não passa por aqui — rota é `/field-intake` (registro na inbox antes de parecer).

## Entrega

Reporte: ideia reformulada · achados de conexão com âncoras · respostas do Diretor que mudaram o rumo · veredito com porquê · mini-brief (quando houver) · pergunta que ficou sem resposta, se alguma travou o julgamento.
