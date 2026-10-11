# Testes

`01_restricoes.sql` exercita cada restrição e regra de negócio com casos que devem ser rejeitados e casos que devem ser aceitos. Roda dentro de uma transação desfeita ao final (`ROLLBACK`), sem alterar os dados, e termina com o resultado de cada caso e o total de acertos.

Execução manual, depois da implantação:

```bash
docker compose exec postgres psql -U eventos -d eventos -f /sql/99_testes/01_restricoes.sql
```
