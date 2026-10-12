# Modelo lógico

`modelo-logico-final.pdf` é a exportação do brModelo, revisada contra a DDL: 24 tabelas e 37 chaves estrangeiras.

O brModelo só oferece alguns tipos, então o diagrama mostra `FLOAT` onde o banco usa `numeric`, `INT` onde usa `bigint` e `DATETIME` onde usa `timestamp`. Ele também força `INT` em coluna PK, por isso `tp_papel` (Organiza) aparece como `INT`, com uma nota indicando o tipo real, `varchar(20)`. A chave `ce_edicao_agregadora` aponta para a própria Edição e não tem linha desenhada. Os tipos exatos estão em `sql/01_ddl/` e no dicionário do relatório.
