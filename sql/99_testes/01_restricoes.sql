\set ON_ERROR_STOP on
SET SCHEMA 'eventos';

BEGIN;

CREATE LOCAL TEMPORARY TABLE tmp_resultado (
    nr_caso   int GENERATED ALWAYS AS IDENTITY,
    ds_caso   varchar(200),
    ind_ok    boolean,
    ds_obtido varchar(1000)
);

CREATE FUNCTION pg_temp.fn_espera_erro(p_caso varchar, p_sql varchar, p_erro varchar) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
        INSERT INTO tmp_resultado (ds_caso, ind_ok, ds_obtido) VALUES (p_caso, FALSE, 'aceito sem erro');
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO tmp_resultado (ds_caso, ind_ok, ds_obtido)
        VALUES (p_caso, POSITION(p_erro IN SQLERRM) > 0, SQLERRM);
    END;
END;
$$;

CREATE FUNCTION pg_temp.fn_espera_sucesso(p_caso varchar, p_sql varchar) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
        INSERT INTO tmp_resultado (ds_caso, ind_ok, ds_obtido) VALUES (p_caso, TRUE, 'aceito');
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO tmp_resultado (ds_caso, ind_ok, ds_obtido) VALUES (p_caso, FALSE, SQLERRM);
    END;
END;
$$;

CREATE FUNCTION pg_temp.fn_espera_verdadeiro(p_caso varchar, p_sql varchar) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    v_resultado boolean;
BEGIN
    EXECUTE p_sql INTO v_resultado;
    INSERT INTO tmp_resultado (ds_caso, ind_ok, ds_obtido)
    VALUES (p_caso, COALESCE(v_resultado, FALSE), CAST(v_resultado AS varchar(10)));
END;
$$;

CREATE LOCAL TEMPORARY TABLE tmp_ref AS
SELECT
    (SELECT MIN(s.cp_id_inscricao) FROM vw_saldo_inscricao s
       JOIN tbl_inscricao i ON i.cp_id_inscricao = s.cp_id_inscricao
      WHERE i.status_inscricao = 'AGUARDANDO_PAGAMENTO' AND s.vl_saldo > 0) AS insc_ag1,
    (SELECT MAX(s.cp_id_inscricao) FROM vw_saldo_inscricao s
       JOIN tbl_inscricao i ON i.cp_id_inscricao = s.cp_id_inscricao
      WHERE i.status_inscricao = 'AGUARDANDO_PAGAMENTO' AND s.vl_saldo > 0) AS insc_ag2,
    (SELECT MIN(cp_id_inscricao) FROM vw_inscricao_detalhe
      WHERE status_inscricao = 'PAGA' AND ano_edicao = 2026) AS insc_paga_2026,
    (SELECT MIN(cp_id_inscricao) FROM tbl_inscricao WHERE status_inscricao = 'AGUARDANDO_VALIDACAO') AS insc_validacao,
    (SELECT MIN(cp_id_inscricao) FROM tbl_inscricao
      WHERE status_inscricao IN ('INICIADA', 'AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO')
        AND ce_beneficio IS NULL AND MOD(ce_pessoa, 2) = 0) AS insc_benef,
    (SELECT MIN(cp_id_edicao) FROM tbl_edicao_evento WHERE ano_edicao = 2026) AS edicao_2026,
    (SELECT ed.cp_id_edicao FROM tbl_edicao_evento ed JOIN tbl_evento ev ON ev.cp_id_evento = ed.ce_evento
      WHERE ev.sg_evento = 'CTC' AND ed.ano_edicao = 2025) AS edicao_agregadora,
    (SELECT MIN(cp_id_edicao) FROM tbl_edicao_evento WHERE ano_edicao = 2025) AS edicao_2025;

SELECT pg_temp.fn_espera_erro('RF3 pessoa sem CPF e sem passaporte',
$q$INSERT INTO tbl_pessoa (nm_pessoa, email_pessoa, pais_pessoa, ind_anonimizada)
   VALUES ('Teste', 'teste.sem.doc@exemplo.org', 'BR', FALSE)$q$, 'ck_pessoa_documento');

SELECT pg_temp.fn_espera_erro('RF3 e-mail duplicado',
$q$INSERT INTO tbl_pessoa (nm_pessoa, email_pessoa, pais_pessoa, cpf_pessoa, ind_anonimizada)
   VALUES ('Teste', 'participante1@exemplo.org', 'BR', '99999999999', FALSE)$q$, 'uq_pessoa_email');

SELECT pg_temp.fn_espera_erro('RE13 UF inválida',
$q$INSERT INTO tbl_pessoa (nm_pessoa, email_pessoa, pais_pessoa, uf_pessoa, cpf_pessoa, ind_anonimizada)
   VALUES ('Teste', 'teste.uf@exemplo.org', 'BR', 'XX', '99999999998', FALSE)$q$, 'ck_pessoa_uf');

