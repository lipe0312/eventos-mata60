SET SCHEMA 'eventos';

CREATE PROCEDURE prc_expirar_pendencias()
LANGUAGE SQL
BEGIN ATOMIC
    UPDATE tbl_inscricao
       SET status_inscricao = 'EXPIRADA'
     WHERE status_inscricao IN ('INICIADA', 'AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO')
       AND dt_validade_preco < LOCALTIMESTAMP;
    UPDATE tbl_inscricao_atividade
       SET status_inscricao_atividade = 'EXPIRADA'
     WHERE status_inscricao_atividade = 'RESERVADA'
       AND dt_expira_reserva < LOCALTIMESTAMP;
END;

CREATE PROCEDURE prc_anonimizar_pessoa(p_pessoa bigint)
LANGUAGE SQL
BEGIN ATOMIC
    UPDATE tbl_pessoa
       SET nm_pessoa = 'ANONIMIZADO',
           email_pessoa = 'anonimizado' || CAST(cp_id_pessoa AS varchar(20)) || '@anonimizado.invalid',
           cpf_pessoa = NULL,
           passaporte_pessoa = 'ANON' || CAST(cp_id_pessoa AS varchar(20)),
           uf_pessoa = NULL,
           dt_nascimento = NULL,
           ind_anonimizada = TRUE
     WHERE cp_id_pessoa = p_pessoa;
END;
