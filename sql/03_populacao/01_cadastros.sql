SET SCHEMA 'eventos';

INSERT INTO tbl_instituicao
    (nm_instituicao, sg_instituicao, pais_instituicao, ind_associada, cnpj_instituicao, cidade_instituicao, uf_instituicao)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 40
)
SELECT 'Instituição ' || CAST(n AS varchar(10)),
       'INST' || CAST(n AS varchar(10)),
       'BR',
       MOD(n, 2) = 1,
       CAST(10000000000000 + n AS varchar(14)),
       CASE MOD(n, 5) WHEN 0 THEN 'Salvador' WHEN 1 THEN 'São Paulo' WHEN 2 THEN 'Rio de Janeiro'
                      WHEN 3 THEN 'Belo Horizonte' ELSE 'Recife' END,
       CASE MOD(n, 5) WHEN 0 THEN 'BA' WHEN 1 THEN 'SP' WHEN 2 THEN 'RJ' WHEN 3 THEN 'MG' ELSE 'PE' END
  FROM seq
 ORDER BY n;

INSERT INTO tbl_beneficio
    (ce_instituicao, tp_beneficio, dt_inicio_vigencia, dt_fim_vigencia, nr_limite_periodo, nr_limite_por_edicao, pc_desconto)
SELECT i.cp_id_instituicao, b.tp, DATE '2025-01-01', DATE '2026-12-31', b.limite_periodo, b.limite_edicao, b.pc
  FROM tbl_instituicao i
 CROSS JOIN (VALUES ('GRATUIDADE', 30, 10, CAST(NULL AS numeric(5,2))),
                    ('DESCONTO', 100, 20, CAST(50.00 AS numeric(5,2)))) AS b (tp, limite_periodo, limite_edicao, pc)
 WHERE i.ind_associada
 ORDER BY i.cp_id_instituicao, b.tp;

INSERT INTO tbl_pessoa
    (nm_pessoa, email_pessoa, pais_pessoa, uf_pessoa, cpf_pessoa, passaporte_pessoa, dt_nascimento, ind_anonimizada)
WITH RECURSIVE seq (n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 6000
)
SELECT 'Participante ' || CAST(n AS varchar(10)),
       'participante' || CAST(n AS varchar(10)) || '@exemplo.org',
       CASE WHEN MOD(n, 20) = 0 THEN 'AR' ELSE 'BR' END,
       CASE WHEN MOD(n, 20) = 0 THEN NULL
            ELSE CASE MOD(n, 8) WHEN 0 THEN 'BA' WHEN 1 THEN 'SP' WHEN 2 THEN 'RJ' WHEN 3 THEN 'MG'
                                WHEN 4 THEN 'PE' WHEN 5 THEN 'RS' WHEN 6 THEN 'PR' ELSE 'CE' END END,
       CASE WHEN MOD(n, 20) = 0 THEN NULL ELSE CAST(10000000000 + n AS varchar(11)) END,
       CASE WHEN MOD(n, 20) = 0 THEN 'AR' || CAST(100000 + n AS varchar(10)) END,
       CAST(DATE '1970-01-01' + MOD(n * 37, 12000) * INTERVAL '1' DAY AS date),
       FALSE
  FROM seq
 ORDER BY n;

INSERT INTO tbl_vinculo_institucional (ce_pessoa, ce_instituicao, dt_inicio_vinculo, tp_vinculo, dt_fim_vinculo)
SELECT p.cp_id_pessoa,
       i.cp_id_instituicao,
       CAST(DATE '2020-01-01' + MOD(p.cp_id_pessoa, 365) * INTERVAL '1' DAY AS date),
       CASE MOD(p.cp_id_pessoa, 5) WHEN 0 THEN 'ESTUDANTE' WHEN 1 THEN 'DOCENTE' WHEN 2 THEN 'SERVIDOR'
                                   WHEN 3 THEN 'FUNCIONARIO' ELSE 'OUTRO' END,
       NULL
  FROM tbl_pessoa p
  JOIN tbl_instituicao i ON i.sg_instituicao = 'INST' || CAST(MOD(p.cp_id_pessoa, 40) + 1 AS varchar(10));

INSERT INTO tbl_vinculo_institucional (ce_pessoa, ce_instituicao, dt_inicio_vinculo, tp_vinculo, dt_fim_vinculo)
SELECT p.cp_id_pessoa, i.cp_id_instituicao, DATE '2015-03-01', 'ESTUDANTE', DATE '2019-12-31'
  FROM tbl_pessoa p
  JOIN tbl_instituicao i ON i.sg_instituicao = 'INST' || CAST(MOD(p.cp_id_pessoa + 7, 40) + 1 AS varchar(10))
 WHERE MOD(p.cp_id_pessoa, 10) = 0;

INSERT INTO tbl_periodo_associacao (ce_pessoa, dt_inicio_associacao, dt_fim_associacao)
SELECT cp_id_pessoa,
       CASE WHEN MOD(cp_id_pessoa, 5) = 0 THEN DATE '2025-01-01' ELSE DATE '2023-01-01' END,
       CASE WHEN MOD(cp_id_pessoa, 5) = 0 THEN DATE '2026-12-31' ELSE DATE '2024-12-31' END
  FROM tbl_pessoa
 WHERE MOD(cp_id_pessoa, 5) IN (0, 1);

INSERT INTO tbl_termo (nm_termo, nr_versao, ds_termo, dt_inicio_vigencia, dt_fim_vigencia)
VALUES
    ('Uso de imagem e voz', '1.0', 'Autorizo o uso da minha imagem e voz em registros do evento.',
     TIMESTAMP '2024-01-01 00:00:00', TIMESTAMP '2025-12-31 23:59:59'),
    ('Uso de imagem e voz', '2.0', 'Autorizo o uso da minha imagem e voz em registros e transmissões do evento.',
     TIMESTAMP '2026-01-01 00:00:00', NULL),
    ('Política de privacidade', '1.0', 'Declaro ciência do tratamento dos meus dados pessoais pela SBTC.',
     TIMESTAMP '2024-01-01 00:00:00', TIMESTAMP '2025-12-31 23:59:59'),
    ('Política de privacidade', '2.0', 'Declaro ciência do tratamento dos meus dados pessoais pela SBTC, conforme a LGPD.',
     TIMESTAMP '2026-01-01 00:00:00', NULL);
