SET SCHEMA 'eventos';

CREATE FUNCTION fn_edicao_do_preco(p_preco bigint) RETURNS bigint
LANGUAGE plpgsql STABLE SET search_path = eventos AS $$
DECLARE
    v_edicao bigint;
BEGIN
    SELECT c.ce_edicao INTO v_edicao
      FROM tbl_preco p
      JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
     WHERE p.cp_id_preco = p_preco;
    RETURN v_edicao;
END;
$$;

CREATE FUNCTION fn_edicao_da_inscricao(p_inscricao bigint) RETURNS bigint
LANGUAGE plpgsql STABLE SET search_path = eventos AS $$
DECLARE
    v_preco bigint;
BEGIN
    SELECT ce_preco INTO v_preco FROM tbl_inscricao WHERE cp_id_inscricao = p_inscricao;
    RETURN fn_edicao_do_preco(v_preco);
END;
$$;

CREATE FUNCTION fn_faixa_sobreposicao() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM tbl_faixa_inscricao f
         WHERE f.ce_edicao = NEW.ce_edicao
           AND f.cp_id_faixa <> NEW.cp_id_faixa
           AND NEW.dt_inicio_faixa < f.dt_fim_faixa
           AND f.dt_inicio_faixa < NEW.dt_fim_faixa
    ) THEN
        RAISE EXCEPTION 'fn_faixa_sobreposicao: faixa sobrepõe outra faixa da edição %', NEW.ce_edicao;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_faixa_sobreposicao
BEFORE INSERT OR UPDATE OF ce_edicao, dt_inicio_faixa, dt_fim_faixa ON tbl_faixa_inscricao
FOR EACH ROW EXECUTE FUNCTION fn_faixa_sobreposicao();

CREATE FUNCTION fn_periodo_associacao() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM tbl_periodo_associacao p
         WHERE p.ce_pessoa = NEW.ce_pessoa
           AND p.cp_id_periodo_associacao <> NEW.cp_id_periodo_associacao
           AND NEW.dt_inicio_associacao <= p.dt_fim_associacao
           AND p.dt_inicio_associacao <= NEW.dt_fim_associacao
    ) THEN
        RAISE EXCEPTION 'fn_periodo_associacao: período sobrepõe outro período da pessoa %', NEW.ce_pessoa;
    END IF;
    IF NEW.ce_inscricao_origem IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM tbl_inscricao i
         WHERE i.cp_id_inscricao = NEW.ce_inscricao_origem
           AND i.ce_pessoa = NEW.ce_pessoa
    ) THEN
        RAISE EXCEPTION 'fn_periodo_associacao: inscrição de origem pertence a outra pessoa';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_periodo_associacao
BEFORE INSERT OR UPDATE ON tbl_periodo_associacao
FOR EACH ROW EXECUTE FUNCTION fn_periodo_associacao();

CREATE FUNCTION fn_preco_mesma_edicao() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF (SELECT ce_edicao FROM tbl_categoria_inscricao WHERE cp_id_categoria = NEW.ce_categoria)
       <> (SELECT ce_edicao FROM tbl_faixa_inscricao WHERE cp_id_faixa = NEW.ce_faixa) THEN
        RAISE EXCEPTION 'fn_preco_mesma_edicao: categoria e faixa pertencem a edições diferentes';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_preco_mesma_edicao
BEFORE INSERT OR UPDATE OF ce_categoria, ce_faixa ON tbl_preco
FOR EACH ROW EXECUTE FUNCTION fn_preco_mesma_edicao();

CREATE FUNCTION fn_edicao_agregacao() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF NEW.ce_edicao_agregadora IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM tbl_edicao_evento
             WHERE cp_id_edicao = NEW.ce_edicao_agregadora
               AND ce_edicao_agregadora IS NOT NULL
        ) THEN
            RAISE EXCEPTION 'fn_edicao_agregacao: a edição agregadora já é agregada por outra';
        END IF;
        IF EXISTS (
            SELECT 1 FROM tbl_edicao_evento WHERE ce_edicao_agregadora = NEW.cp_id_edicao
        ) THEN
            RAISE EXCEPTION 'fn_edicao_agregacao: uma edição agregadora não pode ser agregada';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_edicao_agregacao
BEFORE INSERT OR UPDATE OF ce_edicao_agregadora ON tbl_edicao_evento
FOR EACH ROW EXECUTE FUNCTION fn_edicao_agregacao();

CREATE FUNCTION fn_restricao_mesma_edicao() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF (SELECT ce_edicao FROM tbl_atividade WHERE cp_id_atividade = NEW.ce_atividade)
       <> (SELECT ce_edicao FROM tbl_categoria_inscricao WHERE cp_id_categoria = NEW.ce_categoria) THEN
        RAISE EXCEPTION 'fn_restricao_mesma_edicao: atividade e categoria pertencem a edições diferentes';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_restricao_mesma_edicao
BEFORE INSERT OR UPDATE ON tbl_restricao_atividade
FOR EACH ROW EXECUTE FUNCTION fn_restricao_mesma_edicao();

CREATE FUNCTION fn_item_origem() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF NEW.ce_inscricao_atividade IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM tbl_inscricao_atividade
         WHERE cp_id_inscricao_atividade = NEW.ce_inscricao_atividade
           AND ce_inscricao = NEW.ce_inscricao
    ) THEN
        RAISE EXCEPTION 'fn_item_origem: a inscrição em atividade pertence a outra inscrição';
    END IF;
    IF NEW.ce_trabalho IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM tbl_trabalho
         WHERE cp_id_trabalho = NEW.ce_trabalho
           AND ce_inscricao_cobertura = NEW.ce_inscricao
    ) THEN
        RAISE EXCEPTION 'fn_item_origem: a sobretaxa deve ser lançada na inscrição que cobre o trabalho';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_item_origem
BEFORE INSERT ON tbl_item_financeiro
FOR EACH ROW EXECUTE FUNCTION fn_item_origem();

CREATE FUNCTION fn_certificado_atividade() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = eventos AS $$
BEGIN
    IF NEW.ce_atividade IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM tbl_atividade
         WHERE cp_id_atividade = NEW.ce_atividade
           AND ce_edicao = NEW.ce_edicao
    ) THEN
        RAISE EXCEPTION 'fn_certificado_atividade: a atividade pertence a outra edição';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_certificado_atividade
BEFORE INSERT ON tbl_certificado
FOR EACH ROW EXECUTE FUNCTION fn_certificado_atividade();
