SET SCHEMA 'eventos';

CREATE FUNCTION fn_saldo_inscricao(p_inscricao bigint) RETURNS numeric
LANGUAGE plpgsql STABLE SET search_path = eventos AS $$
DECLARE
    v_devido numeric(12,2);
    v_pago   numeric(12,2);
BEGIN
    SELECT COALESCE(SUM(CASE WHEN tp_item = 'DESCONTO' THEN -vl_item ELSE vl_item END), 0)
      INTO v_devido
      FROM tbl_item_financeiro
     WHERE ce_inscricao = p_inscricao AND status_item = 'VALIDO';
    SELECT COALESCE(SUM(vl_pagamento), 0)
      INTO v_pago
      FROM tbl_pagamento
     WHERE ce_inscricao = p_inscricao AND status_pagamento = 'CONFIRMADO';
    RETURN v_devido - v_pago;
END;
$$;

CREATE FUNCTION fn_validar_preco_inscricao(p_pessoa bigint, p_preco bigint, p_data timestamp) RETURNS void
LANGUAGE plpgsql STABLE SET search_path = eventos AS $$
DECLARE
    v_tp       varchar(20);
    v_dia      date := CAST(p_data AS date);
    v_vigente  boolean;
    v_anterior boolean;
BEGIN
    SELECT p.tp_associacao INTO v_tp
      FROM tbl_preco p
      JOIN tbl_faixa_inscricao f ON f.cp_id_faixa = p.ce_faixa
     WHERE p.cp_id_preco = p_preco
       AND f.dt_inicio_faixa <= p_data
       AND p_data < f.dt_fim_faixa;
    IF v_tp IS NULL THEN
        RAISE EXCEPTION 'fn_validar_preco_inscricao: a faixa do preço não está vigente na data da inscrição';
    END IF;
    v_vigente := EXISTS (
        SELECT 1 FROM tbl_periodo_associacao
         WHERE ce_pessoa = p_pessoa
           AND dt_inicio_associacao <= v_dia
           AND dt_fim_associacao >= v_dia
    );
    v_anterior := EXISTS (
        SELECT 1 FROM tbl_periodo_associacao
         WHERE ce_pessoa = p_pessoa
           AND dt_fim_associacao < v_dia
    );
    IF (v_tp = 'ASSOCIADO' AND NOT v_vigente)
       OR (v_tp IN ('NAO_ASSOCIADO', 'COMBO_NOVA', 'COMBO_RENOVACAO') AND v_vigente)
       OR (v_tp = 'COMBO_NOVA' AND v_anterior)
       OR (v_tp = 'COMBO_RENOVACAO' AND NOT v_anterior) THEN
        RAISE EXCEPTION 'fn_validar_preco_inscricao: % incompatível com a situação de associação da pessoa em %', v_tp, v_dia;
    END IF;
END;
$$;

CREATE FUNCTION fn_gerar_itens_inscricao(p_inscricao bigint, p_data timestamp) RETURNS void
LANGUAGE plpgsql SET search_path = eventos AS $$
DECLARE
    v_nr        smallint;
    v_insc      numeric(10,2);
    v_assoc     numeric(10,2);
    v_beneficio bigint;
    v_tp_benef  varchar(20);
    v_pc        numeric(5,2);
BEGIN
    SELECT p.vl_inscricao, p.vl_associacao, i.ce_beneficio
      INTO v_insc, v_assoc, v_beneficio
      FROM tbl_inscricao i
      JOIN tbl_preco p ON p.cp_id_preco = i.ce_preco
     WHERE i.cp_id_inscricao = p_inscricao;
    SELECT COALESCE(MAX(nr_item), 0) INTO v_nr FROM tbl_item_financeiro WHERE ce_inscricao = p_inscricao;

    v_nr := v_nr + 1;
    INSERT INTO tbl_item_financeiro (ce_inscricao, nr_item, tp_item, vl_item, status_item, dt_criacao)
    VALUES (p_inscricao, v_nr, 'INSCRICAO', v_insc, 'VALIDO', p_data);

    IF v_assoc IS NOT NULL THEN
        v_nr := v_nr + 1;
        INSERT INTO tbl_item_financeiro (ce_inscricao, nr_item, tp_item, vl_item, status_item, dt_criacao)
        VALUES (p_inscricao, v_nr, 'ASSOCIACAO', v_assoc, 'VALIDO', p_data);
    END IF;

    IF v_beneficio IS NOT NULL THEN
        SELECT tp_beneficio, pc_desconto INTO v_tp_benef, v_pc FROM tbl_beneficio WHERE cp_id_beneficio = v_beneficio;
        v_nr := v_nr + 1;
        INSERT INTO tbl_item_financeiro (ce_inscricao, nr_item, tp_item, vl_item, status_item, dt_criacao)
        VALUES (
            p_inscricao, v_nr, 'DESCONTO',
            CASE WHEN v_tp_benef = 'GRATUIDADE' THEN v_insc ELSE ROUND(v_insc * v_pc / 100, 2) END,
            'VALIDO', p_data
        );
    END IF;
