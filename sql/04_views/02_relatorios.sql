SET SCHEMA 'eventos';

CREATE VIEW vw_inscritos_evento_categoria_instituicao AS
SELECT d.sg_evento,
       d.ano_edicao,
       d.nm_categoria,
       COALESCE(ins.sg_instituicao, 'SEM VÍNCULO') AS sg_instituicao,
       COUNT(*) AS nr_inscritos
  FROM vw_inscricao_detalhe d
  LEFT JOIN tbl_vinculo_institucional v
    ON v.ce_pessoa = d.ce_pessoa
   AND v.dt_inicio_vinculo <= CAST(d.dt_inscricao AS date)
   AND (v.dt_fim_vinculo IS NULL OR v.dt_fim_vinculo >= CAST(d.dt_inscricao AS date))
  LEFT JOIN tbl_instituicao ins ON ins.cp_id_instituicao = v.ce_instituicao
 WHERE d.status_inscricao NOT IN ('CANCELADA', 'EXPIRADA')
 GROUP BY d.sg_evento, d.ano_edicao, d.nm_categoria, COALESCE(ins.sg_instituicao, 'SEM VÍNCULO');

CREATE VIEW vw_evolucao_inscricoes AS
SELECT d.sg_evento,
       d.ano_edicao,
       CAST(d.dt_inscricao AS date) AS dt_dia,
       COUNT(*) AS nr_inscricoes_dia,
       SUM(COUNT(*)) OVER (PARTITION BY d.cp_id_edicao ORDER BY CAST(d.dt_inscricao AS date)) AS nr_inscricoes_acumulado
  FROM vw_inscricao_detalhe d
 GROUP BY d.cp_id_edicao, d.sg_evento, d.ano_edicao, CAST(d.dt_inscricao AS date);

CREATE VIEW vw_situacao_inscricoes AS
SELECT s.sg_evento,
       s.ano_edicao,
       s.situacao,
       s.nr_inscricoes,
       ROUND(100.0 * s.nr_inscricoes / SUM(s.nr_inscricoes) OVER (PARTITION BY s.cp_id_edicao), 2) AS pc_inscricoes
  FROM (
       SELECT d.cp_id_edicao,
              d.sg_evento,
              d.ano_edicao,
              CASE WHEN d.status_inscricao IN ('PAGA', 'CONCLUIDA') THEN 'PAGA'
                   WHEN d.status_inscricao IN ('CANCELADA', 'EXPIRADA') THEN 'CANCELADA'
                   ELSE 'PENDENTE' END AS situacao,
              COUNT(*) AS nr_inscricoes
         FROM vw_inscricao_detalhe d
        GROUP BY d.cp_id_edicao, d.sg_evento, d.ano_edicao,
                 CASE WHEN d.status_inscricao IN ('PAGA', 'CONCLUIDA') THEN 'PAGA'
                      WHEN d.status_inscricao IN ('CANCELADA', 'EXPIRADA') THEN 'CANCELADA'
                      ELSE 'PENDENTE' END
  ) s;

CREATE VIEW vw_receita_edicao AS
SELECT d.sg_evento,
       d.ano_edicao,
       SUM(pg.vl_pagamento) AS vl_receita_bruta,
       SUM(COALESCE(pg.vl_reembolso, 0)) AS vl_reembolsos,
       SUM(pg.vl_pagamento) - SUM(COALESCE(pg.vl_reembolso, 0)) AS vl_receita_liquida
  FROM tbl_pagamento pg
  JOIN vw_inscricao_detalhe d ON d.cp_id_inscricao = pg.ce_inscricao
 WHERE pg.status_pagamento IN ('CONFIRMADO', 'ESTORNADO')
 GROUP BY d.cp_id_edicao, d.sg_evento, d.ano_edicao;

CREATE VIEW vw_receita_categoria_forma AS
SELECT d.sg_evento,
       d.ano_edicao,
       d.nm_categoria,
       pg.tp_pagamento,
       COUNT(*) AS nr_pagamentos,
       SUM(pg.vl_pagamento - COALESCE(pg.vl_reembolso, 0)) AS vl_receita_liquida
  FROM tbl_pagamento pg
  JOIN vw_inscricao_detalhe d ON d.cp_id_inscricao = pg.ce_inscricao
 WHERE pg.status_pagamento IN ('CONFIRMADO', 'ESTORNADO')
 GROUP BY d.cp_id_edicao, d.sg_evento, d.ano_edicao, d.nm_categoria, pg.tp_pagamento;

CREATE VIEW vw_uso_beneficio AS
SELECT ins.sg_instituicao,
       b.tp_beneficio,
       d.sg_evento,
       d.ano_edicao,
       COUNT(*) AS nr_utilizacoes,
       b.nr_limite_por_edicao,
       b.nr_limite_periodo,
       SUM(it.vl_item) AS vl_concedido
  FROM vw_inscricao_detalhe d
  JOIN tbl_beneficio b ON b.cp_id_beneficio = d.ce_beneficio
  JOIN tbl_instituicao ins ON ins.cp_id_instituicao = b.ce_instituicao
  LEFT JOIN tbl_item_financeiro it
    ON it.ce_inscricao = d.cp_id_inscricao
   AND it.tp_item = 'DESCONTO'
   AND it.status_item = 'VALIDO'
 WHERE d.status_inscricao NOT IN ('CANCELADA', 'EXPIRADA')
 GROUP BY ins.sg_instituicao, b.cp_id_beneficio, b.tp_beneficio, d.cp_id_edicao, d.sg_evento, d.ano_edicao,
          b.nr_limite_por_edicao, b.nr_limite_periodo;