SELECT pg_temp.fn_espera_erro('RF1 duas edições do mesmo evento no mesmo ano',
$q$INSERT INTO tbl_edicao_evento (ce_evento, ano_edicao, dt_inicio_evento, dt_fim_evento, dt_inicio_inscricao,
       dt_fim_inscricao, modalidade_evento, cidade_evento, pais_evento, nr_dias_reserva, nr_dias_limite_reembolso,
       pc_reembolso, ind_exige_credenciamento)
   SELECT ce_evento, ano_edicao, dt_inicio_evento, dt_fim_evento, dt_inicio_inscricao, dt_fim_inscricao,
          modalidade_evento, cidade_evento, pais_evento, nr_dias_reserva, nr_dias_limite_reembolso,
          pc_reembolso, ind_exige_credenciamento
     FROM tbl_edicao_evento WHERE cp_id_edicao = (SELECT edicao_2026 FROM tmp_ref)$q$, 'uq_edicao_evento_ano');

SELECT pg_temp.fn_espera_erro('RF1 edição terminando antes de começar',
$q$UPDATE tbl_edicao_evento SET dt_fim_evento = dt_inicio_evento - 1
    WHERE cp_id_edicao = (SELECT edicao_2026 FROM tmp_ref)$q$, 'ck_edicao_evento_datas');

SELECT pg_temp.fn_espera_erro('RF2 edição agregando a si mesma',
$q$UPDATE tbl_edicao_evento SET ce_edicao_agregadora = cp_id_edicao
    WHERE cp_id_edicao = (SELECT edicao_2026 FROM tmp_ref)$q$, 'ck_edicao_evento_agregadora');

SELECT pg_temp.fn_espera_erro('RF2 agregadora não pode ser agregada',
$q$UPDATE tbl_edicao_evento SET ce_edicao_agregadora = (SELECT edicao_2026 FROM tmp_ref)
    WHERE cp_id_edicao = (SELECT edicao_agregadora FROM tmp_ref)$q$, 'fn_edicao_agregacao');

SELECT pg_temp.fn_espera_erro('RF5 categoria repetida na edição',
$q$INSERT INTO tbl_categoria_inscricao (ce_edicao, nm_categoria, ind_exige_comprovacao, ind_categoria_autor)
   VALUES ((SELECT edicao_2026 FROM tmp_ref), 'Professor', FALSE, TRUE)$q$, 'uq_categoria_inscricao_nome');

SELECT pg_temp.fn_espera_erro('RF6 faixas sobrepostas',
$q$INSERT INTO tbl_faixa_inscricao (ce_edicao, nm_faixa, dt_inicio_faixa, dt_fim_faixa)
   VALUES ((SELECT edicao_2026 FROM tmp_ref), 'Lote extra', TIMESTAMP '2026-04-01 00:00:00',
           TIMESTAMP '2026-04-15 00:00:00')$q$, 'fn_faixa_sobreposicao');

SELECT pg_temp.fn_espera_erro('RF6 preço com categoria e faixa de edições diferentes',
$q$INSERT INTO tbl_preco (ce_categoria, ce_faixa, tp_associacao, vl_inscricao)
   VALUES ((SELECT MIN(cp_id_categoria) FROM tbl_categoria_inscricao WHERE ce_edicao = (SELECT edicao_2025 FROM tmp_ref)),
           (SELECT MIN(cp_id_faixa) FROM tbl_faixa_inscricao WHERE ce_edicao = (SELECT edicao_2026 FROM tmp_ref)),
           'NAO_ASSOCIADO', 10)$q$, 'fn_preco_mesma_edicao');

SELECT pg_temp.fn_espera_erro('RF7 COMBO sem valor de associação',
$q$INSERT INTO tbl_preco (ce_categoria, ce_faixa, tp_associacao, vl_inscricao)
   SELECT ce_categoria, ce_faixa, 'COMBO_NOVA', 10 FROM tbl_preco
    WHERE cp_id_preco = (SELECT MIN(cp_id_preco) FROM tbl_preco)$q$, 'ck_preco_vl_associacao');

SELECT pg_temp.fn_espera_erro('RF4 períodos de associação sobrepostos',
$q$INSERT INTO tbl_periodo_associacao (ce_pessoa, dt_inicio_associacao, dt_fim_associacao)
   VALUES (5, DATE '2026-06-01', DATE '2027-05-31')$q$, 'fn_periodo_associacao');

SELECT pg_temp.fn_espera_erro('RF4 preço de associado para quem não é associado',
$q$INSERT INTO tbl_inscricao (ce_pessoa, ce_preco, dt_inscricao, status_inscricao)
   SELECT 2, p.cp_id_preco, TIMESTAMP '2026-03-10 10:00:00', 'INICIADA'
     FROM tbl_preco p JOIN tbl_faixa_inscricao f ON f.cp_id_faixa = p.ce_faixa
    WHERE f.ce_edicao = (SELECT edicao_2026 FROM tmp_ref) AND f.nm_faixa = 'Primeiro lote'
      AND p.tp_associacao = 'ASSOCIADO'
    FETCH FIRST 1 ROW ONLY$q$, 'fn_validar_preco_inscricao');

