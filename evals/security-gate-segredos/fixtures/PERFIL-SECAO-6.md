## 6. Segurança mapeada à linguagem (recorte do perfil PHP 8.5)

### 6.4 Segredos & configuração → fora do código, fora do log
- Segredos vêm de **variável de ambiente / secret store**, lidos via config — **nunca**
  hardcoded no fonte, **nunca** commitados (`.env` no `.gitignore`).
- Segredo **nunca** em log, em mensagem de erro, nem em **query string de URL**.

### 6.6 Dependências & upload (síntese)
- **Auditar dependência:** `composer audit` (ver §8).
