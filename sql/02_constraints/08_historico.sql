SET SCHEMA 'eventos';

CREATE FUNCTION fn_bloqueia_exclusao() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'fn_bloqueia_exclusao: registros de % não podem ser excluídos', TG_TABLE_NAME;
END;
$$;

CREATE TRIGGER tg_inscricao_exclusao BEFORE DELETE ON tbl_inscricao
FOR EACH ROW EXECUTE FUNCTION fn_bloqueia_exclusao();
CREATE TRIGGER tg_item_financeiro_exclusao BEFORE DELETE ON tbl_item_financeiro
FOR EACH ROW EXECUTE FUNCTION fn_bloqueia_exclusao();
CREATE TRIGGER tg_pagamento_exclusao BEFORE DELETE ON tbl_pagamento
FOR EACH ROW EXECUTE FUNCTION fn_bloqueia_exclusao();
CREATE TRIGGER tg_documento_exclusao BEFORE DELETE ON tbl_documento_comprovacao
FOR EACH ROW EXECUTE FUNCTION fn_bloqueia_exclusao();
CREATE TRIGGER tg_certificado_exclusao BEFORE DELETE ON tbl_certificado
FOR EACH ROW EXECUTE FUNCTION fn_bloqueia_exclusao();
CREATE TRIGGER tg_termo_exclusao BEFORE DELETE ON tbl_termo
FOR EACH ROW EXECUTE FUNCTION fn_bloqueia_exclusao();
CREATE TRIGGER tg_resposta_termo_exclusao BEFORE DELETE ON tbl_resposta_termo
FOR EACH ROW EXECUTE FUNCTION fn_bloqueia_exclusao();
CREATE TRIGGER tg_auditoria_exclusao BEFORE DELETE ON tbl_auditoria
FOR EACH ROW EXECUTE FUNCTION fn_bloqueia_exclusao();

CREATE FUNCTION fn_bloqueia_alteracao() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'fn_bloqueia_alteracao: registros de % não podem ser alterados', TG_TABLE_NAME;
END;
$$;

CREATE TRIGGER tg_resposta_termo_alteracao BEFORE UPDATE ON tbl_resposta_termo
FOR EACH ROW EXECUTE FUNCTION fn_bloqueia_alteracao();
CREATE TRIGGER tg_auditoria_alteracao BEFORE UPDATE ON tbl_auditoria
FOR EACH ROW EXECUTE FUNCTION fn_bloqueia_alteracao();

CREATE FUNCTION fn_termo_versao() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.nm_termo <> OLD.nm_termo
       OR NEW.nr_versao <> OLD.nr_versao
       OR NEW.ds_termo <> OLD.ds_termo
       OR NEW.dt_inicio_vigencia <> OLD.dt_inicio_vigencia
       OR (OLD.dt_fim_vigencia IS NOT NULL AND NEW.dt_fim_vigencia IS DISTINCT FROM OLD.dt_fim_vigencia) THEN
        RAISE EXCEPTION 'fn_termo_versao: versão publicada só admite o encerramento da vigência';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_termo_versao BEFORE UPDATE ON tbl_termo
FOR EACH ROW EXECUTE FUNCTION fn_termo_versao();

CREATE FUNCTION fn_preco_em_uso() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tbl_inscricao WHERE ce_preco = OLD.cp_id_preco) THEN
        RAISE EXCEPTION 'fn_preco_em_uso: preço % já usado por inscrição; crie um novo preço', OLD.cp_id_preco;
    END IF;
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_preco_em_uso BEFORE UPDATE OR DELETE ON tbl_preco
FOR EACH ROW EXECUTE FUNCTION fn_preco_em_uso();

CREATE FUNCTION fn_edicao_politica() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.dt_inicio_inscricao <= LOCALTIMESTAMP AND (
           NEW.nr_dias_reserva IS DISTINCT FROM OLD.nr_dias_reserva
        OR NEW.nr_dias_limite_reembolso IS DISTINCT FROM OLD.nr_dias_limite_reembolso
        OR NEW.pc_reembolso IS DISTINCT FROM OLD.pc_reembolso
        OR NEW.ind_exige_credenciamento IS DISTINCT FROM OLD.ind_exige_credenciamento
        OR NEW.pc_frequencia_minima IS DISTINCT FROM OLD.pc_frequencia_minima
        OR NEW.nr_max_trabalhos_inscricao IS DISTINCT FROM OLD.nr_max_trabalhos_inscricao
        OR NEW.vl_taxa_trabalho_extra IS DISTINCT FROM OLD.vl_taxa_trabalho_extra
    ) THEN
        RAISE EXCEPTION 'fn_edicao_politica: políticas da edição não mudam após a abertura das inscrições';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_edicao_politica BEFORE UPDATE ON tbl_edicao_evento
FOR EACH ROW EXECUTE FUNCTION fn_edicao_politica();

CREATE FUNCTION fn_item_financeiro_update() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.ce_inscricao <> OLD.ce_inscricao
       OR NEW.ce_inscricao_atividade IS DISTINCT FROM OLD.ce_inscricao_atividade
       OR NEW.ce_trabalho IS DISTINCT FROM OLD.ce_trabalho
       OR NEW.nr_item <> OLD.nr_item
       OR NEW.tp_item <> OLD.tp_item
       OR NEW.vl_item <> OLD.vl_item
       OR NEW.dt_criacao <> OLD.dt_criacao
       OR NOT (OLD.status_item = 'VALIDO' AND NEW.status_item IN ('SUBSTITUIDO', 'CANCELADO')) THEN
        RAISE EXCEPTION 'fn_item_financeiro_update: item congelado só admite substituição ou cancelamento';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_item_financeiro_update BEFORE UPDATE ON tbl_item_financeiro
FOR EACH ROW EXECUTE FUNCTION fn_item_financeiro_update();