SELECT pg_temp.fn_espera_erro('RF6 preço de faixa fora da vigência',
$q$INSERT INTO tbl_inscricao (ce_pessoa, ce_preco, dt_inscricao, status_inscricao)
   SELECT 5, p.cp_id_preco, TIMESTAMP '2026-06-10 10:00:00', 'INICIADA'
     FROM tbl_preco p JOIN tbl_faixa_inscricao f ON f.cp_id_faixa = p.ce_faixa
    WHERE f.ce_edicao = (SELECT edicao_2026 FROM tmp_ref) AND f.nm_faixa = 'Primeiro lote'
      AND p.tp_associacao = 'ASSOCIADO'
    FETCH FIRST 1 ROW ONLY$q$, 'fn_validar_preco_inscricao');

SELECT pg_temp.fn_espera_erro('RF9 inscrição criada já paga',
$q$INSERT INTO tbl_inscricao (ce_pessoa, ce_preco, dt_inscricao, status_inscricao)
   SELECT 5, p.cp_id_preco, TIMESTAMP '2026-03-10 10:00:00', 'PAGA'
     FROM tbl_preco p JOIN tbl_faixa_inscricao f ON f.cp_id_faixa = p.ce_faixa
    WHERE f.ce_edicao = (SELECT edicao_2026 FROM tmp_ref) AND f.nm_faixa = 'Primeiro lote'
      AND p.tp_associacao = 'ASSOCIADO'
    FETCH FIRST 1 ROW ONLY$q$, 'fn_inscricao_insert');

SELECT pg_temp.fn_espera_erro('RF9 transição de status inválida',
$q$UPDATE tbl_inscricao SET status_inscricao = 'CONCLUIDA'
    WHERE cp_id_inscricao = (SELECT insc_ag1 FROM tmp_ref)$q$, 'fn_inscricao_update');

SELECT pg_temp.fn_espera_erro('RF8 pagamento liberado sem documento aprovado',
$q$UPDATE tbl_inscricao SET status_inscricao = 'AGUARDANDO_PAGAMENTO'
    WHERE cp_id_inscricao = (SELECT insc_validacao FROM tmp_ref)$q$, 'documento aprovado');

SELECT pg_temp.fn_espera_erro('RF13 inscrição paga sem pagamento confirmado',
$q$UPDATE tbl_inscricao SET status_inscricao = 'PAGA'
    WHERE cp_id_inscricao = (SELECT insc_ag1 FROM tmp_ref)$q$, 'não quitam');

SELECT pg_temp.fn_espera_erro('RF13 pagamento para inscrição já paga',
$q$INSERT INTO tbl_pagamento (ce_inscricao, dt_criacao, tp_pagamento, vl_pagamento, status_pagamento)
   VALUES ((SELECT insc_paga_2026 FROM tmp_ref), LOCALTIMESTAMP, 'CARTAO', 10, 'PENDENTE')$q$, 'fn_pagamento_insert');

SELECT pg_temp.fn_espera_erro('RF13 pagamento criado já confirmado',
$q$INSERT INTO tbl_pagamento (ce_inscricao, dt_criacao, tp_pagamento, vl_pagamento, status_pagamento)
   VALUES ((SELECT insc_ag1 FROM tmp_ref), LOCALTIMESTAMP, 'CARTAO', 10, 'CONFIRMADO')$q$, 'fn_pagamento_insert');

SELECT pg_temp.fn_espera_erro('RF13 pagamento recusado não volta a confirmado',
$q$UPDATE tbl_pagamento SET status_pagamento = 'CONFIRMADO'
    WHERE cp_id_pagamento = (SELECT MIN(cp_id_pagamento) FROM tbl_pagamento WHERE status_pagamento = 'RECUSADO')$q$,
'fn_pagamento_update');

SELECT pg_temp.fn_espera_erro('RF14 boleto sem vencimento',
$q$INSERT INTO tbl_pagamento (ce_inscricao, dt_criacao, tp_pagamento, vl_pagamento, status_pagamento)
   VALUES ((SELECT insc_ag1 FROM tmp_ref), LOCALTIMESTAMP, 'BOLETO', 10, 'PENDENTE')$q$, 'ck_pagamento_vencimento');

SELECT pg_temp.fn_espera_erro('RE15 reembolso sem estorno',
$q$UPDATE tbl_pagamento SET vl_reembolso = 1, dt_reembolso = LOCALTIMESTAMP
    WHERE cp_id_pagamento = (SELECT MIN(cp_id_pagamento) FROM tbl_pagamento WHERE status_pagamento = 'CONFIRMADO')$q$,
'ck_pagamento_estorno');

SELECT pg_temp.fn_espera_erro('RF8 documento analisado não muda',
$q$UPDATE tbl_documento_comprovacao SET status_documento = 'REJEITADO', ds_motivo_rejeicao = 'x'
    WHERE cp_id_documento = (SELECT MIN(cp_id_documento) FROM tbl_documento_comprovacao WHERE status_documento = 'APROVADO')$q$,
'fn_documento_update');

