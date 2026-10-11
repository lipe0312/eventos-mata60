SET SCHEMA 'eventos';

CREATE FUNCTION fn_pagamento_insert() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF NEW.status_pagamento <> 'PENDENTE' THEN
        RAISE EXCEPTION 'fn_pagamento_insert: todo pagamento começa como PENDENTE';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM tbl_inscricao
         WHERE cp_id_inscricao = NEW.ce_inscricao
           AND status_inscricao = 'AGUARDANDO_PAGAMENTO'
    ) THEN
        RAISE EXCEPTION 'fn_pagamento_insert: a inscrição não está aguardando pagamento';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_pagamento_insert
BEFORE INSERT ON tbl_pagamento
FOR EACH ROW EXECUTE FUNCTION fn_pagamento_insert();

CREATE FUNCTION fn_pagamento_update() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF NEW.ce_inscricao <> OLD.ce_inscricao
       OR NEW.dt_criacao <> OLD.dt_criacao
       OR NEW.tp_pagamento <> OLD.tp_pagamento
       OR NEW.vl_pagamento <> OLD.vl_pagamento THEN
        RAISE EXCEPTION 'fn_pagamento_update: inscrição, data, forma e valor do pagamento são imutáveis';
    END IF;
    IF NEW.status_pagamento <> OLD.status_pagamento THEN
        IF NOT (
               (OLD.status_pagamento = 'PENDENTE'
                    AND NEW.status_pagamento IN ('CONFIRMADO', 'RECUSADO', 'CANCELADO', 'EXPIRADO'))
            OR (OLD.status_pagamento = 'CONFIRMADO' AND NEW.status_pagamento = 'ESTORNADO')
        ) THEN
            RAISE EXCEPTION 'fn_pagamento_update: transição % -> % não permitida',
                OLD.status_pagamento, NEW.status_pagamento;
        END IF;
        IF NEW.status_pagamento = 'CONFIRMADO' THEN
            NEW.dt_confirmacao := COALESCE(NEW.dt_confirmacao, LOCALTIMESTAMP);
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_pagamento_update
BEFORE UPDATE ON tbl_pagamento
FOR EACH ROW EXECUTE FUNCTION fn_pagamento_update();

CREATE FUNCTION fn_documento_insert() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF NEW.status_documento <> 'PENDENTE' THEN
        RAISE EXCEPTION 'fn_documento_insert: todo documento começa como PENDENTE';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM tbl_inscricao
         WHERE cp_id_inscricao = NEW.ce_inscricao
           AND status_inscricao IN ('INICIADA', 'AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO')
    ) THEN
        RAISE EXCEPTION 'fn_documento_insert: a inscrição não aceita novos documentos';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_documento_insert
BEFORE INSERT ON tbl_documento_comprovacao
FOR EACH ROW EXECUTE FUNCTION fn_documento_insert();

CREATE FUNCTION fn_documento_update() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF NEW.ce_inscricao <> OLD.ce_inscricao
       OR NEW.dt_envio <> OLD.dt_envio
       OR NEW.tp_documento <> OLD.tp_documento
       OR NEW.ds_caminho_arquivo <> OLD.ds_caminho_arquivo THEN
        RAISE EXCEPTION 'fn_documento_update: inscrição, envio, tipo e arquivo do documento são imutáveis';
    END IF;
    IF OLD.status_documento <> 'PENDENTE' THEN
        RAISE EXCEPTION 'fn_documento_update: documento já analisado não pode ser alterado';
    END IF;
    IF NEW.status_documento <> 'PENDENTE' THEN
        NEW.dt_analise := COALESCE(NEW.dt_analise, LOCALTIMESTAMP);
        IF NEW.dt_analise < NEW.dt_envio THEN
            RAISE EXCEPTION 'fn_documento_update: a análise não pode ser anterior ao envio';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_documento_update
BEFORE UPDATE ON tbl_documento_comprovacao
FOR EACH ROW EXECUTE FUNCTION fn_documento_update();
