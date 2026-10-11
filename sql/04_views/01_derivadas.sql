SET SCHEMA 'eventos';

CREATE VIEW vw_inscricao_detalhe AS
SELECT i.cp_id_inscricao,
       i.ce_pessoa,
       ev.cp_id_evento,
       ev.sg_evento,
       ed.cp_id_edicao,
       ed.ano_edicao,
       c.cp_id_categoria,
       c.nm_categoria,
       f.cp_id_faixa,
       f.nm_faixa,
       p.tp_associacao,
       i.ce_beneficio,
       i.status_inscricao,
       i.dt_inscricao,
       i.dt_validade_preco,
       i.dt_confirmacao,
       i.dt_cancelamento,
       i.dt_credenciamento
  FROM tbl_inscricao i
  JOIN tbl_preco p ON p.cp_id_preco = i.ce_preco
  JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
  JOIN tbl_faixa_inscricao f ON f.cp_id_faixa = p.ce_faixa
  JOIN tbl_edicao_evento ed ON ed.cp_id_edicao = c.ce_edicao
  JOIN tbl_evento ev ON ev.cp_id_evento = ed.ce_evento;

CREATE VIEW vw_valor_inscricao AS
SELECT i.cp_id_inscricao,
       COALESCE(SUM(CASE WHEN it.tp_item <> 'DESCONTO' THEN it.vl_item END), 0) AS vl_bruto,
       COALESCE(SUM(CASE WHEN it.tp_item = 'DESCONTO' THEN it.vl_item END), 0) AS vl_desconto,
       COALESCE(SUM(CASE WHEN it.tp_item = 'DESCONTO' THEN -it.vl_item ELSE it.vl_item END), 0) AS vl_devido
  FROM tbl_inscricao i
  LEFT JOIN tbl_item_financeiro it
    ON it.ce_inscricao = i.cp_id_inscricao
   AND it.status_item = 'VALIDO'
 GROUP BY i.cp_id_inscricao;

CREATE VIEW vw_saldo_inscricao AS
SELECT v.cp_id_inscricao,
       v.vl_devido,
       COALESCE(pg.vl_pago, 0) AS vl_pago,
       COALESCE(pg.vl_reembolsado, 0) AS vl_reembolsado,
       v.vl_devido - COALESCE(pg.vl_pago, 0) AS vl_saldo
  FROM vw_valor_inscricao v
  LEFT JOIN (
       SELECT ce_inscricao,
              SUM(CASE WHEN status_pagamento = 'CONFIRMADO' THEN vl_pagamento ELSE 0 END) AS vl_pago,
              SUM(COALESCE(vl_reembolso, 0)) AS vl_reembolsado
         FROM tbl_pagamento
        GROUP BY ce_inscricao
  ) pg ON pg.ce_inscricao = v.cp_id_inscricao;

CREATE VIEW vw_situacao_associacao AS
SELECT p.cp_id_pessoa,
       CASE
           WHEN EXISTS (SELECT 1 FROM tbl_periodo_associacao pa
                         WHERE pa.ce_pessoa = p.cp_id_pessoa
                           AND CURRENT_DATE BETWEEN pa.dt_inicio_associacao AND pa.dt_fim_associacao) THEN 'VIGENTE'
           WHEN EXISTS (SELECT 1 FROM tbl_periodo_associacao pa WHERE pa.ce_pessoa = p.cp_id_pessoa) THEN 'VENCIDA'
           ELSE 'SEM_ASSOCIACAO'
       END AS situacao_associacao,
       (SELECT MAX(pa.dt_fim_associacao) FROM tbl_periodo_associacao pa
         WHERE pa.ce_pessoa = p.cp_id_pessoa) AS dt_fim_ultima_associacao
  FROM tbl_pessoa p;

CREATE VIEW vw_acesso_inscricao AS
SELECT d.cp_id_inscricao, d.cp_id_edicao, 'PRINCIPAL' AS tp_acesso
  FROM vw_inscricao_detalhe d
 WHERE d.status_inscricao IN ('PAGA', 'CONCLUIDA')
UNION ALL
SELECT d.cp_id_inscricao, ag.cp_id_edicao, 'AGREGADA'
  FROM vw_inscricao_detalhe d
  JOIN tbl_edicao_evento ag ON ag.ce_edicao_agregadora = d.cp_id_edicao
 WHERE d.status_inscricao IN ('PAGA', 'CONCLUIDA');

CREATE VIEW vw_aptidao_certificado AS
SELECT d.cp_id_inscricao,
       d.ce_pessoa,
       d.cp_id_edicao,
       d.sg_evento,
       d.ano_edicao,
       d.dt_credenciamento IS NOT NULL AS ind_credenciado,
       COALESCE(fr.nr_confirmadas, 0) AS nr_atividades_confirmadas,
       COALESCE(fr.nr_presencas, 0) AS nr_presencas,
       CASE WHEN COALESCE(fr.nr_confirmadas, 0) > 0
            THEN ROUND(100.0 * fr.nr_presencas / fr.nr_confirmadas, 2) END AS pc_frequencia,
       (NOT ed.ind_exige_credenciamento OR d.dt_credenciamento IS NOT NULL)
       AND (ed.pc_frequencia_minima IS NULL
            OR (COALESCE(fr.nr_confirmadas, 0) > 0
                AND fr.nr_presencas * 100 >= ed.pc_frequencia_minima * fr.nr_confirmadas)) AS ind_apto
  FROM vw_inscricao_detalhe d
  JOIN tbl_edicao_evento ed ON ed.cp_id_edicao = d.cp_id_edicao
  LEFT JOIN (
       SELECT ce_inscricao, COUNT(*) AS nr_confirmadas, COUNT(dt_presenca) AS nr_presencas
         FROM tbl_inscricao_atividade
        WHERE status_inscricao_atividade = 'CONFIRMADA'
        GROUP BY ce_inscricao
  ) fr ON fr.ce_inscricao = d.cp_id_inscricao
 WHERE d.status_inscricao IN ('PAGA', 'CONCLUIDA');