SELECT pg_temp.fn_espera_erro('RE12 rejeição sem motivo',
$q$UPDATE tbl_documento_comprovacao SET status_documento = 'REJEITADO', ce_pessoa_analise = 1
    WHERE cp_id_documento = (SELECT MIN(cp_id_documento) FROM tbl_documento_comprovacao WHERE status_documento = 'PENDENTE')$q$,
'ck_documento_comprovacao_motivo');

SELECT pg_temp.fn_espera_erro('RF8 documento rejeitado não é excluído',
$q$DELETE FROM tbl_documento_comprovacao WHERE status_documento = 'REJEITADO'$q$, 'fn_bloqueia_exclusao');

SELECT pg_temp.fn_espera_erro('RF10 atividade de outra edição',
$q$INSERT INTO tbl_inscricao_atividade (ce_inscricao, ce_atividade, dt_inclusao, status_inscricao_atividade)
   VALUES ((SELECT insc_ag1 FROM tmp_ref),
           (SELECT MIN(cp_id_atividade) FROM tbl_atividade WHERE ce_edicao = (SELECT edicao_2025 FROM tmp_ref)),
           LOCALTIMESTAMP, 'RESERVADA')$q$, 'não pertence à edição');

SELECT pg_temp.fn_espera_erro('RF10 categoria sem acesso à atividade restrita',
$q$INSERT INTO tbl_inscricao_atividade (ce_inscricao, ce_atividade, dt_inclusao, status_inscricao_atividade)
   SELECT d.cp_id_inscricao, a.cp_id_atividade, LOCALTIMESTAMP, 'RESERVADA'
     FROM vw_inscricao_detalhe d
     JOIN tbl_atividade a ON a.ce_edicao = d.cp_id_edicao AND a.nm_atividade = 'Minicurso avançado'
    WHERE d.nm_categoria = 'Estudante de graduação'
      AND d.status_inscricao IN ('INICIADA', 'AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO')
    ORDER BY d.cp_id_inscricao
    FETCH FIRST 1 ROW ONLY$q$, 'não pode selecionar');

UPDATE tbl_atividade a
   SET nr_capacidade = (SELECT COUNT(*) FROM tbl_inscricao_atividade ia
                         WHERE ia.ce_atividade = a.cp_id_atividade
                           AND ia.status_inscricao_atividade IN ('RESERVADA', 'CONFIRMADA'))
 WHERE a.cp_id_atividade = (
       SELECT MIN(cp_id_atividade) FROM tbl_atividade
        WHERE nm_atividade = 'Visita técnica' AND ce_edicao = (SELECT edicao_2026 FROM tmp_ref));

SELECT pg_temp.fn_espera_erro('RF11 atividade sem vagas',
$q$INSERT INTO tbl_inscricao_atividade (ce_inscricao, ce_atividade, dt_inclusao, status_inscricao_atividade)
   SELECT d.cp_id_inscricao, a.cp_id_atividade, LOCALTIMESTAMP, 'RESERVADA'
     FROM vw_inscricao_detalhe d
     JOIN tbl_atividade a ON a.ce_edicao = d.cp_id_edicao AND a.nm_atividade = 'Visita técnica'
    WHERE d.cp_id_edicao = (SELECT edicao_2026 FROM tmp_ref)
      AND d.status_inscricao IN ('INICIADA', 'AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO')
      AND NOT EXISTS (SELECT 1 FROM tbl_inscricao_atividade x
                       WHERE x.ce_inscricao = d.cp_id_inscricao AND x.ce_atividade = a.cp_id_atividade)
    ORDER BY d.cp_id_inscricao
    FETCH FIRST 1 ROW ONLY$q$, 'sem vagas');

SELECT pg_temp.fn_espera_erro('RF10 atividade confirmada não volta a reservada',
$q$UPDATE tbl_inscricao_atividade SET status_inscricao_atividade = 'RESERVADA'
    WHERE cp_id_inscricao_atividade = (SELECT MIN(cp_id_inscricao_atividade) FROM tbl_inscricao_atividade
                                        WHERE status_inscricao_atividade = 'CONFIRMADA')$q$,
'fn_inscricao_atividade_update');

SELECT pg_temp.fn_espera_erro('RF20 credenciamento sem pagamento',
$q$UPDATE tbl_inscricao SET dt_credenciamento = LOCALTIMESTAMP
    WHERE cp_id_inscricao = (SELECT insc_ag1 FROM tmp_ref)$q$, 'ck_inscricao_credenciamento');

SELECT pg_temp.fn_espera_erro('RF21 presença em atividade não confirmada',
$q$UPDATE tbl_inscricao_atividade SET dt_presenca = LOCALTIMESTAMP
    WHERE cp_id_inscricao_atividade = (SELECT MIN(cp_id_inscricao_atividade) FROM tbl_inscricao_atividade
                                        WHERE status_inscricao_atividade = 'RESERVADA')$q$,
'ck_inscricao_atividade_presenca');

