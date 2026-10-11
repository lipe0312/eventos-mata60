SET SCHEMA 'eventos';

CREATE FUNCTION fn_auditoria() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_linha     record;
    v_registro  bigint;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_linha := OLD;
    ELSE
        v_linha := NEW;
    END IF;

    IF TG_TABLE_NAME = 'tbl_inscricao' THEN
        v_registro := v_linha.cp_id_inscricao;
    ELSIF TG_TABLE_NAME = 'tbl_documento_comprovacao' THEN
        v_registro := v_linha.cp_id_documento;
    ELSIF TG_TABLE_NAME = 'tbl_pagamento' THEN
        v_registro := v_linha.cp_id_pagamento;
    ELSE
        v_registro := v_linha.cp_id_certificado;
    END IF;

    INSERT INTO tbl_auditoria
        (ce_pessoa_responsavel, nm_tabela, cd_registro, tp_operacao, dt_operacao, ds_valor_anterior, ds_valor_novo)
    VALUES (
        CAST(NULLIF(current_setting('eventos.cp_pessoa', true), '') AS bigint),
        TG_TABLE_NAME,
        v_registro,
        TG_OP,
        LOCALTIMESTAMP,
        CASE WHEN TG_OP <> 'INSERT' THEN CAST(CAST(OLD AS varchar) AS varchar(4000)) END,
        CASE WHEN TG_OP <> 'DELETE' THEN CAST(CAST(NEW AS varchar) AS varchar(4000)) END
    );
    RETURN NULL;
END;
$$;

CREATE TRIGGER tg_inscricao_auditoria
AFTER INSERT OR UPDATE OR DELETE ON tbl_inscricao
FOR EACH ROW EXECUTE FUNCTION fn_auditoria();

CREATE TRIGGER tg_documento_auditoria
AFTER INSERT OR UPDATE OR DELETE ON tbl_documento_comprovacao
FOR EACH ROW EXECUTE FUNCTION fn_auditoria();

CREATE TRIGGER tg_pagamento_auditoria
AFTER INSERT OR UPDATE OR DELETE ON tbl_pagamento
FOR EACH ROW EXECUTE FUNCTION fn_auditoria();

CREATE TRIGGER tg_certificado_auditoria
AFTER INSERT OR UPDATE OR DELETE ON tbl_certificado
FOR EACH ROW EXECUTE FUNCTION fn_auditoria();
