# Lições ativas do projeto (recorte de `lessons.sh . match --paths tests/** src/Integracoes/**`)

## LRN-004 — Teste de cliente HTTP fica no grupo excluído da suíte padrão
**estado**: ativa · **paths**: `tests/Integracoes/**`
Todo teste em `tests/Integracoes/` que usa o servidor HTTP falso leva `@group integration`,
e o `phpunit.xml` **exclui esse grupo da suíte padrão**: `vendor/bin/phpunit` e
`vendor/bin/phpunit --filter NotaClientTest` terminam verdes **sem executar** o teste.
Um critério que prove comportamento de cliente HTTP precisa rodar o grupo explicitamente
(`--group integration`) e trazer a contagem de testes executados; caso real: a integração
fiscal ficou 3 semanas com teste "verde" que nunca rodou.

## LRN-009 — Cabeçalho de tenant no payload externo
**estado**: em-observacao · **paths**: `src/Integracoes/**`
Payload enviado a parceiro leva o `tenant_id` no cabeçalho, nunca no corpo (contexto de leitura; não é critério).