SELECT pg_temp.fn_espera_erro('RE4 reserva sem prazo de expiração',
$q$UPDATE tbl_inscricao_atividade SET dt_expira_reserva = NULL
    WHERE cp_id_inscricao_atividade = (SELECT MIN(cp_id_inscricao_atividade) FROM tbl_inscricao_atividade
                                        WHERE status_inscricao_atividade = 'RESERVADA')$q$,
'ck_inscricao_atividade_reserva');

SELECT pg_temp.fn_espera_erro('RF12 item de atividade sem atividade',
$q$INSERT INTO tbl_item_financeiro (ce_inscricao, nr_item, tp_item, vl_item, status_item, dt_criacao)
   VALUES ((SELECT insc_ag1 FROM tmp_ref), 99, 'ATIVIDADE', 10, 'VALIDO', LOCALTIMESTAMP)$q$,
'ck_item_financeiro_atividade');

SELECT pg_temp.fn_espera_erro('RF12 sobretaxa em inscrição que não cobre o trabalho',
$q$INSERT INTO tbl_item_financeiro (ce_inscricao, ce_trabalho, nr_item, tp_item, vl_item, status_item, dt_criacao)
   VALUES ((SELECT insc_ag1 FROM tmp_ref), (SELECT MIN(cp_id_trabalho) FROM tbl_trabalho), 99,
           'TAXA_PUBLICACAO', 10, 'VALIDO', LOCALTIMESTAMP)$q$, 'fn_item_origem');

SELECT pg_temp.fn_espera_erro('RF27 valor de item congelado',
$q$UPDATE tbl_item_financeiro SET vl_item = vl_item + 1
    WHERE cp_id_item_financeiro = (SELECT MIN(cp_id_item_financeiro) FROM tbl_item_financeiro)$q$,
'fn_item_financeiro_update');

SELECT pg_temp.fn_espera_erro('RF17 benefício sem vínculo com a instituição',
$q$UPDATE tbl_inscricao i
      SET ce_beneficio = (SELECT MIN(b.cp_id_beneficio) FROM tbl_beneficio b
                           WHERE b.ce_instituicao NOT IN (SELECT v.ce_instituicao FROM tbl_vinculo_institucional v
                                                           WHERE v.ce_pessoa = i.ce_pessoa)),
          dt_uso_beneficio = i.dt_inscricao
    WHERE i.cp_id_inscricao = (SELECT insc_ag1 FROM tmp_ref)$q$, 'vínculo vigente');

UPDATE tbl_beneficio
   SET nr_limite_por_edicao = 0
 WHERE cp_id_beneficio = (
       SELECT b.cp_id_beneficio
         FROM tbl_beneficio b
         JOIN tbl_vinculo_institucional v ON v.ce_instituicao = b.ce_instituicao AND v.dt_fim_vinculo IS NULL
         JOIN tbl_inscricao i ON i.ce_pessoa = v.ce_pessoa
        WHERE i.cp_id_inscricao = (SELECT insc_benef FROM tmp_ref)
          AND b.tp_beneficio = 'GRATUIDADE');

SELECT pg_temp.fn_espera_erro('RF17 limite do benefício na edição',
$q$UPDATE tbl_inscricao i
      SET ce_beneficio = (SELECT b.cp_id_beneficio FROM tbl_beneficio b
                            JOIN tbl_vinculo_institucional v ON v.ce_instituicao = b.ce_instituicao
                           WHERE v.ce_pessoa = i.ce_pessoa AND v.dt_fim_vinculo IS NULL
                             AND b.tp_beneficio = 'GRATUIDADE'),
          dt_uso_beneficio = i.dt_inscricao
    WHERE i.cp_id_inscricao = (SELECT insc_benef FROM tmp_ref)$q$, 'limite do benefício na edição');

SELECT pg_temp.fn_espera_erro('RF19 cobertura por inscrição de quem não é autor',
$q$UPDATE tbl_trabalho t
      SET ce_inscricao_cobertura = (
          SELECT MIN(d.cp_id_inscricao) FROM vw_inscricao_detalhe d
            JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = d.cp_id_categoria
           WHERE d.cp_id_edicao = t.ce_edicao AND c.ind_categoria_autor
             AND d.status_inscricao NOT IN ('CANCELADA', 'EXPIRADA')
             AND d.ce_pessoa NOT IN (SELECT a.ce_pessoa FROM tbl_autoria a WHERE a.ce_trabalho = t.cp_id_trabalho))
    WHERE t.cp_id_trabalho = (SELECT MIN(cp_id_trabalho) FROM tbl_trabalho
                               WHERE ce_inscricao_cobertura IS NULL AND ce_edicao = (SELECT edicao_2026 FROM tmp_ref))$q$,
'não é de um autor');

