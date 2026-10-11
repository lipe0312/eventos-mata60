SET SCHEMA 'eventos';

SELECT table_name, table_type
  FROM information_schema.tables
 WHERE table_schema = 'eventos'
 ORDER BY table_type, table_name;

SELECT table_name, ordinal_position, column_name, data_type,
       character_maximum_length, numeric_precision, numeric_scale, is_nullable, is_identity
  FROM information_schema.columns
 WHERE table_schema = 'eventos'
   AND table_name LIKE 'tbl\_%'
 ORDER BY table_name, ordinal_position;

SELECT tc.table_name, tc.constraint_type, COUNT(*) AS nr_restricoes
  FROM information_schema.table_constraints tc
 WHERE tc.table_schema = 'eventos'
   AND tc.constraint_name NOT LIKE '%\_not\_null'
 GROUP BY tc.table_name, tc.constraint_type
 ORDER BY tc.table_name, tc.constraint_type;

SELECT kcu.table_name AS tabela_origem,
       kcu.column_name AS coluna_origem,
       ccu.table_name AS tabela_destino,
       ccu.column_name AS coluna_destino,
       rc.constraint_name
  FROM information_schema.referential_constraints rc
  JOIN information_schema.key_column_usage kcu
    ON kcu.constraint_schema = rc.constraint_schema AND kcu.constraint_name = rc.constraint_name
  JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_schema = rc.unique_constraint_schema AND ccu.constraint_name = rc.unique_constraint_name
 WHERE rc.constraint_schema = 'eventos'
 ORDER BY kcu.table_name, kcu.column_name;

SELECT tc.table_name, cc.constraint_name, cc.check_clause
  FROM information_schema.check_constraints cc
  JOIN information_schema.table_constraints tc
    ON tc.constraint_schema = cc.constraint_schema AND tc.constraint_name = cc.constraint_name
 WHERE cc.constraint_schema = 'eventos'
   AND cc.constraint_name LIKE 'ck\_%'
 ORDER BY tc.table_name, cc.constraint_name;

SELECT event_object_table AS tabela, trigger_name, action_timing, event_manipulation, action_statement
  FROM information_schema.triggers
 WHERE trigger_schema = 'eventos'
 ORDER BY event_object_table, trigger_name, event_manipulation;

SELECT routine_name, routine_type, external_language
  FROM information_schema.routines
 WHERE routine_schema = 'eventos'
 ORDER BY routine_type, routine_name;

SELECT table_name AS visao
  FROM information_schema.views
 WHERE table_schema = 'eventos'
 ORDER BY table_name;

SELECT grantee, table_name, privilege_type
  FROM information_schema.role_table_grants
 WHERE table_schema = 'eventos'
   AND grantee LIKE 'papel\_%'
 ORDER BY grantee, table_name, privilege_type;

SELECT 'tbl_pessoa' AS tabela, COUNT(*) AS nr_linhas FROM tbl_pessoa
UNION ALL SELECT 'tbl_evento', COUNT(*) FROM tbl_evento
UNION ALL SELECT 'tbl_edicao_evento', COUNT(*) FROM tbl_edicao_evento
UNION ALL SELECT 'tbl_categoria_inscricao', COUNT(*) FROM tbl_categoria_inscricao
UNION ALL SELECT 'tbl_faixa_inscricao', COUNT(*) FROM tbl_faixa_inscricao
UNION ALL SELECT 'tbl_preco', COUNT(*) FROM tbl_preco
UNION ALL SELECT 'tbl_atividade', COUNT(*) FROM tbl_atividade
UNION ALL SELECT 'tbl_instituicao', COUNT(*) FROM tbl_instituicao
UNION ALL SELECT 'tbl_vinculo_institucional', COUNT(*) FROM tbl_vinculo_institucional
UNION ALL SELECT 'tbl_beneficio', COUNT(*) FROM tbl_beneficio
UNION ALL SELECT 'tbl_periodo_associacao', COUNT(*) FROM tbl_periodo_associacao
UNION ALL SELECT 'tbl_inscricao', COUNT(*) FROM tbl_inscricao
UNION ALL SELECT 'tbl_inscricao_atividade', COUNT(*) FROM tbl_inscricao_atividade
UNION ALL SELECT 'tbl_item_financeiro', COUNT(*) FROM tbl_item_financeiro
UNION ALL SELECT 'tbl_pagamento', COUNT(*) FROM tbl_pagamento
UNION ALL SELECT 'tbl_documento_comprovacao', COUNT(*) FROM tbl_documento_comprovacao
UNION ALL SELECT 'tbl_trabalho', COUNT(*) FROM tbl_trabalho
UNION ALL SELECT 'tbl_termo', COUNT(*) FROM tbl_termo
UNION ALL SELECT 'tbl_certificado', COUNT(*) FROM tbl_certificado
UNION ALL SELECT 'tbl_auditoria', COUNT(*) FROM tbl_auditoria
UNION ALL SELECT 'tbl_autoria', COUNT(*) FROM tbl_autoria
UNION ALL SELECT 'tbl_resposta_termo', COUNT(*) FROM tbl_resposta_termo
UNION ALL SELECT 'tbl_organizacao_edicao', COUNT(*) FROM tbl_organizacao_edicao
UNION ALL SELECT 'tbl_restricao_atividade', COUNT(*) FROM tbl_restricao_atividade
ORDER BY nr_linhas DESC;
