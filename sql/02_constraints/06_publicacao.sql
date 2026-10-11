SET SCHEMA 'eventos';

CREATE FUNCTION fn_trabalho_cobertura() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_insc tbl_inscricao%ROWTYPE;
BEGIN
    IF NEW.ce_inscricao_cobertura IS NULL
       OR (TG_OP = 'UPDATE' AND NEW.ce_inscricao_cobertura IS NOT DISTINCT FROM OLD.ce_inscricao_cobertura) THEN
        RETURN NEW;
    END IF;
    SELECT * INTO v_insc FROM tbl_inscricao WHERE cp_id_inscricao = NEW.ce_inscricao_cobertura FOR UPDATE;

    IF v_insc.status_inscricao IN ('CANCELADA', 'EXPIRADA') THEN
        RAISE EXCEPTION 'fn_trabalho_cobertura: inscrição de cobertura cancelada ou expirada';
    END IF;
    IF fn_edicao_do_preco(v_insc.ce_preco) <> NEW.ce_edicao THEN
        RAISE EXCEPTION 'fn_trabalho_cobertura: inscrição de cobertura pertence a outra edição';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM tbl_preco p
          JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
         WHERE p.cp_id_preco = v_insc.ce_preco AND c.ind_categoria_autor
    ) THEN
        RAISE EXCEPTION 'fn_trabalho_cobertura: a categoria da inscrição não cobre publicação';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM tbl_autoria
         WHERE ce_pessoa = v_insc.ce_pessoa AND ce_trabalho = NEW.cp_id_trabalho
    ) THEN
        RAISE EXCEPTION 'fn_trabalho_cobertura: a inscrição de cobertura não é de um autor do trabalho';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_trabalho_cobertura
BEFORE INSERT OR UPDATE OF ce_inscricao_cobertura ON tbl_trabalho
FOR EACH ROW EXECUTE FUNCTION fn_trabalho_cobertura();

CREATE FUNCTION fn_trabalho_sobretaxa() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_edicao  tbl_edicao_evento%ROWTYPE;
    v_status  varchar(25);
    v_qtd     bigint;
    v_nr      smallint;
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.ce_inscricao_cobertura IS NOT NULL
       AND NEW.ce_inscricao_cobertura IS DISTINCT FROM OLD.ce_inscricao_cobertura THEN
        UPDATE tbl_item_financeiro
           SET status_item = 'CANCELADO'
         WHERE ce_trabalho = NEW.cp_id_trabalho
           AND ce_inscricao = OLD.ce_inscricao_cobertura
           AND status_item = 'VALIDO';
    END IF;

    IF NEW.ce_inscricao_cobertura IS NULL
       OR (TG_OP = 'UPDATE' AND NEW.ce_inscricao_cobertura IS NOT DISTINCT FROM OLD.ce_inscricao_cobertura) THEN
        RETURN NULL;
    END IF;

    SELECT * INTO v_edicao FROM tbl_edicao_evento WHERE cp_id_edicao = NEW.ce_edicao;
    IF v_edicao.nr_max_trabalhos_inscricao IS NULL THEN
        RETURN NULL;
    END IF;
    SELECT COUNT(*) INTO v_qtd FROM tbl_trabalho WHERE ce_inscricao_cobertura = NEW.ce_inscricao_cobertura;
    IF v_qtd <= v_edicao.nr_max_trabalhos_inscricao THEN
        RETURN NULL;
    END IF;

    SELECT status_inscricao INTO v_status FROM tbl_inscricao WHERE cp_id_inscricao = NEW.ce_inscricao_cobertura;
    IF v_edicao.vl_taxa_trabalho_extra IS NULL THEN
        RAISE EXCEPTION 'fn_trabalho_sobretaxa: limite de trabalhos por inscrição atingido';
    END IF;
    IF v_status NOT IN ('INICIADA', 'AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO') THEN
        RAISE EXCEPTION 'fn_trabalho_sobretaxa: trabalho excedente exige inscrição ainda não paga';
    END IF;
    SELECT COALESCE(MAX(nr_item), 0) + 1 INTO v_nr
      FROM tbl_item_financeiro WHERE ce_inscricao = NEW.ce_inscricao_cobertura;
    INSERT INTO tbl_item_financeiro (ce_inscricao, ce_trabalho, nr_item, tp_item, vl_item, status_item, dt_criacao)
    VALUES (NEW.ce_inscricao_cobertura, NEW.cp_id_trabalho, v_nr, 'TAXA_PUBLICACAO',
            v_edicao.vl_taxa_trabalho_extra, 'VALIDO', LOCALTIMESTAMP);
    RETURN NULL;
END;
$$;

CREATE TRIGGER tg_trabalho_sobretaxa
AFTER INSERT OR UPDATE OF ce_inscricao_cobertura ON tbl_trabalho
FOR EACH ROW EXECUTE FUNCTION fn_trabalho_sobretaxa();