END;
$$;

CREATE FUNCTION fn_inscricao_insert() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_dias smallint;
BEGIN
    IF NEW.status_inscricao <> 'INICIADA' THEN
        RAISE EXCEPTION 'fn_inscricao_insert: toda inscrição começa como INICIADA';
    END IF;
    PERFORM fn_validar_preco_inscricao(NEW.ce_pessoa, NEW.ce_preco, NEW.dt_inscricao);
    SELECT nr_dias_reserva INTO v_dias
      FROM tbl_edicao_evento
     WHERE cp_id_edicao = fn_edicao_do_preco(NEW.ce_preco);
    NEW.dt_validade_preco := NEW.dt_inscricao + v_dias * INTERVAL '1' DAY;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_inscricao_insert
BEFORE INSERT ON tbl_inscricao
FOR EACH ROW EXECUTE FUNCTION fn_inscricao_insert();

CREATE FUNCTION fn_inscricao_itens() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    PERFORM fn_gerar_itens_inscricao(NEW.cp_id_inscricao, NEW.dt_inscricao);
    RETURN NULL;
END;
$$;

CREATE TRIGGER tg_inscricao_itens
AFTER INSERT ON tbl_inscricao
FOR EACH ROW EXECUTE FUNCTION fn_inscricao_itens();

CREATE FUNCTION fn_inscricao_beneficio() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_b      tbl_beneficio%ROWTYPE;
    v_dia    date;
    v_edicao bigint;
BEGIN
    IF NEW.ce_beneficio IS NULL THEN
        RETURN NEW;
    END IF;
    IF TG_OP = 'UPDATE'
       AND NEW.ce_beneficio IS NOT DISTINCT FROM OLD.ce_beneficio
       AND NEW.dt_uso_beneficio IS NOT DISTINCT FROM OLD.dt_uso_beneficio THEN
        RETURN NEW;
    END IF;

    SELECT * INTO v_b FROM tbl_beneficio WHERE cp_id_beneficio = NEW.ce_beneficio FOR UPDATE;
    v_dia := CAST(NEW.dt_uso_beneficio AS date);
    v_edicao := fn_edicao_do_preco(NEW.ce_preco);

    IF v_dia < v_b.dt_inicio_vigencia OR v_dia > v_b.dt_fim_vigencia THEN
        RAISE EXCEPTION 'fn_inscricao_beneficio: benefício fora da vigência';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM tbl_instituicao WHERE cp_id_instituicao = v_b.ce_instituicao AND ind_associada
    ) THEN
        RAISE EXCEPTION 'fn_inscricao_beneficio: a instituição do benefício não é associada';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM tbl_vinculo_institucional
         WHERE ce_pessoa = NEW.ce_pessoa
           AND ce_instituicao = v_b.ce_instituicao
           AND dt_inicio_vinculo <= v_dia
           AND (dt_fim_vinculo IS NULL OR dt_fim_vinculo >= v_dia)
    ) THEN
        RAISE EXCEPTION 'fn_inscricao_beneficio: a pessoa não tem vínculo vigente com a instituição';
    END IF;
    IF EXISTS (
        SELECT 1 FROM tbl_inscricao i
          JOIN tbl_preco p ON p.cp_id_preco = i.ce_preco
          JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
         WHERE i.ce_beneficio = NEW.ce_beneficio
           AND i.ce_pessoa = NEW.ce_pessoa
           AND c.ce_edicao = v_edicao
           AND i.cp_id_inscricao <> NEW.cp_id_inscricao
           AND i.status_inscricao NOT IN ('CANCELADA', 'EXPIRADA')
    ) THEN
        RAISE EXCEPTION 'fn_inscricao_beneficio: benefício já utilizado pela pessoa nesta edição';
    END IF;
    IF (SELECT COUNT(*) FROM tbl_inscricao
         WHERE ce_beneficio = NEW.ce_beneficio
           AND cp_id_inscricao <> NEW.cp_id_inscricao
           AND status_inscricao NOT IN ('CANCELADA', 'EXPIRADA')) >= v_b.nr_limite_periodo THEN
        RAISE EXCEPTION 'fn_inscricao_beneficio: limite do benefício no período atingido';
    END IF;
    IF (SELECT COUNT(*) FROM tbl_inscricao i
          JOIN tbl_preco p ON p.cp_id_preco = i.ce_preco
          JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
         WHERE i.ce_beneficio = NEW.ce_beneficio
           AND c.ce_edicao = v_edicao
           AND i.cp_id_inscricao <> NEW.cp_id_inscricao
           AND i.status_inscricao NOT IN ('CANCELADA', 'EXPIRADA')) >= v_b.nr_limite_por_edicao THEN
        RAISE EXCEPTION 'fn_inscricao_beneficio: limite do benefício na edição atingido';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_inscricao_beneficio