SELECT pg_temp.fn_espera_erro('RF19 categoria que não cobre publicação',
$q$UPDATE tbl_trabalho t
      SET ce_inscricao_cobertura = (
          SELECT MIN(d.cp_id_inscricao) FROM vw_inscricao_detalhe d
           WHERE d.cp_id_edicao = t.ce_edicao AND d.nm_categoria = 'Estudante de graduação'
             AND d.status_inscricao NOT IN ('CANCELADA', 'EXPIRADA'))
    WHERE t.cp_id_trabalho = (SELECT MIN(cp_id_trabalho) FROM tbl_trabalho
                               WHERE ce_inscricao_cobertura IS NULL AND ce_edicao = (SELECT edicao_2026 FROM tmp_ref))$q$,
'não cobre publicação');

SELECT pg_temp.fn_espera_erro('RF22 certificado duplicado',
$q$INSERT INTO tbl_certificado (ce_pessoa, ce_edicao, cd_validacao, tp_certificado, dt_emissao, status_certificado)
   SELECT ce_pessoa, ce_edicao, 'TESTE-DUPLICADO', tp_certificado, LOCALTIMESTAMP, 'VALIDO'
     FROM tbl_certificado
    WHERE cp_id_certificado = (SELECT MIN(cp_id_certificado) FROM tbl_certificado
                                WHERE tp_certificado = 'PARTICIPACAO' AND status_certificado = 'VALIDO')$q$,
'já existe certificado válido');

SELECT pg_temp.fn_espera_erro('RF22 certificado para quem não atende aos critérios',
$q$INSERT INTO tbl_certificado (ce_pessoa, ce_edicao, cd_validacao, tp_certificado, dt_emissao, status_certificado)
   VALUES ((SELECT MIN(p.cp_id_pessoa) FROM tbl_pessoa p
             WHERE NOT EXISTS (SELECT 1 FROM vw_inscricao_detalhe d
                                WHERE d.ce_pessoa = p.cp_id_pessoa AND d.cp_id_edicao = (SELECT edicao_2025 FROM tmp_ref))),
           (SELECT edicao_2025 FROM tmp_ref), 'TESTE-INAPTO', 'PARTICIPACAO', LOCALTIMESTAMP, 'VALIDO')$q$,
'não atende aos critérios');

SELECT pg_temp.fn_espera_erro('RF22 código de validação repetido',
$q$INSERT INTO tbl_certificado (ce_pessoa, ce_edicao, cd_validacao, tp_certificado, dt_emissao, status_certificado)
   SELECT a.ce_pessoa, t.ce_edicao, (SELECT MIN(cd_validacao) FROM tbl_certificado), 'AUTORIA', LOCALTIMESTAMP, 'VALIDO'
     FROM tbl_autoria a JOIN tbl_trabalho t ON t.cp_id_trabalho = a.ce_trabalho
    WHERE t.ce_edicao = (SELECT edicao_2026 FROM tmp_ref)
    ORDER BY a.ce_pessoa
    FETCH FIRST 1 ROW ONLY$q$, 'uq_certificado_validacao');

SELECT pg_temp.fn_espera_erro('RF22 certificado só admite revogação',
$q$UPDATE tbl_certificado SET cd_validacao = cd_validacao || 'X'
    WHERE cp_id_certificado = (SELECT MIN(cp_id_certificado) FROM tbl_certificado)$q$, 'fn_certificado_update');

SELECT pg_temp.fn_espera_erro('RF23 versão de termo publicada não muda',
$q$UPDATE tbl_termo SET ds_termo = 'Texto alterado'
    WHERE cp_id_termo = (SELECT MIN(cp_id_termo) FROM tbl_termo)$q$, 'fn_termo_versao');

SELECT pg_temp.fn_espera_erro('RF23 resposta a termo não é sobrescrita',
$q$UPDATE tbl_resposta_termo SET ind_aceite = NOT ind_aceite
    WHERE ce_inscricao = (SELECT MIN(ce_inscricao) FROM tbl_resposta_termo)$q$, 'fn_bloqueia_alteracao');

SELECT pg_temp.fn_espera_erro('RF24 papel de organização inválido',
$q$INSERT INTO tbl_organizacao_edicao (ce_pessoa, ce_edicao, tp_papel)
   VALUES (100, (SELECT edicao_2026 FROM tmp_ref), 'PRESIDENTE')$q$, 'ck_organizacao_edicao_papel');

SELECT pg_temp.fn_espera_erro('RF25 auditoria não é alterada',
$q$UPDATE tbl_auditoria SET nm_tabela = 'x'
    WHERE cp_id_auditoria = (SELECT MIN(cp_id_auditoria) FROM tbl_auditoria)$q$, 'fn_bloqueia_alteracao');

SELECT pg_temp.fn_espera_erro('RF27 preço já usado não muda',
$q$UPDATE tbl_preco SET vl_inscricao = vl_inscricao + 1
    WHERE cp_id_preco = (SELECT MIN(ce_preco) FROM tbl_inscricao)$q$, 'fn_preco_em_uso');

SELECT pg_temp.fn_espera_erro('RF27 política da edição congelada após abertura',
$q$UPDATE tbl_edicao_evento SET pc_reembolso = 50
    WHERE cp_id_edicao = (SELECT edicao_2026 FROM tmp_ref)$q$, 'fn_edicao_politica');

