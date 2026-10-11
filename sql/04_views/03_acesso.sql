SET SCHEMA 'eventos';

CREATE VIEW vw_pessoa_mascarada AS
SELECT cp_id_pessoa,
       nm_pessoa,
       SUBSTRING(email_pessoa FROM 1 FOR 2) || '***' || SUBSTRING(email_pessoa FROM POSITION('@' IN email_pessoa)) AS email_mascarado,
       CASE WHEN cpf_pessoa IS NOT NULL THEN '*******' || SUBSTRING(cpf_pessoa FROM 8 FOR 4) END AS cpf_mascarado,
       pais_pessoa,
       uf_pessoa,
       ind_anonimizada
  FROM tbl_pessoa;

CREATE ROLE papel_admin;
CREATE ROLE papel_financeiro;
CREATE ROLE papel_credenciamento;
CREATE ROLE papel_organizacao;
CREATE ROLE papel_relatorio;

GRANT USAGE ON SCHEMA eventos TO papel_admin, papel_financeiro, papel_credenciamento, papel_organizacao, papel_relatorio;

GRANT SELECT, INSERT, UPDATE, DELETE
   ON tbl_pessoa, tbl_evento, tbl_edicao_evento, tbl_categoria_inscricao, tbl_faixa_inscricao, tbl_preco,
      tbl_atividade, tbl_instituicao, tbl_vinculo_institucional, tbl_beneficio, tbl_inscricao,
      tbl_periodo_associacao, tbl_inscricao_atividade, tbl_trabalho, tbl_item_financeiro, tbl_pagamento,
      tbl_documento_comprovacao, tbl_termo, tbl_certificado, tbl_auditoria, tbl_autoria,
      tbl_resposta_termo, tbl_organizacao_edicao, tbl_restricao_atividade
   TO papel_admin;
GRANT EXECUTE ON PROCEDURE prc_expirar_pendencias, prc_anonimizar_pessoa TO papel_admin;

GRANT SELECT ON tbl_evento, tbl_edicao_evento, tbl_categoria_inscricao, tbl_faixa_inscricao, tbl_preco,
                tbl_instituicao, tbl_beneficio, tbl_inscricao, tbl_item_financeiro, tbl_pagamento,
                vw_pessoa_mascarada, vw_inscricao_detalhe, vw_valor_inscricao, vw_saldo_inscricao,
                vw_receita_edicao, vw_receita_categoria_forma, vw_uso_beneficio
             TO papel_financeiro;
GRANT INSERT ON tbl_pagamento TO papel_financeiro;
GRANT UPDATE (status_pagamento, dt_confirmacao, cd_transacao_externa) ON tbl_pagamento TO papel_financeiro;
GRANT UPDATE (status_inscricao, dt_confirmacao, dt_cancelamento) ON tbl_inscricao TO papel_financeiro;

GRANT SELECT ON tbl_edicao_evento, tbl_atividade, tbl_inscricao, tbl_inscricao_atividade,
                vw_pessoa_mascarada, vw_inscricao_detalhe, vw_credenciados_dia_atividade
             TO papel_credenciamento;
GRANT UPDATE (dt_credenciamento) ON tbl_inscricao TO papel_credenciamento;
GRANT UPDATE (dt_presenca) ON tbl_inscricao_atividade TO papel_credenciamento;

GRANT SELECT ON tbl_evento, tbl_edicao_evento, tbl_categoria_inscricao, tbl_faixa_inscricao, tbl_preco,
                tbl_atividade, tbl_restricao_atividade, tbl_organizacao_edicao, tbl_trabalho, tbl_autoria,
                tbl_termo, tbl_certificado, tbl_documento_comprovacao, tbl_inscricao,
                vw_pessoa_mascarada, vw_inscricao_detalhe, vw_aptidao_certificado,
                vw_trabalho_sem_cobertura, vw_documentos_pendentes
             TO papel_organizacao;
GRANT INSERT, UPDATE ON tbl_categoria_inscricao, tbl_faixa_inscricao, tbl_preco, tbl_atividade,
                        tbl_restricao_atividade, tbl_trabalho, tbl_autoria, tbl_termo
                     TO papel_organizacao;
GRANT INSERT ON tbl_certificado TO papel_organizacao;
GRANT UPDATE (status_certificado) ON tbl_certificado TO papel_organizacao;
GRANT UPDATE (status_documento, dt_analise, ce_pessoa_analise, ds_motivo_rejeicao)
   ON tbl_documento_comprovacao TO papel_organizacao;

GRANT SELECT ON vw_inscritos_evento_categoria_instituicao, vw_evolucao_inscricoes, vw_situacao_inscricoes,
                vw_receita_edicao, vw_receita_categoria_forma, vw_uso_beneficio, vw_inscritos_atividade_limitada,
                vw_trabalho_sem_cobertura, vw_aptidao_certificado, vw_credenciados_dia_atividade,
                vw_distribuicao_participantes, vw_documentos_pendentes
             TO papel_relatorio;
