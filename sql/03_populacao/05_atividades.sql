SET SCHEMA 'eventos';

INSERT INTO tbl_inscricao_atividade (ce_inscricao, ce_atividade, dt_inclusao, status_inscricao_atividade)
WITH candidata AS (
    SELECT i.cp_id_inscricao, i.dt_inscricao, c.ce_edicao, p.ce_categoria,
           MOD(i.cp_id_inscricao, 6) + 1 AS ordem, 30 AS minutos
      FROM tbl_inscricao i
      JOIN tbl_preco p ON p.cp_id_preco = i.ce_preco
      JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
     WHERE i.status_inscricao IN ('INICIADA', 'AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO')
       AND MOD(i.cp_id_inscricao, 10) < 6
    UNION ALL
    SELECT i.cp_id_inscricao, i.dt_inscricao, c.ce_edicao, p.ce_categoria,
           MOD(i.cp_id_inscricao + 3, 6) + 1, 40
      FROM tbl_inscricao i
      JOIN tbl_preco p ON p.cp_id_preco = i.ce_preco
      JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
     WHERE i.status_inscricao IN ('INICIADA', 'AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO')
       AND MOD(i.cp_id_inscricao, 10) = 0
),
atividade AS (
    SELECT cp_id_atividade, ce_edicao, nr_capacidade,
           ROW_NUMBER() OVER (PARTITION BY ce_edicao ORDER BY cp_id_atividade) AS ordem
      FROM tbl_atividade
),
elegivel AS (
    SELECT ca.cp_id_inscricao, ca.dt_inscricao, ca.minutos, a.cp_id_atividade, a.nr_capacidade,
           ROW_NUMBER() OVER (PARTITION BY a.cp_id_atividade ORDER BY ca.cp_id_inscricao) AS posicao
      FROM candidata ca
      JOIN atividade a ON a.ce_edicao = ca.ce_edicao AND a.ordem = ca.ordem
     WHERE NOT EXISTS (SELECT 1 FROM tbl_restricao_atividade r WHERE r.ce_atividade = a.cp_id_atividade)
        OR EXISTS (
           SELECT 1 FROM tbl_restricao_atividade r
            WHERE r.ce_atividade = a.cp_id_atividade AND r.ce_categoria = ca.ce_categoria
        )
)
SELECT cp_id_inscricao, cp_id_atividade, dt_inscricao + minutos * INTERVAL '1' MINUTE, 'RESERVADA'
  FROM elegivel
 WHERE nr_capacidade IS NULL OR posicao <= nr_capacidade
 ORDER BY cp_id_inscricao, cp_id_atividade;
