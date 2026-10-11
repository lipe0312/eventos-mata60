SET SCHEMA 'eventos';

CREATE FUNCTION fn_evento_edicao_minima() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_evento bigint;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_evento := OLD.ce_evento;
    ELSE
        v_evento := NEW.cp_id_evento;
    END IF;
    IF EXISTS (SELECT 1 FROM tbl_evento WHERE cp_id_evento = v_evento)
       AND NOT EXISTS (SELECT 1 FROM tbl_edicao_evento WHERE ce_evento = v_evento) THEN
        RAISE EXCEPTION 'fn_evento_edicao_minima: evento % precisa de ao menos uma edição', v_evento;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER tg_evento_edicao_minima
AFTER INSERT ON tbl_evento DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_evento_edicao_minima();
CREATE CONSTRAINT TRIGGER tg_edicao_evento_minima_exclusao
AFTER DELETE ON tbl_edicao_evento DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_evento_edicao_minima();

CREATE FUNCTION fn_edicao_oferta_minima() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_edicao bigint;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_edicao := OLD.ce_edicao;
    ELSE
        v_edicao := NEW.cp_id_edicao;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tbl_edicao_evento WHERE cp_id_edicao = v_edicao) THEN
        RETURN NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tbl_categoria_inscricao WHERE ce_edicao = v_edicao) THEN
        RAISE EXCEPTION 'fn_edicao_oferta_minima: edição % precisa de ao menos uma categoria', v_edicao;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tbl_faixa_inscricao WHERE ce_edicao = v_edicao) THEN
        RAISE EXCEPTION 'fn_edicao_oferta_minima: edição % precisa de ao menos uma faixa', v_edicao;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tbl_organizacao_edicao WHERE ce_edicao = v_edicao) THEN
        RAISE EXCEPTION 'fn_edicao_oferta_minima: edição % precisa de ao menos um organizador', v_edicao;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER tg_edicao_oferta_minima
AFTER INSERT ON tbl_edicao_evento DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_edicao_oferta_minima();
CREATE CONSTRAINT TRIGGER tg_categoria_minima_exclusao
AFTER DELETE ON tbl_categoria_inscricao DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_edicao_oferta_minima();
CREATE CONSTRAINT TRIGGER tg_faixa_minima_exclusao
AFTER DELETE ON tbl_faixa_inscricao DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_edicao_oferta_minima();
CREATE CONSTRAINT TRIGGER tg_organizacao_minima_exclusao
AFTER DELETE ON tbl_organizacao_edicao DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_edicao_oferta_minima();

CREATE FUNCTION fn_categoria_preco_minimo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_categoria bigint;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_categoria := OLD.ce_categoria;
    ELSE
        v_categoria := NEW.cp_id_categoria;
    END IF;
    IF EXISTS (SELECT 1 FROM tbl_categoria_inscricao WHERE cp_id_categoria = v_categoria)
       AND NOT EXISTS (SELECT 1 FROM tbl_preco WHERE ce_categoria = v_categoria) THEN
        RAISE EXCEPTION 'fn_categoria_preco_minimo: categoria % precisa de ao menos um preço', v_categoria;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER tg_categoria_preco_minimo
AFTER INSERT ON tbl_categoria_inscricao DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_categoria_preco_minimo();
CREATE CONSTRAINT TRIGGER tg_preco_categoria_exclusao
AFTER DELETE ON tbl_preco DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_categoria_preco_minimo();

CREATE FUNCTION fn_faixa_preco_minimo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_faixa bigint;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_faixa := OLD.ce_faixa;
    ELSE
        v_faixa := NEW.cp_id_faixa;
    END IF;
    IF EXISTS (SELECT 1 FROM tbl_faixa_inscricao WHERE cp_id_faixa = v_faixa)
       AND NOT EXISTS (SELECT 1 FROM tbl_preco WHERE ce_faixa = v_faixa) THEN
        RAISE EXCEPTION 'fn_faixa_preco_minimo: faixa % precisa de ao menos um preço', v_faixa;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER tg_faixa_preco_minimo
AFTER INSERT ON tbl_faixa_inscricao DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_faixa_preco_minimo();
CREATE CONSTRAINT TRIGGER tg_preco_faixa_exclusao
AFTER DELETE ON tbl_preco DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_faixa_preco_minimo();

CREATE FUNCTION fn_trabalho_autor_minimo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
DECLARE
    v_trabalho bigint;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_trabalho := OLD.ce_trabalho;
    ELSE
        v_trabalho := NEW.cp_id_trabalho;
    END IF;
    IF EXISTS (SELECT 1 FROM tbl_trabalho WHERE cp_id_trabalho = v_trabalho)
       AND NOT EXISTS (SELECT 1 FROM tbl_autoria WHERE ce_trabalho = v_trabalho) THEN
        RAISE EXCEPTION 'fn_trabalho_autor_minimo: trabalho % precisa de ao menos um autor', v_trabalho;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER tg_trabalho_autor_minimo
AFTER INSERT ON tbl_trabalho DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_trabalho_autor_minimo();
CREATE CONSTRAINT TRIGGER tg_autoria_minima_exclusao
AFTER DELETE ON tbl_autoria DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_trabalho_autor_minimo();