CREATE VIEW vw_inscritos_atividade_limitada AS
SELECT d.sg_evento,
       d.ano_edicao,
       a.nm_atividade,
       a.nr_capacidade,
       ia.ce_inscricao,
       d.ce_pessoa,
       ia.status_inscricao_atividade,
       COUNT(*) OVER (PARTITION BY a.cp_id_atividade) AS nr_ocupacao
  FROM tbl_inscricao_atividade ia
  JOIN tbl_atividade a ON a.cp_id_atividade = ia.ce_atividade
  JOIN vw_inscricao_detalhe d ON d.cp_id_inscricao = ia.ce_inscricao
 WHERE a.nr_capacidade IS NOT NULL
   AND ia.status_inscricao_atividade IN ('RESERVADA', 'CONFIRMADA');

CREATE VIEW vw_trabalho_sem_cobertura AS
SELECT ev.sg_evento,
       ed.ano_edicao,
       t.cp_id_trabalho,
       t.cd_trabalho_externo,
       t.titulo_trabalho,
       CASE WHEN t.ce_inscricao_cobertura IS NULL THEN 'SEM INSCRIÇÃO DE COBERTURA'
            ELSE 'INSCRIÇÃO DE COBERTURA NÃO PAGA' END AS ds_motivo
  FROM tbl_trabalho t
  JOIN tbl_edicao_evento ed ON ed.cp_id_edicao = t.ce_edicao
  JOIN tbl_evento ev ON ev.cp_id_evento = ed.ce_evento
  LEFT JOIN tbl_inscricao i ON i.cp_id_inscricao = t.ce_inscricao_cobertura
 WHERE t.ce_inscricao_cobertura IS NULL
    OR i.status_inscricao NOT IN ('PAGA', 'CONCLUIDA');

CREATE VIEW vw_credenciados_dia_atividade AS
SELECT d.sg_evento,
       d.ano_edicao,
       CAST(d.dt_credenciamento AS date) AS dt_dia,
       'CREDENCIAMENTO' AS ds_registro,
       COUNT(*) AS nr_participantes
  FROM vw_inscricao_detalhe d
 WHERE d.dt_credenciamento IS NOT NULL
 GROUP BY d.cp_id_edicao, d.sg_evento, d.ano_edicao, CAST(d.dt_credenciamento AS date)
UNION ALL
SELECT d.sg_evento,
       d.ano_edicao,
       CAST(ia.dt_presenca AS date),
       a.nm_atividade,
       COUNT(*)
  FROM tbl_inscricao_atividade ia
  JOIN tbl_atividade a ON a.cp_id_atividade = ia.ce_atividade
  JOIN vw_inscricao_detalhe d ON d.cp_id_inscricao = ia.ce_inscricao
 WHERE ia.dt_presenca IS NOT NULL
 GROUP BY d.cp_id_edicao, d.sg_evento, d.ano_edicao, CAST(ia.dt_presenca AS date), a.cp_id_atividade, a.nm_atividade;

CREATE VIEW vw_distribuicao_participantes AS
SELECT d.sg_evento,
       d.ano_edicao,
       COALESCE(ins.sg_instituicao, 'SEM VÍNCULO') AS sg_instituicao,
       COALESCE(p.uf_pessoa, p.pais_pessoa) AS uf_pessoa,
       d.nm_categoria,
       COUNT(DISTINCT d.ce_pessoa) AS nr_participantes
  FROM vw_inscricao_detalhe d
  JOIN tbl_pessoa p ON p.cp_id_pessoa = d.ce_pessoa
  LEFT JOIN tbl_vinculo_institucional v
    ON v.ce_pessoa = d.ce_pessoa
   AND v.dt_inicio_vinculo <= CAST(d.dt_inscricao AS date)
   AND (v.dt_fim_vinculo IS NULL OR v.dt_fim_vinculo >= CAST(d.dt_inscricao AS date))
  LEFT JOIN tbl_instituicao ins ON ins.cp_id_instituicao = v.ce_instituicao
 WHERE d.status_inscricao NOT IN ('CANCELADA', 'EXPIRADA')
 GROUP BY d.sg_evento, d.ano_edicao, COALESCE(ins.sg_instituicao, 'SEM VÍNCULO'),
          COALESCE(p.uf_pessoa, p.pais_pessoa), d.nm_categoria;

CREATE VIEW vw_documentos_pendentes AS
SELECT d.sg_evento,
       d.ano_edicao,
       d.nm_categoria,
       doc.cp_id_documento,
       doc.ce_inscricao,
       doc.tp_documento,
       doc.dt_envio
  FROM tbl_documento_comprovacao doc
  JOIN vw_inscricao_detalhe d ON d.cp_id_inscricao = doc.ce_inscricao
 WHERE doc.status_documento = 'PENDENTE'
   AND d.status_inscricao NOT IN ('CANCELADA', 'EXPIRADA');
