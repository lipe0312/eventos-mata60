SET SCHEMA 'eventos';

INSERT INTO tbl_resposta_termo (ce_inscricao, ce_termo, ind_aceite, dt_resposta)
SELECT i.cp_id_inscricao,
       t.cp_id_termo,
       NOT (t.nm_termo = 'Uso de imagem e voz' AND MOD(i.cp_id_inscricao, 10) = 0),
       i.dt_inscricao + INTERVAL '5' MINUTE
  FROM tbl_inscricao i
  JOIN tbl_termo t
    ON t.dt_inicio_vigencia <= i.dt_inscricao
   AND (t.dt_fim_vigencia IS NULL OR t.dt_fim_vigencia >= i.dt_inscricao)
 ORDER BY i.cp_id_inscricao, t.cp_id_termo;

UPDATE tbl_inscricao
   SET status_inscricao = 'CANCELADA',
       dt_cancelamento = dt_confirmacao + INTERVAL '3' DAY
 WHERE status_inscricao = 'PAGA'
   AND MOD(cp_id_inscricao, 30) = 0
   AND ce_preco IN (
       SELECT p.cp_id_preco FROM tbl_preco p
         JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
         JOIN tbl_edicao_evento e ON e.cp_id_edicao = c.ce_edicao
        WHERE e.ano_edicao = 2026
 );

UPDATE tbl_inscricao
   SET status_inscricao = 'CANCELADA',
       dt_cancelamento = (
           SELECT CAST(e.dt_inicio_evento AS timestamp) - INTERVAL '2' DAY
             FROM tbl_preco p
             JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
             JOIN tbl_edicao_evento e ON e.cp_id_edicao = c.ce_edicao
            WHERE p.cp_id_preco = tbl_inscricao.ce_preco
       )
 WHERE status_inscricao = 'PAGA'
   AND MOD(cp_id_inscricao, 50) = 7
   AND ce_preco IN (
       SELECT p.cp_id_preco FROM tbl_preco p
         JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
         JOIN tbl_edicao_evento e ON e.cp_id_edicao = c.ce_edicao
        WHERE e.ano_edicao = 2025
 );

UPDATE tbl_inscricao
   SET status_inscricao = 'CANCELADA',
       dt_cancelamento = dt_inscricao + INTERVAL '3' DAY
 WHERE status_inscricao = 'AGUARDANDO_PAGAMENTO'
   AND MOD(cp_id_inscricao, 30) = 15;

UPDATE tbl_inscricao_atividade
   SET status_inscricao_atividade = 'CANCELADA',
       dt_cancelamento = dt_inclusao + INTERVAL '5' DAY
 WHERE status_inscricao_atividade = 'CONFIRMADA'
   AND MOD(cp_id_inscricao_atividade, 40) = 3;

UPDATE tbl_inscricao
   SET status_inscricao = 'EXPIRADA'
 WHERE status_inscricao IN ('INICIADA', 'AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO')
   AND ce_preco IN (
       SELECT p.cp_id_preco FROM tbl_preco p
         JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
         JOIN tbl_edicao_evento e ON e.cp_id_edicao = c.ce_edicao
        WHERE e.ano_edicao = 2025
 );

UPDATE tbl_inscricao
   SET dt_credenciamento = (
       SELECT CAST(e.dt_inicio_evento AS timestamp) + INTERVAL '8' HOUR
              + MOD(tbl_inscricao.cp_id_inscricao, 180) * INTERVAL '1' MINUTE
         FROM tbl_preco p
         JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
         JOIN tbl_edicao_evento e ON e.cp_id_edicao = c.ce_edicao
        WHERE p.cp_id_preco = tbl_inscricao.ce_preco
   )
 WHERE status_inscricao = 'PAGA'
   AND MOD(cp_id_inscricao, 10) <> 0
   AND ce_preco IN (
       SELECT p.cp_id_preco FROM tbl_preco p
         JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
         JOIN tbl_edicao_evento e ON e.cp_id_edicao = c.ce_edicao
        WHERE e.ano_edicao = 2025
 );

UPDATE tbl_inscricao_atividade
   SET dt_presenca = (
       SELECT a.dt_inicio + INTERVAL '10' MINUTE
         FROM tbl_atividade a
        WHERE a.cp_id_atividade = tbl_inscricao_atividade.ce_atividade
   )
 WHERE status_inscricao_atividade = 'CONFIRMADA'
   AND MOD(cp_id_inscricao_atividade, 5) <> 0
   AND ce_inscricao IN (
       SELECT cp_id_inscricao FROM tbl_inscricao WHERE dt_credenciamento IS NOT NULL
 );

UPDATE tbl_inscricao
   SET status_inscricao = 'CONCLUIDA'
 WHERE status_inscricao = 'PAGA'
   AND ce_preco IN (
       SELECT p.cp_id_preco FROM tbl_preco p
         JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
         JOIN tbl_edicao_evento e ON e.cp_id_edicao = c.ce_edicao
        WHERE e.ano_edicao = 2025
 );
