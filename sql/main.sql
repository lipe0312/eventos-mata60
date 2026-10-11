\set ON_ERROR_STOP on

\ir 00_init.sql

\ir 01_ddl/01_entidades.sql
\ir 01_ddl/02_relacionamentos_nn.sql

\ir 02_constraints/01_checks.sql
\ir 02_constraints/02_consistencia.sql
\ir 02_constraints/03_inscricao.sql
\ir 02_constraints/04_pagamento_documento.sql
\ir 02_constraints/05_atividade.sql
\ir 02_constraints/06_publicacao.sql
\ir 02_constraints/07_certificado.sql
\ir 02_constraints/08_historico.sql
\ir 02_constraints/09_cardinalidade_minima.sql
\ir 02_constraints/10_auditoria.sql
\ir 02_constraints/11_rotinas.sql

\ir 03_populacao/01_cadastros.sql
\ir 03_populacao/02_oferta.sql
\ir 03_populacao/03_inscricoes.sql
\ir 03_populacao/04_validacao.sql
\ir 03_populacao/05_atividades.sql
\ir 03_populacao/06_publicacao.sql
\ir 03_populacao/07_pagamentos.sql
\ir 03_populacao/08_evento.sql
\ir 03_populacao/09_certificados.sql

\ir 04_views/01_derivadas.sql
\ir 04_views/02_relatorios.sql
\ir 04_views/03_acesso.sql
