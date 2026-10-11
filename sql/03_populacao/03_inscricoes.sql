SET SCHEMA 'eventos';

INSERT INTO tbl_inscricao (ce_pessoa, ce_preco, ce_beneficio, dt_inscricao, status_inscricao, dt_uso_beneficio)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 9000
),
pessoa AS (
    SELECT cp_id_pessoa, ROW_NUMBER() OVER (ORDER BY cp_id_pessoa) AS r FROM tbl_pessoa
),
edicao AS (
    SELECT cp_id_edicao, dt_inicio_inscricao, ROW_NUMBER() OVER (ORDER BY cp_id_edicao) AS k FROM tbl_edicao_evento
),
categoria AS (
    SELECT cp_id_categoria, ce_edicao,
           ROW_NUMBER() OVER (PARTITION BY ce_edicao ORDER BY cp_id_categoria) AS c
      FROM tbl_categoria_inscricao
),
base AS (
    SELECT s.n,
           p.cp_id_pessoa,
           e.cp_id_edicao,
           cat.cp_id_categoria,
           e.dt_inicio_inscricao
             + MOD(s.n * 13, 180) * INTERVAL '1' DAY
             + MOD(s.n * 7, 1440) * INTERVAL '1' MINUTE AS dt_inscricao,
           CASE
               WHEN MOD(p.cp_id_pessoa, 5) = 0 THEN 'ASSOCIADO'
               WHEN MOD(p.cp_id_pessoa, 5) = 1 AND s.n <= 6000 AND MOD(s.n, 3) = 0 THEN 'COMBO_RENOVACAO'
               WHEN MOD(p.cp_id_pessoa, 5) > 1 AND s.n <= 6000 AND MOD(s.n, 7) = 0 THEN 'COMBO_NOVA'
               ELSE 'NAO_ASSOCIADO'
           END AS tp_associacao,
           CASE
               WHEN MOD(p.cp_id_pessoa, 2) = 0 AND MOD(s.n, 17) = 0 THEN
                   CASE WHEN MOD(s.n / 17, 2) = 0 THEN 'GRATUIDADE' ELSE 'DESCONTO' END
           END AS tp_beneficio
      FROM seq s
      JOIN pessoa p ON p.r = MOD(s.n - 1, 6000) + 1
      JOIN edicao e ON e.k = CASE WHEN s.n <= 6000 THEN MOD(s.n - 1, 20) + 1 ELSE MOD(s.n, 20) + 1 END
      JOIN categoria cat ON cat.ce_edicao = e.cp_id_edicao AND cat.c = MOD((s.n - 1) / 20, 4) + 1
)
SELECT b.cp_id_pessoa,
       pr.cp_id_preco,
       bn.cp_id_beneficio,
       b.dt_inscricao,
       'INICIADA',
       CASE WHEN bn.cp_id_beneficio IS NOT NULL THEN b.dt_inscricao END
  FROM base b
  JOIN tbl_faixa_inscricao f
    ON f.ce_edicao = b.cp_id_edicao
   AND f.dt_inicio_faixa <= b.dt_inscricao
   AND b.dt_inscricao < f.dt_fim_faixa
  JOIN tbl_preco pr
    ON pr.ce_categoria = b.cp_id_categoria
   AND pr.ce_faixa = f.cp_id_faixa
   AND pr.tp_associacao = b.tp_associacao
  LEFT JOIN tbl_vinculo_institucional v
    ON v.ce_pessoa = b.cp_id_pessoa
   AND v.dt_fim_vinculo IS NULL
  LEFT JOIN tbl_beneficio bn
    ON bn.ce_instituicao = v.ce_instituicao
   AND bn.tp_beneficio = b.tp_beneficio
 ORDER BY b.n;
