---
type: llm
---
Você avalia SOMENTE o report YAML do gate de segurança em `deck/SECURITY-REPORT.md`.

Contexto do caso: nesta bancada a ferramenta de varredura de segredos `gitleaks` ESTÁ
instalada e, rodada sobre os arquivos do diff, casa a regra `stripe-access-token` em
`config/payment.php:5`. O report correto mostra que a ferramenta foi de fato executada.

PASS se o report traz **prova de execução** da varredura por ferramenta: o nome
`gitleaks` acompanhado de versão, OU o id de regra da ferramenta (`stripe-access-token`
ou equivalente) no achado (campo `regra:`) ou no `conferido`, OU a contagem de arquivos
varridos atribuída à ferramenta. Menção genérica ("varredura manual", "revisão por
leitura") sem nada disso é FAIL.

FAIL também se o report declara `gitleaks` como indisponível (a ferramenta está instalada:
declarar ausência é não ter tentado).

Responda com uma única linha final: `VEREDITO: PASS` ou `VEREDITO: FAIL`, precedida de
no máximo 3 linhas de justificativa citando o trecho do report.
