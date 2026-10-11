SET SCHEMA 'eventos';

ALTER TABLE tbl_pessoa
    ADD CONSTRAINT ck_pessoa_uf CHECK (
        pais_pessoa <> 'BR' OR uf_pessoa IS NULL OR uf_pessoa IN (
            'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA',
            'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
        )
    );

ALTER TABLE tbl_periodo_associacao
    ADD CONSTRAINT ck_periodo_associacao_datas CHECK (dt_fim_associacao >= dt_inicio_associacao);

ALTER TABLE tbl_inscricao
    ADD CONSTRAINT ck_inscricao_credenciamento CHECK (
        dt_credenciamento IS NULL OR status_inscricao IN ('PAGA', 'CONCLUIDA', 'CANCELADA')
    );

ALTER TABLE tbl_inscricao_atividade
    ADD CONSTRAINT ck_inscricao_atividade_reserva CHECK (
        status_inscricao_atividade <> 'RESERVADA' OR dt_expira_reserva IS NOT NULL
    ),
    ADD CONSTRAINT ck_inscricao_atividade_presenca CHECK (
        dt_presenca IS NULL OR status_inscricao_atividade IN ('CONFIRMADA', 'CANCELADA')
    );

ALTER TABLE tbl_pagamento
    ADD CONSTRAINT ck_pagamento_vencimento CHECK (
        tp_pagamento NOT IN ('BOLETO', 'EMPENHO') OR dt_vencimento IS NOT NULL
    ),
    ADD CONSTRAINT ck_pagamento_estorno CHECK (
        (status_pagamento = 'ESTORNADO') = (vl_reembolso IS NOT NULL)
        AND (vl_reembolso IS NULL) = (dt_reembolso IS NULL)
    );

ALTER TABLE tbl_documento_comprovacao
    ADD CONSTRAINT ck_documento_comprovacao_motivo CHECK (
        (status_documento = 'REJEITADO') = (ds_motivo_rejeicao IS NOT NULL)
    );
