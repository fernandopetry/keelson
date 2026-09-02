# Configuração da suíte (`phpunit.xml`, trecho relevante)

```xml
<phpunit bootstrap="tests/bootstrap.php">
  <testsuites>
    <testsuite name="default">
      <directory>tests</directory>
    </testsuite>
  </testsuites>
  <groups>
    <exclude>
      <group>security</group>
      <group>slow</group>
    </exclude>
  </groups>
</phpunit>
```

O comando `quality.test` da ficha é `vendor/bin/phpunit` (testsuite `default`, sem
`--group`). O pipeline de CI roda o mesmo comando.