BEFORE INSERT OR UPDATE OF ce_beneficio, dt_uso_beneficio ON tbl_inscricao
FOR EACH ROW EXECUTE FUNCTION fn_inscricao_beneficio();

CREATE FUNCTION fn_inscricao_update() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_edicao tbl_edicao_evento%ROWTYPE;
    v_exige  boolean;
BEGIN
    IF OLD.status_inscricao IN ('CANCELADA', 'EXPIRADA', 'CONCLUIDA') THEN
        RAISE EXCEPTION 'fn_inscricao_update: inscrição % finalizada não pode ser alterada', OLD.cp_id_inscricao;
    END IF;
    IF NEW.ce_pessoa <> OLD.ce_pessoa
       OR NEW.dt_inscricao <> OLD.dt_inscricao
       OR NEW.dt_validade_preco <> OLD.dt_validade_preco THEN
        RAISE EXCEPTION 'fn_inscricao_update: pessoa, data da inscrição e validade do preço são imutáveis';
    END IF;

    IF NEW.ce_preco <> OLD.ce_preco OR NEW.ce_beneficio IS DISTINCT FROM OLD.ce_beneficio THEN
        IF OLD.status_inscricao NOT IN ('INICIADA', 'AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO') THEN
            RAISE EXCEPTION 'fn_inscricao_update: preço e benefício só mudam antes do pagamento';
        END IF;
        IF NEW.ce_preco <> OLD.ce_preco THEN
            IF fn_edicao_do_preco(NEW.ce_preco) <> fn_edicao_do_preco(OLD.ce_preco) THEN
                RAISE EXCEPTION 'fn_inscricao_update: o novo preço pertence a outra edição';
            END IF;
            PERFORM fn_validar_preco_inscricao(NEW.ce_pessoa, NEW.ce_preco, NEW.dt_inscricao);
        END IF;
    END IF;

    SELECT * INTO v_edicao FROM tbl_edicao_evento WHERE cp_id_edicao = fn_edicao_do_preco(NEW.ce_preco);
    SELECT c.ind_exige_comprovacao INTO v_exige
      FROM tbl_preco p
      JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
     WHERE p.cp_id_preco = NEW.ce_preco;

    IF NEW.status_inscricao <> OLD.status_inscricao THEN
        IF NOT (
               (OLD.status_inscricao = 'INICIADA'
                    AND NEW.status_inscricao IN ('AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO', 'CANCELADA', 'EXPIRADA'))
            OR (OLD.status_inscricao = 'AGUARDANDO_VALIDACAO'
                    AND NEW.status_inscricao IN ('AGUARDANDO_PAGAMENTO', 'CANCELADA', 'EXPIRADA'))
            OR (OLD.status_inscricao = 'AGUARDANDO_PAGAMENTO'
                    AND NEW.status_inscricao IN ('PAGA', 'CANCELADA', 'EXPIRADA'))
            OR (OLD.status_inscricao = 'PAGA'
                    AND NEW.status_inscricao IN ('CONCLUIDA', 'CANCELADA'))
        ) THEN
            RAISE EXCEPTION 'fn_inscricao_update: transição % -> % não permitida',
                OLD.status_inscricao, NEW.status_inscricao;
        END IF;

        IF NEW.status_inscricao = 'AGUARDANDO_VALIDACAO' AND NOT v_exige THEN
            RAISE EXCEPTION 'fn_inscricao_update: a categoria não exige comprovação';
        ELSIF NEW.status_inscricao = 'PAGA' THEN
            IF fn_saldo_inscricao(NEW.cp_id_inscricao) > 0 THEN
                RAISE EXCEPTION 'fn_inscricao_update: pagamentos confirmados não quitam a inscrição';
            END IF;
            NEW.dt_confirmacao := COALESCE(NEW.dt_confirmacao, LOCALTIMESTAMP);
        ELSIF NEW.status_inscricao = 'CANCELADA' THEN
            NEW.dt_cancelamento := COALESCE(NEW.dt_cancelamento, LOCALTIMESTAMP);
        ELSIF NEW.status_inscricao = 'EXPIRADA' AND NEW.dt_validade_preco >= LOCALTIMESTAMP THEN
            RAISE EXCEPTION 'fn_inscricao_update: o prazo de reserva ainda não terminou';
        ELSIF NEW.status_inscricao = 'CONCLUIDA' AND v_edicao.dt_fim_evento >= CURRENT_DATE THEN
            RAISE EXCEPTION 'fn_inscricao_update: a edição ainda não terminou';
        END IF;
    END IF;

    IF NEW.status_inscricao = 'AGUARDANDO_PAGAMENTO'
       AND (NEW.status_inscricao <> OLD.status_inscricao OR NEW.ce_preco <> OLD.ce_preco)
       AND v_exige
       AND NOT EXISTS (
           SELECT 1 FROM tbl_documento_comprovacao
            WHERE ce_inscricao = NEW.cp_id_inscricao AND status_documento = 'APROVADO'
       ) THEN
        RAISE EXCEPTION 'fn_inscricao_update: a categoria exige documento aprovado antes do pagamento';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_inscricao_update
