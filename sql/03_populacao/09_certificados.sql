SET SCHEMA 'eventos';

INSERT INTO tbl_certificado (ce_pessoa, ce_edicao, ce_atividade, cd_validacao, tp_certificado, dt_emissao, status_certificado)
SELECT i.ce_pessoa,
       e.cp_id_edicao,
       NULL,
       'CERT-PART-' || CAST(i.cp_id_inscricao AS varchar(20)),
       'PARTICIPACAO',
       CAST(e.dt_fim_evento AS timestamp) + INTERVAL '2' DAY,
       'VALIDO'
  FROM tbl_inscricao i
  JOIN tbl_preco p ON p.cp_id_preco = i.ce_preco
  JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
  JOIN tbl_edicao_evento e ON e.cp_id_edicao = c.ce_edicao
 WHERE i.status_inscricao = 'CONCLUIDA'
   AND (NOT e.ind_exige_credenciamento OR i.dt_credenciamento IS NOT NULL)
   AND (
       e.pc_frequencia_minima IS NULL
       OR EXISTS (
           SELECT 1 FROM tbl_inscricao_atividade ia
            WHERE ia.ce_inscricao = i.cp_id_inscricao
              AND ia.status_inscricao_atividade = 'CONFIRMADA'
           HAVING COUNT(*) > 0
              AND COUNT(ia.dt_presenca) * 100 >= e.pc_frequencia_minima * COUNT(*)
       )
   )
 ORDER BY i.cp_id_inscricao;

INSERT INTO tbl_certificado (ce_pessoa, ce_edicao, ce_atividade, cd_validacao, tp_certificado, dt_emissao, status_certificado)
SELECT i.ce_pessoa,
       a.ce_edicao,
       a.cp_id_atividade,
       'CERT-ATIV-' || CAST(ia.cp_id_inscricao_atividade AS varchar(20)),
       'ATIVIDADE',
       a.dt_fim + INTERVAL '2' DAY,
       'VALIDO'
  FROM tbl_inscricao_atividade ia
  JOIN tbl_inscricao i ON i.cp_id_inscricao = ia.ce_inscricao
  JOIN tbl_atividade a ON a.cp_id_atividade = ia.ce_atividade
 WHERE i.status_inscricao = 'CONCLUIDA'
   AND ia.status_inscricao_atividade = 'CONFIRMADA'
   AND ia.dt_presenca IS NOT NULL
 ORDER BY ia.cp_id_inscricao_atividade;

INSERT INTO tbl_certificado (ce_pessoa, ce_edicao, ce_atividade, cd_validacao, tp_certificado, dt_emissao, status_certificado)
SELECT DISTINCT au.ce_pessoa,
       t.ce_edicao,
       CAST(NULL AS bigint),
       'CERT-AUT-' || CAST(au.ce_pessoa AS varchar(20)) || '-' || CAST(t.ce_edicao AS varchar(20)),
       'AUTORIA',
       CAST(e.dt_fim_evento AS timestamp) + INTERVAL '2' DAY,
       'VALIDO'
  FROM tbl_autoria au
  JOIN tbl_trabalho t ON t.cp_id_trabalho = au.ce_trabalho
  JOIN tbl_edicao_evento e ON e.cp_id_edicao = t.ce_edicao
 WHERE e.ano_edicao = 2025;

INSERT INTO tbl_certificado (ce_pessoa, ce_edicao, ce_atividade, cd_validacao, tp_certificado, dt_emissao, status_certificado)
SELECT DISTINCT o.ce_pessoa,
       o.ce_edicao,
       CAST(NULL AS bigint),
       'CERT-ORG-' || CAST(o.ce_pessoa AS varchar(20)) || '-' || CAST(o.ce_edicao AS varchar(20)),
       'ORGANIZACAO',
       CAST(e.dt_fim_evento AS timestamp) + INTERVAL '2' DAY,
       'VALIDO'
  FROM tbl_organizacao_edicao o
  JOIN tbl_edicao_evento e ON e.cp_id_edicao = o.ce_edicao
 WHERE e.ano_edicao = 2025;

UPDATE tbl_certificado
   SET status_certificado = 'REVOGADO'
 WHERE tp_certificado = 'PARTICIPACAO'
   AND MOD(cp_id_certificado, 100) = 0;

INSERT INTO tbl_certificado (ce_pessoa, ce_edicao, ce_atividade, cd_validacao, tp_certificado, dt_emissao, status_certificado)
SELECT ce_pessoa, ce_edicao, ce_atividade, cd_validacao || '-R', tp_certificado,
       dt_emissao + INTERVAL '30' DAY, 'VALIDO'
  FROM tbl_certificado
 WHERE status_certificado = 'REVOGADO'
 ORDER BY cp_id_certificado;
