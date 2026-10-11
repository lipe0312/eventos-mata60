# Metadados

Consultas ao `information_schema` para a exploração de metadados exigida na rubrica P2: tabelas, colunas, restrições, chaves estrangeiras, CHECKs, triggers, rotinas, visões, permissões e contagem de linhas.

Execução manual, depois da implantação:

```bash
docker compose exec postgres psql -U eventos -d eventos -f /sql/05_metadados/01_metadados.sql
```
