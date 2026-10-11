SET SCHEMA 'eventos';

CREATE FUNCTION fn_inscricao_atividade_insert() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_insc       tbl_inscricao%ROWTYPE;
    v_ativ       tbl_atividade%ROWTYPE;
    v_edicao     bigint;
    v_categoria  bigint;
    v_ocupacao   bigint;
BEGIN
    SELECT * INTO v_insc FROM tbl_inscricao WHERE cp_id_inscricao = NEW.ce_inscricao;
    SELECT * INTO v_ativ FROM tbl_atividade WHERE cp_id_atividade = NEW.ce_atividade FOR UPDATE;
    v_edicao := fn_edicao_do_preco(v_insc.ce_preco);
    SELECT ce_categoria INTO v_categoria FROM tbl_preco WHERE cp_id_preco = v_insc.ce_preco;

    IF v_ativ.ce_edicao <> v_edicao AND NOT EXISTS (
        SELECT 1 FROM tbl_edicao_evento
         WHERE cp_id_edicao = v_ativ.ce_edicao
           AND ce_edicao_agregadora = v_edicao
    ) THEN
        RAISE EXCEPTION 'fn_inscricao_atividade_insert: a atividade não pertence à edição da inscrição';
    END IF;
    IF EXISTS (SELECT 1 FROM tbl_restricao_atividade WHERE ce_atividade = NEW.ce_atividade)
       AND NOT EXISTS (
           SELECT 1 FROM tbl_restricao_atividade
            WHERE ce_atividade = NEW.ce_atividade AND ce_categoria = v_categoria
       ) THEN
        RAISE EXCEPTION 'fn_inscricao_atividade_insert: a categoria da inscrição não pode selecionar esta atividade';
    END IF;

    IF NEW.status_inscricao_atividade = 'RESERVADA' THEN
        IF v_insc.status_inscricao NOT IN ('INICIADA', 'AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO') THEN
            RAISE EXCEPTION 'fn_inscricao_atividade_insert: reserva exige inscrição ainda não paga';
        END IF;
        NEW.dt_expira_reserva := COALESCE(NEW.dt_expira_reserva, v_insc.dt_validade_preco);
    ELSIF NEW.status_inscricao_atividade = 'CONFIRMADA' THEN
        IF v_insc.status_inscricao <> 'PAGA' OR COALESCE(v_ativ.vl_atividade, 0) > 0 THEN
            RAISE EXCEPTION 'fn_inscricao_atividade_insert: só atividade gratuita é confirmada direto, em inscrição paga';
        END IF;
    ELSE
        RAISE EXCEPTION 'fn_inscricao_atividade_insert: toda inscrição em atividade começa RESERVADA ou CONFIRMADA';
    END IF;

    IF v_ativ.nr_capacidade IS NOT NULL THEN
        SELECT COUNT(*) INTO v_ocupacao
          FROM tbl_inscricao_atividade
         WHERE ce_atividade = NEW.ce_atividade
           AND status_inscricao_atividade IN ('RESERVADA', 'CONFIRMADA');
        IF v_ocupacao >= v_ativ.nr_capacidade THEN
            RAISE EXCEPTION 'fn_inscricao_atividade_insert: atividade % sem vagas', NEW.ce_atividade;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_inscricao_atividade_insert
BEFORE INSERT ON tbl_inscricao_atividade
FOR EACH ROW EXECUTE FUNCTION fn_inscricao_atividade_insert();

CREATE FUNCTION fn_inscricao_atividade_tarifa() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_valor numeric(10,2);
    v_nr    smallint;
BEGIN
    SELECT vl_atividade INTO v_valor FROM tbl_atividade WHERE cp_id_atividade = NEW.ce_atividade;
    IF COALESCE(v_valor, 0) > 0 THEN
        SELECT COALESCE(MAX(nr_item), 0) + 1 INTO v_nr
          FROM tbl_item_financeiro WHERE ce_inscricao = NEW.ce_inscricao;
        INSERT INTO tbl_item_financeiro
            (ce_inscricao, ce_inscricao_atividade, nr_item, tp_item, vl_item, status_item, dt_criacao)
        VALUES
            (NEW.ce_inscricao, NEW.cp_id_inscricao_atividade, v_nr, 'ATIVIDADE', v_valor, 'VALIDO', NEW.dt_inclusao);
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER tg_inscricao_atividade_tarifa
AFTER INSERT ON tbl_inscricao_atividade
FOR EACH ROW EXECUTE FUNCTION fn_inscricao_atividade_tarifa();

CREATE FUNCTION fn_inscricao_atividade_update() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF NEW.ce_inscricao <> OLD.ce_inscricao
       OR NEW.ce_atividade <> OLD.ce_atividade
       OR NEW.dt_inclusao <> OLD.dt_inclusao THEN
        RAISE EXCEPTION 'fn_inscricao_atividade_update: inscrição, atividade e data de inclusão são imutáveis';
    END IF;
    IF NEW.status_inscricao_atividade <> OLD.status_inscricao_atividade THEN
        IF NOT (
               (OLD.status_inscricao_atividade = 'RESERVADA'
                    AND NEW.status_inscricao_atividade IN ('CONFIRMADA', 'CANCELADA', 'EXPIRADA'))
            OR (OLD.status_inscricao_atividade = 'CONFIRMADA' AND NEW.status_inscricao_atividade = 'CANCELADA')
        ) THEN
            RAISE EXCEPTION 'fn_inscricao_atividade_update: transição % -> % não permitida',
                OLD.status_inscricao_atividade, NEW.status_inscricao_atividade;
        END IF;
        IF NEW.status_inscricao_atividade = 'CANCELADA' THEN
            NEW.dt_cancelamento := COALESCE(NEW.dt_cancelamento, LOCALTIMESTAMP);
        END IF;
    ELSIF OLD.status_inscricao_atividade IN ('CANCELADA', 'EXPIRADA') THEN
        RAISE EXCEPTION 'fn_inscricao_atividade_update: inscrição em atividade finalizada não pode ser alterada';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_inscricao_atividade_update
BEFORE UPDATE ON tbl_inscricao_atividade
FOR EACH ROW EXECUTE FUNCTION fn_inscricao_atividade_update();

CREATE FUNCTION fn_inscricao_atividade_cancela_item() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF NEW.status_inscricao_atividade IN ('CANCELADA', 'EXPIRADA')
       AND OLD.status_inscricao_atividade NOT IN ('CANCELADA', 'EXPIRADA') THEN
        UPDATE tbl_item_financeiro
           SET status_item = 'CANCELADO'
         WHERE ce_inscricao_atividade = NEW.cp_id_inscricao_atividade
           AND status_item = 'VALIDO';
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER tg_inscricao_atividade_cancela_item
AFTER UPDATE OF status_inscricao_atividade ON tbl_inscricao_atividade
FOR EACH ROW EXECUTE FUNCTION fn_inscricao_atividade_cancela_item();
