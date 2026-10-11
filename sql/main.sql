-- EventOS · script principal de implantação
-- Executado automaticamente pelo container na primeira inicialização
-- ou manualmente: psql -U eventos -d eventos -f sql/main.sql
\set ON_ERROR_STOP on

\ir 00_init.sql

-- Descomentar à medida que as etapas forem concluídas:
\ir 01_ddl/01_entidades.sql
-- \ir 02_constraints/...
-- \ir 03_populacao/...
-- \ir 04_views/...
