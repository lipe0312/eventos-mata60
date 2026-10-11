SET SCHEMA 'eventos';

BEGIN;

INSERT INTO tbl_evento (sg_evento, nm_evento, tp_evento, ds_evento)
VALUES
    ('CTC', 'Congresso de Tecnologia e Computação', 'CONGRESSO', 'Congresso anual da SBTC, agregador de eventos satélites.'),
    ('SSI', 'Simpósio de Sistemas de Informação', 'SIMPOSIO', NULL),
    ('SBD', 'Simpósio de Bancos de Dados', 'SIMPOSIO', NULL),
    ('SES', 'Simpósio de Engenharia de Software', 'SIMPOSIO', NULL),
    ('CIA', 'Conferência de Inteligência Artificial', 'CONGRESSO', NULL),
    ('WEC', 'Workshop de Educação em Computação', 'WORKSHOP', NULL),
    ('WTD', 'Workshop de Teses e Dissertações', 'WORKSHOP', NULL),
    ('ERC', 'Escola Regional de Computação', 'ESCOLA', NULL),
    ('MPR', 'Maratona de Programação', 'COMPETICAO', NULL),
    ('FTI', 'Fórum de Tecnologia e Inovação', 'OUTRO', NULL);

INSERT INTO tbl_edicao_evento
    (ce_evento, ano_edicao, nr_edicao, dt_inicio_evento, dt_fim_evento, dt_inicio_inscricao, dt_fim_inscricao,
     modalidade_evento, cidade_evento, uf_evento, pais_evento, nr_dias_reserva, nr_dias_limite_reembolso,
     pc_reembolso, ind_exige_credenciamento, pc_frequencia_minima, nr_max_trabalhos_inscricao, vl_taxa_trabalho_extra)
SELECT e.cp_id_evento,
       a.ano,
       a.ano - 2000,
       CAST(a.inicio_evento + e.cp_id_evento * INTERVAL '1' DAY AS date),
       CAST(a.inicio_evento + (e.cp_id_evento + 3) * INTERVAL '1' DAY AS date),
       a.inicio_inscricao,
       a.fim_inscricao,
       CASE MOD(e.cp_id_evento, 3) WHEN 0 THEN 'REMOTO' WHEN 1 THEN 'PRESENCIAL' ELSE 'HIBRIDO' END,
       'Salvador', 'BA', 'BR',
       7, 15, 80.00,
       MOD(e.cp_id_evento, 3) <> 0,
       CASE WHEN MOD(e.cp_id_evento, 2) = 0 THEN 75.00 END,
       2, 150.00
  FROM tbl_evento e
 CROSS JOIN (VALUES
       (2025, DATE '2025-09-01', TIMESTAMP '2025-03-01 00:00:00', TIMESTAMP '2025-08-31 23:59:59'),
       (2026, DATE '2026-11-01', TIMESTAMP '2026-03-01 00:00:00', TIMESTAMP '2026-10-31 23:59:59')
 ) AS a (ano, inicio_evento, inicio_inscricao, fim_inscricao)
 ORDER BY a.ano, e.cp_id_evento;

UPDATE tbl_edicao_evento
   SET ce_edicao_agregadora = (
       SELECT ed.cp_id_edicao
         FROM tbl_edicao_evento ed
         JOIN tbl_evento ev ON ev.cp_id_evento = ed.ce_evento
        WHERE ev.sg_evento = 'CTC' AND ed.ano_edicao = 2025
   )
 WHERE ano_edicao = 2025
   AND ce_evento IN (SELECT cp_id_evento FROM tbl_evento WHERE sg_evento IN ('SSI', 'SBD'));

INSERT INTO tbl_categoria_inscricao (ce_edicao, nm_categoria, ind_exige_comprovacao, ind_categoria_autor, ds_categoria)
SELECT ed.cp_id_edicao, c.nm, c.exige, c.autor, NULL
  FROM tbl_edicao_evento ed
 CROSS JOIN (VALUES (1, 'Estudante de graduação', TRUE, FALSE),
                    (2, 'Estudante de pós-graduação', TRUE, TRUE),
                    (3, 'Professor', FALSE, TRUE),
                    (4, 'Profissional', FALSE, TRUE)) AS c (ordem, nm, exige, autor)
 ORDER BY ed.cp_id_edicao, c.ordem;