BEFORE UPDATE ON tbl_inscricao
FOR EACH ROW EXECUTE FUNCTION fn_inscricao_update();

CREATE FUNCTION fn_inscricao_pos_update() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_edicao tbl_edicao_evento%ROWTYPE;
    v_tp     varchar(20);
BEGIN
    IF NEW.ce_preco <> OLD.ce_preco OR NEW.ce_beneficio IS DISTINCT FROM OLD.ce_beneficio THEN
        UPDATE tbl_item_financeiro
           SET status_item = 'SUBSTITUIDO'
         WHERE ce_inscricao = NEW.cp_id_inscricao
           AND status_item = 'VALIDO'
           AND tp_item IN ('INSCRICAO', 'ASSOCIACAO', 'DESCONTO');
        PERFORM fn_gerar_itens_inscricao(NEW.cp_id_inscricao, LOCALTIMESTAMP);
    END IF;

    IF NEW.status_inscricao = OLD.status_inscricao THEN
        RETURN NULL;
    END IF;

    IF NEW.status_inscricao = 'PAGA' THEN
        UPDATE tbl_inscricao_atividade
           SET status_inscricao_atividade = 'CONFIRMADA'
         WHERE ce_inscricao = NEW.cp_id_inscricao
           AND status_inscricao_atividade = 'RESERVADA';
        SELECT tp_associacao INTO v_tp FROM tbl_preco WHERE cp_id_preco = NEW.ce_preco;
        IF v_tp IN ('COMBO_NOVA', 'COMBO_RENOVACAO') THEN
            INSERT INTO tbl_periodo_associacao (ce_pessoa, ce_inscricao_origem, dt_inicio_associacao, dt_fim_associacao)
            VALUES (
                NEW.ce_pessoa,
                NEW.cp_id_inscricao,
                CAST(NEW.dt_confirmacao AS date),
                CAST(NEW.dt_confirmacao + INTERVAL '1' YEAR - INTERVAL '1' DAY AS date)
            );
        END IF;

    ELSIF NEW.status_inscricao IN ('CANCELADA', 'EXPIRADA') THEN
        UPDATE tbl_inscricao_atividade
           SET status_inscricao_atividade = NEW.status_inscricao,
               dt_cancelamento = CASE WHEN NEW.status_inscricao = 'CANCELADA' THEN NEW.dt_cancelamento END
         WHERE ce_inscricao = NEW.cp_id_inscricao
           AND status_inscricao_atividade IN ('RESERVADA', 'CONFIRMADA');
        UPDATE tbl_item_financeiro
           SET status_item = 'CANCELADO'
         WHERE ce_inscricao = NEW.cp_id_inscricao
           AND status_item = 'VALIDO';
        UPDATE tbl_trabalho
           SET ce_inscricao_cobertura = NULL
         WHERE ce_inscricao_cobertura = NEW.cp_id_inscricao;
        UPDATE tbl_pagamento
           SET status_pagamento = CASE WHEN NEW.status_inscricao = 'CANCELADA' THEN 'CANCELADO' ELSE 'EXPIRADO' END
         WHERE ce_inscricao = NEW.cp_id_inscricao
           AND status_pagamento = 'PENDENTE';

        IF NEW.status_inscricao = 'CANCELADA' THEN
            SELECT * INTO v_edicao FROM tbl_edicao_evento WHERE cp_id_edicao = fn_edicao_do_preco(NEW.ce_preco);
            IF v_edicao.pc_reembolso > 0
               AND NEW.dt_cancelamento <= v_edicao.dt_inicio_evento - v_edicao.nr_dias_limite_reembolso * INTERVAL '1' DAY THEN
                UPDATE tbl_pagamento
                   SET status_pagamento = 'ESTORNADO',
                       vl_reembolso = ROUND(vl_pagamento * v_edicao.pc_reembolso / 100, 2),
                       dt_reembolso = NEW.dt_cancelamento
                 WHERE ce_inscricao = NEW.cp_id_inscricao
                   AND status_pagamento = 'CONFIRMADO';
            END IF;
        END IF;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER tg_inscricao_pos_update
AFTER UPDATE ON tbl_inscricao
FOR EACH ROW EXECUTE FUNCTION fn_inscricao_pos_update();
