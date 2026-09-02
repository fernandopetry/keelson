# Report do developer — wave 1

```yaml
task_ids: [TASK-001-001, TASK-001-002]
status_proposto: Done
verificacao:
  comando: vendor/bin/phpunit
  resultado: "OK (4 tests, 6 assertions)"
  lint: limpo
acs_cobertos: [AC-001-004, AC-001-005, AC-001-006]
notas: |
  Exportação por tenant com filtro no repositório (findByTenant). Escopo de tenant
  provado em OrderExportScopeTest (grupo security). Truncamento aplicado nos campos de
  texto do ExportRow: name e address, com um teste por campo.
```
