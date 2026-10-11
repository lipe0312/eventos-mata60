SET SCHEMA 'eventos';

INSERT INTO tbl_pagamento (ce_inscricao, dt_criacao, tp_pagamento, vl_pagamento, status_pagamento)
SELECT i.cp_id_inscricao, i.dt_inscricao + INTERVAL '2' HOUR, 'CARTAO', s.vl_devido, 'PENDENTE'
  FROM tbl_inscricao i
  JOIN (SELECT ce_inscricao,
               SUM(CASE WHEN tp_item = 'DESCONTO' THEN -vl_item ELSE vl_item END) AS vl_devido
          FROM tbl_item_financeiro
         WHERE status_item = 'VALIDO'
         GROUP BY ce_inscricao) s ON s.ce_inscricao = i.cp_id_inscricao
 WHERE i.status_inscricao = 'AGUARDANDO_PAGAMENTO'
   AND s.vl_devido > 0
   AND MOD(i.cp_id_inscricao, 9) = 0
 ORDER BY i.cp_id_inscricao;

UPDATE tbl_pagamento
   SET status_pagamento = 'RECUSADO'
 WHERE status_pagamento = 'PENDENTE';

INSERT INTO tbl_pagamento (ce_inscricao, dt_criacao, tp_pagamento, vl_pagamento, status_pagamento, dt_vencimento)
SELECT i.cp_id_inscricao,
       i.dt_inscricao + INTERVAL '1' DAY,
       CASE MOD(i.cp_id_inscricao, 4) WHEN 0 THEN 'CARTAO' WHEN 1 THEN 'BOLETO'
                                      WHEN 2 THEN 'FATURAMENTO' ELSE 'EMPENHO' END,
       s.vl_devido,
       'PENDENTE',
       CASE MOD(i.cp_id_inscricao, 4) WHEN 1 THEN CAST(i.dt_inscricao + INTERVAL '4' DAY AS date)
                                      WHEN 3 THEN CAST(i.dt_inscricao + INTERVAL '30' DAY AS date) END
  FROM tbl_inscricao i
  JOIN (SELECT ce_inscricao,
               SUM(CASE WHEN tp_item = 'DESCONTO' THEN -vl_item ELSE vl_item END) AS vl_devido
          FROM tbl_item_financeiro
         WHERE status_item = 'VALIDO'
         GROUP BY ce_inscricao) s ON s.ce_inscricao = i.cp_id_inscricao
 WHERE i.status_inscricao = 'AGUARDANDO_PAGAMENTO'
   AND s.vl_devido > 0
   AND MOD(i.cp_id_inscricao, 23) <> 1
 ORDER BY i.cp_id_inscricao;

UPDATE tbl_pagamento
   SET status_pagamento = 'CONFIRMADO',
       dt_confirmacao = dt_criacao + INTERVAL '1' HOUR,
       cd_transacao_externa = 'TX' || CAST(cp_id_pagamento AS varchar(20))
 WHERE status_pagamento = 'PENDENTE'
   AND MOD(ce_inscricao, 23) <> 2;

UPDATE tbl_inscricao i
   SET status_inscricao = 'PAGA',
       dt_confirmacao = COALESCE(
           (SELECT MAX(pg.dt_confirmacao) FROM tbl_pagamento pg
             WHERE pg.ce_inscricao = i.cp_id_inscricao AND pg.status_pagamento = 'CONFIRMADO'),
           i.dt_inscricao + INTERVAL '1' DAY)
 WHERE i.status_inscricao = 'AGUARDANDO_PAGAMENTO'
   AND (SELECT COALESCE(SUM(CASE WHEN it.tp_item = 'DESCONTO' THEN -it.vl_item ELSE it.vl_item END), 0)
          FROM tbl_item_financeiro it
         WHERE it.ce_inscricao = i.cp_id_inscricao AND it.status_item = 'VALIDO')
     - (SELECT COALESCE(SUM(pg.vl_pagamento), 0)
          FROM tbl_pagamento pg
         WHERE pg.ce_inscricao = i.cp_id_inscricao AND pg.status_pagamento = 'CONFIRMADO') <= 0;
