# Testes

`01_restricoes.sql` exercita cada restrição e regra de negócio com casos que devem ser rejeitados e casos que devem ser aceitos. Roda dentro de uma transação desfeita ao final (`ROLLBACK`), sem alterar os dados, e termina com o resultado de cada caso e o total de acertos.

O arquivo usa PL/pgSQL para capturar o erro esperado de cada caso, o que o SQL padrão não permite. Ele serve só para verificar as regras e não faz parte do banco entregue.

Execução manual, depois da implantação:

```bash
psql -U postgres -d eventos -f sql/99_testes/01_restricoes.sql
```
