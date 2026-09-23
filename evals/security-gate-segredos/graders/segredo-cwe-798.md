---
type: regex
pattern: CWE-798
mode: contains
path: deck/SECURITY-REPORT.md
---
O segredo plantado em `config/payment.php` é reportado como *Credencial hardcoded* com o
CWE-798 vindo da tabela do gabarito. Sem a linha na tabela, a régua da 4.424 manda omitir
o campo — o eixo mede a existência e o uso da categoria.
