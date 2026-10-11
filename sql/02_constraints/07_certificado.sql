SET SCHEMA 'eventos';

CREATE FUNCTION fn_certificado_insert() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_edicao tbl_edicao_evento%ROWTYPE;
    v_apto   boolean;
BEGIN
    IF NEW.status_certificado <> 'VALIDO' THEN
        RAISE EXCEPTION 'fn_certificado_insert: todo certificado é emitido como VALIDO';
    END IF;
    IF (NEW.tp_certificado = 'ATIVIDADE') <> (NEW.ce_atividade IS NOT NULL) THEN
        RAISE EXCEPTION 'fn_certificado_insert: apenas certificado de ATIVIDADE referencia atividade';
    END IF;

    PERFORM 1 FROM tbl_pessoa WHERE cp_id_pessoa = NEW.ce_pessoa FOR UPDATE;
    IF EXISTS (
        SELECT 1 FROM tbl_certificado
         WHERE ce_pessoa = NEW.ce_pessoa
           AND ce_edicao = NEW.ce_edicao
           AND tp_certificado = NEW.tp_certificado
           AND ce_atividade IS NOT DISTINCT FROM NEW.ce_atividade
           AND status_certificado = 'VALIDO'
    ) THEN
        RAISE EXCEPTION 'fn_certificado_insert: já existe certificado válido para a mesma finalidade';
    END IF;

    SELECT * INTO v_edicao FROM tbl_edicao_evento WHERE cp_id_edicao = NEW.ce_edicao;

    IF NEW.tp_certificado = 'PARTICIPACAO' THEN
        v_apto := EXISTS (
            SELECT 1
              FROM tbl_inscricao i
              JOIN tbl_preco p ON p.cp_id_preco = i.ce_preco
              JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
             WHERE i.ce_pessoa = NEW.ce_pessoa
               AND c.ce_edicao = NEW.ce_edicao
               AND i.status_inscricao IN ('PAGA', 'CONCLUIDA')
               AND (NOT v_edicao.ind_exige_credenciamento OR i.dt_credenciamento IS NOT NULL)
               AND (
                   v_edicao.pc_frequencia_minima IS NULL
                   OR EXISTS (
                       SELECT 1 FROM tbl_inscricao_atividade ia
                        WHERE ia.ce_inscricao = i.cp_id_inscricao
                          AND ia.status_inscricao_atividade = 'CONFIRMADA'
                       HAVING COUNT(*) > 0
                          AND COUNT(ia.dt_presenca) * 100 >= v_edicao.pc_frequencia_minima * COUNT(*)
                   )
               )
        );
    ELSIF NEW.tp_certificado = 'ATIVIDADE' THEN
        v_apto := EXISTS (
            SELECT 1
              FROM tbl_inscricao i
              JOIN tbl_inscricao_atividade ia ON ia.ce_inscricao = i.cp_id_inscricao
             WHERE i.ce_pessoa = NEW.ce_pessoa
               AND i.status_inscricao IN ('PAGA', 'CONCLUIDA')
               AND ia.ce_atividade = NEW.ce_atividade
               AND ia.status_inscricao_atividade = 'CONFIRMADA'
               AND ia.dt_presenca IS NOT NULL
        );
    ELSIF NEW.tp_certificado = 'AUTORIA' THEN
        v_apto := EXISTS (
            SELECT 1
              FROM tbl_autoria a
              JOIN tbl_trabalho t ON t.cp_id_trabalho = a.ce_trabalho
             WHERE a.ce_pessoa = NEW.ce_pessoa
               AND t.ce_edicao = NEW.ce_edicao
        );
    ELSE
        v_apto := EXISTS (
            SELECT 1 FROM tbl_organizacao_edicao
             WHERE ce_pessoa = NEW.ce_pessoa AND ce_edicao = NEW.ce_edicao
        );
    END IF;

    IF NOT v_apto THEN
        RAISE EXCEPTION 'fn_certificado_insert: pessoa % não atende aos critérios do certificado %',
            NEW.ce_pessoa, NEW.tp_certificado;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_certificado_insert
BEFORE INSERT ON tbl_certificado
FOR EACH ROW EXECUTE FUNCTION fn_certificado_insert();

CREATE FUNCTION fn_certificado_update() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF NEW.ce_pessoa <> OLD.ce_pessoa
       OR NEW.ce_edicao <> OLD.ce_edicao
       OR NEW.ce_atividade IS DISTINCT FROM OLD.ce_atividade
       OR NEW.cd_validacao <> OLD.cd_validacao
       OR NEW.tp_certificado <> OLD.tp_certificado
       OR NEW.dt_emissao <> OLD.dt_emissao
       OR NOT (OLD.status_certificado = 'VALIDO' AND NEW.status_certificado = 'REVOGADO') THEN
        RAISE EXCEPTION 'fn_certificado_update: certificado só admite revogação';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_certificado_update
BEFORE UPDATE ON tbl_certificado
FOR EACH ROW EXECUTE FUNCTION fn_certificado_update();