SELECT pg_temp.fn_espera_erro('RF27 inscrição não é excluída',
$q$DELETE FROM tbl_inscricao WHERE cp_id_inscricao = (SELECT insc_ag1 FROM tmp_ref)$q$, 'fn_bloqueia_exclusao');

SELECT pg_temp.fn_espera_erro('Cardinalidade (1,n) evento sem edição',
$q$INSERT INTO tbl_evento (sg_evento, nm_evento, tp_evento) VALUES ('TST', 'Evento de teste', 'OUTRO');
   SET CONSTRAINTS tg_evento_edicao_minima IMMEDIATE$q$, 'fn_evento_edicao_minima');

SELECT pg_temp.fn_espera_erro('Cardinalidade (1,n) trabalho sem autor',
$q$INSERT INTO tbl_trabalho (ce_edicao, cd_trabalho_externo, titulo_trabalho, tp_trabalho, status_trabalho)
   VALUES ((SELECT edicao_2026 FROM tmp_ref), 'SUB-TESTE', 'Trabalho sem autor', 'POSTER', 'ACEITO');
   SET CONSTRAINTS tg_trabalho_autor_minimo IMMEDIATE$q$, 'fn_trabalho_autor_minimo');

SELECT pg_temp.fn_espera_erro('RF30 relatório não lê dados pessoais',
$q$SET LOCAL ROLE papel_relatorio; SELECT COUNT(*) FROM tbl_pessoa$q$, 'permission denied');

SELECT pg_temp.fn_espera_sucesso('RF30 relatório lê as visões gerenciais',
$q$SET LOCAL ROLE papel_relatorio; SELECT COUNT(*) FROM vw_situacao_inscricoes; RESET ROLE$q$);

SELECT pg_temp.fn_espera_sucesso('RF3/RF6 nova inscrição válida',
$q$INSERT INTO tbl_inscricao (ce_pessoa, ce_preco, dt_inscricao, status_inscricao)
   SELECT 5, p.cp_id_preco, TIMESTAMP '2026-03-10 10:00:00', 'INICIADA'
     FROM tbl_preco p JOIN tbl_faixa_inscricao f ON f.cp_id_faixa = p.ce_faixa
     JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
    WHERE f.ce_edicao = (SELECT edicao_2026 FROM tmp_ref) AND f.nm_faixa = 'Primeiro lote'
      AND c.nm_categoria = 'Professor' AND p.tp_associacao = 'ASSOCIADO'$q$);

SELECT pg_temp.fn_espera_verdadeiro('RF12 itens gerados para a nova inscrição',
$q$SELECT EXISTS (SELECT 1 FROM tbl_item_financeiro it JOIN tbl_inscricao i ON i.cp_id_inscricao = it.ce_inscricao
                 WHERE i.ce_pessoa = 5 AND i.dt_inscricao = TIMESTAMP '2026-03-10 10:00:00' AND it.tp_item = 'INSCRICAO')$q$);

SELECT pg_temp.fn_espera_verdadeiro('RE2 validade do preço calculada',
$q$SELECT dt_validade_preco = TIMESTAMP '2026-03-17 10:00:00' FROM tbl_inscricao
    WHERE ce_pessoa = 5 AND dt_inscricao = TIMESTAMP '2026-03-10 10:00:00'$q$);

SELECT pg_temp.fn_espera_sucesso('RF13 pagamento do saldo',
$q$INSERT INTO tbl_pagamento (ce_inscricao, dt_criacao, tp_pagamento, vl_pagamento, status_pagamento)
   SELECT cp_id_inscricao, LOCALTIMESTAMP, 'CARTAO', vl_saldo, 'PENDENTE'
     FROM vw_saldo_inscricao WHERE cp_id_inscricao = (SELECT insc_ag1 FROM tmp_ref)$q$);

SELECT pg_temp.fn_espera_sucesso('RF13 confirmação do pagamento por usuário identificado',
$q$SET LOCAL eventos.cp_pessoa = '1';
   UPDATE tbl_pagamento SET status_pagamento = 'CONFIRMADO'
    WHERE ce_inscricao = (SELECT insc_ag1 FROM tmp_ref) AND status_pagamento = 'PENDENTE'$q$);

SELECT pg_temp.fn_espera_sucesso('RF9 inscrição quitada passa a PAGA',
$q$UPDATE tbl_inscricao SET status_inscricao = 'PAGA' WHERE cp_id_inscricao = (SELECT insc_ag1 FROM tmp_ref)$q$);

SELECT pg_temp.fn_espera_verdadeiro('RF25 auditoria registra operação e responsável',
$q$SELECT EXISTS (SELECT 1 FROM tbl_auditoria
                 WHERE nm_tabela = 'tbl_inscricao' AND tp_operacao = 'UPDATE' AND ce_pessoa_responsavel = 1
                   AND cd_registro = (SELECT insc_ag1 FROM tmp_ref))$q$);