INSERT INTO tbl_faixa_inscricao (ce_edicao, nm_faixa, dt_inicio_faixa, dt_fim_faixa)
SELECT ed.cp_id_edicao,
       f.nm,
       CASE f.ordem WHEN 1 THEN ed.dt_inicio_inscricao
                    WHEN 2 THEN ed.dt_inicio_inscricao + INTERVAL '2' MONTH
                    ELSE ed.dt_inicio_inscricao + INTERVAL '4' MONTH END,
       CASE f.ordem WHEN 1 THEN ed.dt_inicio_inscricao + INTERVAL '2' MONTH
                    WHEN 2 THEN ed.dt_inicio_inscricao + INTERVAL '4' MONTH
                    ELSE ed.dt_fim_inscricao END
  FROM tbl_edicao_evento ed
 CROSS JOIN (VALUES (1, 'Primeiro lote'), (2, 'Segundo lote'), (3, 'Inscrição tardia')) AS f (ordem, nm)
 ORDER BY ed.cp_id_edicao, f.ordem;

INSERT INTO tbl_preco (ce_categoria, ce_faixa, tp_associacao, vl_inscricao, vl_associacao)
SELECT c.cp_id_categoria,
       f.cp_id_faixa,
       t.tp,
       ROUND(
           CASE c.nm_categoria WHEN 'Estudante de graduação' THEN 100 WHEN 'Estudante de pós-graduação' THEN 200
                               WHEN 'Professor' THEN 400 ELSE 500 END
         * CASE f.nm_faixa WHEN 'Primeiro lote' THEN 1.0 WHEN 'Segundo lote' THEN 1.2 ELSE 1.5 END
         * CASE WHEN t.tp = 'NAO_ASSOCIADO' THEN 1.0 ELSE 0.7 END, 2),
       t.vl_assoc
  FROM tbl_categoria_inscricao c
  JOIN tbl_faixa_inscricao f ON f.ce_edicao = c.ce_edicao
 CROSS JOIN (VALUES ('NAO_ASSOCIADO', CAST(NULL AS numeric(10,2))),
                    ('ASSOCIADO', CAST(NULL AS numeric(10,2))),
                    ('COMBO_NOVA', CAST(120.00 AS numeric(10,2))),
                    ('COMBO_RENOVACAO', CAST(100.00 AS numeric(10,2)))) AS t (tp, vl_assoc)
 ORDER BY c.cp_id_categoria, f.cp_id_faixa, t.tp;

INSERT INTO tbl_organizacao_edicao (ce_pessoa, ce_edicao, tp_papel)
SELECT (ed.cp_id_edicao - 1) * 3 + p.ordem, ed.cp_id_edicao, p.papel
  FROM tbl_edicao_evento ed
 CROSS JOIN (VALUES (1, 'COORD_GERAL'), (2, 'COORD_FINANCEIRA'), (3, 'APOIO_ADMIN')) AS p (ordem, papel);

INSERT INTO tbl_atividade
    (ce_edicao, nm_atividade, dt_inicio, tp_atividade, dt_fim, ind_inscricao_adicional, nr_capacidade, vl_atividade)
SELECT ed.cp_id_edicao,
       a.nm,
       CAST(ed.dt_inicio_evento AS timestamp) + a.dia * INTERVAL '1' DAY + a.hora * INTERVAL '1' HOUR,
       a.tp,
       CAST(ed.dt_inicio_evento AS timestamp) + a.dia * INTERVAL '1' DAY + (a.hora + a.duracao) * INTERVAL '1' HOUR,
       a.adicional,
       a.capacidade,
       a.valor
  FROM tbl_edicao_evento ed
 CROSS JOIN (VALUES
       (1, 'Palestra de abertura', 'PALESTRA', 0, 9, 2, FALSE, CAST(NULL AS int), CAST(NULL AS numeric(10,2))),
       (2, 'Minicurso de introdução', 'MINICURSO', 0, 14, 4, TRUE, 40, CAST(80.00 AS numeric(10,2))),
       (3, 'Minicurso avançado', 'MINICURSO', 1, 14, 4, TRUE, 40, CAST(60.00 AS numeric(10,2))),
       (4, 'Workshop temático', 'WORKSHOP', 1, 9, 3, FALSE, CAST(NULL AS int), CAST(NULL AS numeric(10,2))),
       (5, 'Visita técnica', 'VISITA', 2, 9, 4, TRUE, 30, CAST(NULL AS numeric(10,2))),
       (6, 'Jantar de confraternização', 'SOCIAL', 2, 20, 3, TRUE, 100, CAST(150.00 AS numeric(10,2)))
 ) AS a (ordem, nm, tp, dia, hora, duracao, adicional, capacidade, valor)
 ORDER BY ed.cp_id_edicao, a.ordem;

INSERT INTO tbl_restricao_atividade (ce_atividade, ce_categoria)
SELECT a.cp_id_atividade, c.cp_id_categoria
  FROM tbl_atividade a
  JOIN tbl_categoria_inscricao c ON c.ce_edicao = a.ce_edicao
 WHERE a.nm_atividade = 'Minicurso avançado'
   AND c.nm_categoria IN ('Estudante de pós-graduação', 'Professor');

COMMIT;
