SET SCHEMA 'eventos';

BEGIN;

INSERT INTO tbl_trabalho (ce_edicao, cd_trabalho_externo, titulo_trabalho, tp_trabalho, status_trabalho)
WITH RECURSIVE seq (t) AS (
    SELECT 1 UNION ALL SELECT t + 1 FROM seq WHERE t < 15
)
SELECT ed.cp_id_edicao,
       'SUB-' || ev.sg_evento || '-' || CAST(ed.ano_edicao AS varchar(4)) || '-' || CAST(s.t AS varchar(2)),
       'Trabalho ' || CAST(s.t AS varchar(2)) || ' do ' || ev.sg_evento || ' ' || CAST(ed.ano_edicao AS varchar(4)),
       CASE MOD(s.t, 3) WHEN 0 THEN 'POSTER' WHEN 1 THEN 'ARTIGO_COMPLETO' ELSE 'ARTIGO_CURTO' END,
       'ACEITO'
  FROM tbl_edicao_evento ed
  JOIN tbl_evento ev ON ev.cp_id_evento = ed.ce_evento
 CROSS JOIN seq s
 ORDER BY ed.cp_id_edicao, s.t;

CREATE LOCAL TEMPORARY TABLE tmp_autoria AS
WITH autor AS (
    SELECT i.cp_id_inscricao, i.ce_pessoa, c.ce_edicao,
           ROW_NUMBER() OVER (PARTITION BY c.ce_edicao ORDER BY i.cp_id_inscricao) AS r
      FROM tbl_inscricao i
      JOIN tbl_preco p ON p.cp_id_preco = i.ce_preco
      JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
     WHERE c.ind_categoria_autor
       AND i.status_inscricao = 'AGUARDANDO_PAGAMENTO'
),
trabalho AS (
    SELECT cp_id_trabalho, ce_edicao,
           ROW_NUMBER() OVER (PARTITION BY ce_edicao ORDER BY cp_id_trabalho) AS t
      FROM tbl_trabalho
)
SELECT tr.cp_id_trabalho, tr.ce_edicao, tr.t,
       a1.cp_id_inscricao AS ce_inscricao,
       a1.ce_pessoa AS ce_autor,
       a2.ce_pessoa AS ce_coautor
  FROM trabalho tr
  JOIN autor a1 ON a1.ce_edicao = tr.ce_edicao AND a1.r = (tr.t - 1) / 3 + 1
  LEFT JOIN autor a2 ON a2.ce_edicao = tr.ce_edicao AND a2.r = 10 + tr.t AND MOD(tr.t, 2) = 0;

INSERT INTO tbl_autoria (ce_pessoa, ce_trabalho)
SELECT ce_autor, cp_id_trabalho FROM tmp_autoria
UNION
SELECT ce_coautor, cp_id_trabalho FROM tmp_autoria WHERE ce_coautor IS NOT NULL
UNION
SELECT 5000 + ce_edicao * 15 + t, cp_id_trabalho FROM tmp_autoria WHERE MOD(t, 5) = 0;

UPDATE tbl_trabalho
   SET ce_inscricao_cobertura = (
       SELECT ce_inscricao FROM tmp_autoria WHERE tmp_autoria.cp_id_trabalho = tbl_trabalho.cp_id_trabalho
   )
 WHERE cp_id_trabalho IN (SELECT cp_id_trabalho FROM tmp_autoria WHERE MOD(t, 5) <> 0);

DROP TABLE tmp_autoria;

COMMIT;