SELECT pg_temp.fn_espera_verdadeiro('RF10 reservas confirmadas no pagamento',
$q$SELECT NOT EXISTS (SELECT 1 FROM tbl_inscricao_atividade
                     WHERE ce_inscricao = (SELECT insc_ag1 FROM tmp_ref) AND status_inscricao_atividade = 'RESERVADA')$q$);

SELECT pg_temp.fn_espera_sucesso('RE5 troca de categoria antes do pagamento',
$q$UPDATE tbl_inscricao i
      SET ce_preco = (SELECT MIN(p2.cp_id_preco) FROM tbl_preco p1
                        JOIN tbl_preco p2 ON p2.ce_faixa = p1.ce_faixa AND p2.tp_associacao = p1.tp_associacao
                                         AND p2.cp_id_preco <> p1.cp_id_preco
                        JOIN tbl_categoria_inscricao c2 ON c2.cp_id_categoria = p2.ce_categoria
                       WHERE p1.cp_id_preco = i.ce_preco AND NOT c2.ind_exige_comprovacao
                         AND p2.ce_categoria <> p1.ce_categoria)
    WHERE i.cp_id_inscricao = (SELECT insc_ag2 FROM tmp_ref)$q$);

SELECT pg_temp.fn_espera_verdadeiro('RE5 itens anteriores substituídos',
$q$SELECT EXISTS (SELECT 1 FROM tbl_item_financeiro
                 WHERE ce_inscricao = (SELECT insc_ag2 FROM tmp_ref) AND status_item = 'SUBSTITUIDO')$q$);

SELECT pg_temp.fn_espera_sucesso('RF15 cancelamento de inscrição paga',
$q$UPDATE tbl_inscricao SET status_inscricao = 'CANCELADA', dt_cancelamento = dt_confirmacao + INTERVAL '1' DAY
    WHERE cp_id_inscricao = (SELECT insc_paga_2026 FROM tmp_ref)$q$);

SELECT pg_temp.fn_espera_verdadeiro('RF15 reembolso conforme política da edição',
$q$SELECT EXISTS (SELECT 1 FROM tbl_pagamento
                 WHERE ce_inscricao = (SELECT insc_paga_2026 FROM tmp_ref) AND status_pagamento = 'ESTORNADO')$q$);

SELECT pg_temp.fn_espera_verdadeiro('RF7 COMBO pago gera período de associação',
$q$SELECT EXISTS (SELECT 1 FROM tbl_periodo_associacao WHERE ce_inscricao_origem IS NOT NULL)$q$);

SELECT pg_temp.fn_espera_verdadeiro('RF19 trabalho excedente gera sobretaxa',
$q$SELECT EXISTS (SELECT 1 FROM tbl_item_financeiro WHERE tp_item = 'TAXA_PUBLICACAO')$q$);

SELECT pg_temp.fn_espera_sucesso('RE8 anonimização de pessoa',
$q$CALL prc_anonimizar_pessoa(6000)$q$);

SELECT pg_temp.fn_espera_verdadeiro('RE8 pessoa anonimizada mantém inscrições',
$q$SELECT p.ind_anonimizada AND p.cpf_pessoa IS NULL FROM tbl_pessoa p WHERE p.cp_id_pessoa = 6000$q$);

SELECT pg_temp.fn_espera_verdadeiro('RF26 todas as visões gerenciais retornam linhas',
$q$SELECT EXISTS (SELECT 1 FROM vw_inscritos_evento_categoria_instituicao)
      AND EXISTS (SELECT 1 FROM vw_evolucao_inscricoes)
      AND EXISTS (SELECT 1 FROM vw_situacao_inscricoes)
      AND EXISTS (SELECT 1 FROM vw_receita_edicao)
      AND EXISTS (SELECT 1 FROM vw_receita_categoria_forma)
      AND EXISTS (SELECT 1 FROM vw_uso_beneficio)
      AND EXISTS (SELECT 1 FROM vw_inscritos_atividade_limitada)
      AND EXISTS (SELECT 1 FROM vw_trabalho_sem_cobertura)
      AND EXISTS (SELECT 1 FROM vw_aptidao_certificado)
      AND EXISTS (SELECT 1 FROM vw_credenciados_dia_atividade)
      AND EXISTS (SELECT 1 FROM vw_distribuicao_participantes)
      AND EXISTS (SELECT 1 FROM vw_documentos_pendentes)$q$);

SELECT pg_temp.fn_espera_sucesso('RE2 rotina de expiração',
$q$CALL prc_expirar_pendencias()$q$);

SELECT nr_caso, CASE WHEN ind_ok THEN 'OK' ELSE 'FALHA' END AS resultado, ds_caso, ds_obtido
  FROM tmp_resultado
 ORDER BY nr_caso;

SELECT COUNT(*) AS nr_casos,
       SUM(CASE WHEN ind_ok THEN 1 ELSE 0 END) AS nr_ok,
       SUM(CASE WHEN ind_ok THEN 0 ELSE 1 END) AS nr_falha
  FROM tmp_resultado;

ROLLBACK;
