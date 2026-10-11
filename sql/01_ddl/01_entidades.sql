SET SCHEMA 'eventos';

CREATE TABLE tbl_pessoa (
    cp_id_pessoa        bigint GENERATED ALWAYS AS IDENTITY,
    nm_pessoa           varchar(200) NOT NULL,
    email_pessoa        varchar(254) NOT NULL,
    pais_pessoa         char(2)      NOT NULL,
    uf_pessoa           char(2),
    cpf_pessoa          char(11),
    passaporte_pessoa   varchar(30),
    dt_nascimento       date,
    ind_anonimizada     boolean      NOT NULL,
    CONSTRAINT pk_pessoa PRIMARY KEY (cp_id_pessoa),
    CONSTRAINT uq_pessoa_email UNIQUE (email_pessoa),
    CONSTRAINT uq_pessoa_cpf UNIQUE (cpf_pessoa),
    CONSTRAINT uq_pessoa_passaporte UNIQUE (passaporte_pessoa, pais_pessoa),
    CONSTRAINT ck_pessoa_documento CHECK (cpf_pessoa IS NOT NULL OR passaporte_pessoa IS NOT NULL)
);

CREATE TABLE tbl_evento (
    cp_id_evento  bigint GENERATED ALWAYS AS IDENTITY,
    sg_evento     varchar(20)   NOT NULL,
    nm_evento     varchar(200)  NOT NULL,
    tp_evento     varchar(20)   NOT NULL,
    ds_evento     varchar(4000),
    CONSTRAINT pk_evento PRIMARY KEY (cp_id_evento),
    CONSTRAINT uq_evento_sigla UNIQUE (sg_evento),
    CONSTRAINT ck_evento_tipo CHECK (tp_evento IN ('CONGRESSO', 'SIMPOSIO', 'WORKSHOP', 'ESCOLA', 'COMPETICAO', 'OUTRO'))
);

CREATE TABLE tbl_edicao_evento (
    cp_id_edicao                bigint GENERATED ALWAYS AS IDENTITY,
    ce_evento                   bigint        NOT NULL,
    ce_edicao_agregadora        bigint,
    ano_edicao                  smallint      NOT NULL,
    nr_edicao                   int,
    dt_inicio_evento            date          NOT NULL,
    dt_fim_evento               date          NOT NULL,
    dt_inicio_inscricao         timestamp     NOT NULL,
    dt_fim_inscricao            timestamp     NOT NULL,
    modalidade_evento           varchar(10)   NOT NULL,
    cidade_evento               varchar(100)  NOT NULL,
    uf_evento                   char(2),
    pais_evento                 char(2)       NOT NULL,
    nr_dias_reserva             smallint      NOT NULL,
    nr_dias_limite_reembolso    smallint      NOT NULL,
    pc_reembolso                numeric(5,2)  NOT NULL,
    ind_exige_credenciamento    boolean       NOT NULL,
    pc_frequencia_minima        numeric(5,2),
    nr_max_trabalhos_inscricao  smallint,
    vl_taxa_trabalho_extra      numeric(10,2),
    CONSTRAINT pk_edicao_evento PRIMARY KEY (cp_id_edicao),
    CONSTRAINT fk_edicao_evento_evento FOREIGN KEY (ce_evento) REFERENCES tbl_evento (cp_id_evento),
    CONSTRAINT fk_edicao_evento_agregadora FOREIGN KEY (ce_edicao_agregadora) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT uq_edicao_evento_ano UNIQUE (ce_evento, ano_edicao),
    CONSTRAINT ck_edicao_evento_datas CHECK (dt_fim_evento >= dt_inicio_evento),
    CONSTRAINT ck_edicao_evento_agregadora CHECK (ce_edicao_agregadora <> cp_id_edicao),
    CONSTRAINT ck_edicao_evento_modalidade CHECK (modalidade_evento IN ('PRESENCIAL', 'REMOTO', 'HIBRIDO')),
    CONSTRAINT ck_edicao_evento_pc_reembolso CHECK (pc_reembolso BETWEEN 0 AND 100),
    CONSTRAINT ck_edicao_evento_pc_frequencia CHECK (pc_frequencia_minima BETWEEN 0 AND 100)
);

CREATE TABLE tbl_categoria_inscricao (
    cp_id_categoria        bigint GENERATED ALWAYS AS IDENTITY,
    ce_edicao              bigint        NOT NULL,
    nm_categoria           varchar(100)  NOT NULL,
    ind_exige_comprovacao  boolean       NOT NULL,
    ind_categoria_autor    boolean       NOT NULL,
    ds_categoria           varchar(4000),
    CONSTRAINT pk_categoria_inscricao PRIMARY KEY (cp_id_categoria),
    CONSTRAINT fk_categoria_inscricao_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT uq_categoria_inscricao_nome UNIQUE (ce_edicao, nm_categoria)
);

CREATE TABLE tbl_faixa_inscricao (
    cp_id_faixa      bigint GENERATED ALWAYS AS IDENTITY,
    ce_edicao        bigint       NOT NULL,
    nm_faixa         varchar(60)  NOT NULL,
    dt_inicio_faixa  timestamp    NOT NULL,
    dt_fim_faixa     timestamp    NOT NULL,
    CONSTRAINT pk_faixa_inscricao PRIMARY KEY (cp_id_faixa),
    CONSTRAINT fk_faixa_inscricao_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT uq_faixa_inscricao_nome UNIQUE (ce_edicao, nm_faixa),
    CONSTRAINT ck_faixa_inscricao_datas CHECK (dt_fim_faixa > dt_inicio_faixa)
);

CREATE TABLE tbl_preco (
    cp_id_preco     bigint GENERATED ALWAYS AS IDENTITY,
    ce_categoria    bigint         NOT NULL,
    ce_faixa        bigint         NOT NULL,
    tp_associacao   varchar(20)    NOT NULL,
    vl_inscricao    numeric(10,2)  NOT NULL,
    vl_associacao   numeric(10,2),
    CONSTRAINT pk_preco PRIMARY KEY (cp_id_preco),
    CONSTRAINT fk_preco_categoria FOREIGN KEY (ce_categoria) REFERENCES tbl_categoria_inscricao (cp_id_categoria),
    CONSTRAINT fk_preco_faixa FOREIGN KEY (ce_faixa) REFERENCES tbl_faixa_inscricao (cp_id_faixa),
    CONSTRAINT uq_preco UNIQUE (ce_categoria, ce_faixa, tp_associacao),
    CONSTRAINT ck_preco_tp_associacao CHECK (tp_associacao IN ('NAO_ASSOCIADO', 'ASSOCIADO', 'COMBO_NOVA', 'COMBO_RENOVACAO')),
    CONSTRAINT ck_preco_vl_associacao CHECK (
        (tp_associacao IN ('COMBO_NOVA', 'COMBO_RENOVACAO') AND vl_associacao IS NOT NULL)
        OR (tp_associacao IN ('NAO_ASSOCIADO', 'ASSOCIADO') AND vl_associacao IS NULL)
    )
);

CREATE TABLE tbl_atividade (
    cp_id_atividade          bigint GENERATED ALWAYS AS IDENTITY,
    ce_edicao                bigint         NOT NULL,
    nm_atividade             varchar(200)   NOT NULL,
    dt_inicio                timestamp      NOT NULL,
    tp_atividade             varchar(20)    NOT NULL,
    dt_fim                   timestamp      NOT NULL,
    ind_inscricao_adicional  boolean        NOT NULL,
    nr_capacidade            int,
    vl_atividade             numeric(10,2),
    CONSTRAINT pk_atividade PRIMARY KEY (cp_id_atividade),
    CONSTRAINT fk_atividade_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT uq_atividade UNIQUE (ce_edicao, nm_atividade, dt_inicio),
    CONSTRAINT ck_atividade_capacidade CHECK (nr_capacidade > 0),
    CONSTRAINT ck_atividade_datas CHECK (dt_fim > dt_inicio)
);

CREATE TABLE tbl_instituicao (
    cp_id_instituicao   bigint GENERATED ALWAYS AS IDENTITY,
    nm_instituicao      varchar(200)  NOT NULL,
    sg_instituicao      varchar(30)   NOT NULL,
    pais_instituicao    char(2)       NOT NULL,
    ind_associada       boolean       NOT NULL,
    cnpj_instituicao    char(14),
    cidade_instituicao  varchar(100),
    uf_instituicao      char(2),
    CONSTRAINT pk_instituicao PRIMARY KEY (cp_id_instituicao),
    CONSTRAINT uq_instituicao_cnpj UNIQUE (cnpj_instituicao)
);

CREATE TABLE tbl_vinculo_institucional (
    cp_id_vinculo      bigint GENERATED ALWAYS AS IDENTITY,
    ce_pessoa          bigint       NOT NULL,
    ce_instituicao     bigint       NOT NULL,
    dt_inicio_vinculo  date         NOT NULL,
    tp_vinculo         varchar(20)  NOT NULL,
    dt_fim_vinculo     date,
    CONSTRAINT pk_vinculo_institucional PRIMARY KEY (cp_id_vinculo),
    CONSTRAINT fk_vinculo_institucional_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT fk_vinculo_institucional_instituicao FOREIGN KEY (ce_instituicao) REFERENCES tbl_instituicao (cp_id_instituicao),
    CONSTRAINT uq_vinculo_institucional UNIQUE (ce_pessoa, ce_instituicao, dt_inicio_vinculo),
    CONSTRAINT ck_vinculo_institucional_datas CHECK (dt_fim_vinculo IS NULL OR dt_fim_vinculo >= dt_inicio_vinculo),
    CONSTRAINT ck_vinculo_institucional_tipo CHECK (tp_vinculo IN ('ESTUDANTE', 'DOCENTE', 'SERVIDOR', 'FUNCIONARIO', 'OUTRO'))
);

CREATE TABLE tbl_beneficio (
    cp_id_beneficio       bigint GENERATED ALWAYS AS IDENTITY,
    ce_instituicao        bigint        NOT NULL,
    tp_beneficio          varchar(20)   NOT NULL,
    dt_inicio_vigencia    date          NOT NULL,
    dt_fim_vigencia       date          NOT NULL,
    nr_limite_periodo     int           NOT NULL,
    nr_limite_por_edicao  int           NOT NULL,
    pc_desconto           numeric(5,2),
    CONSTRAINT pk_beneficio PRIMARY KEY (cp_id_beneficio),
    CONSTRAINT fk_beneficio_instituicao FOREIGN KEY (ce_instituicao) REFERENCES tbl_instituicao (cp_id_instituicao),
    CONSTRAINT uq_beneficio UNIQUE (ce_instituicao, tp_beneficio, dt_inicio_vigencia),
    CONSTRAINT ck_beneficio_tipo CHECK (tp_beneficio IN ('GRATUIDADE', 'DESCONTO')),
    CONSTRAINT ck_beneficio_desconto CHECK (tp_beneficio <> 'DESCONTO' OR pc_desconto IS NOT NULL),
    CONSTRAINT ck_beneficio_pc_desconto CHECK (pc_desconto BETWEEN 0 AND 100)
);

CREATE TABLE tbl_inscricao (
    cp_id_inscricao    bigint GENERATED ALWAYS AS IDENTITY,
    ce_pessoa          bigint       NOT NULL,
    ce_preco           bigint       NOT NULL,
    ce_beneficio       bigint,
    dt_inscricao       timestamp    NOT NULL,
    status_inscricao   varchar(25)  NOT NULL,
    dt_validade_preco  timestamp    NOT NULL,
    dt_uso_beneficio   timestamp,
    dt_confirmacao     timestamp,
    dt_cancelamento    timestamp,
    dt_credenciamento  timestamp,
    CONSTRAINT pk_inscricao PRIMARY KEY (cp_id_inscricao),
    CONSTRAINT fk_inscricao_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT fk_inscricao_preco FOREIGN KEY (ce_preco) REFERENCES tbl_preco (cp_id_preco),
    CONSTRAINT fk_inscricao_beneficio FOREIGN KEY (ce_beneficio) REFERENCES tbl_beneficio (cp_id_beneficio),
    CONSTRAINT ck_inscricao_status CHECK (status_inscricao IN ('INICIADA', 'AGUARDANDO_VALIDACAO', 'AGUARDANDO_PAGAMENTO', 'PAGA', 'CANCELADA', 'CONCLUIDA', 'EXPIRADA')),
    CONSTRAINT ck_inscricao_validade_preco CHECK (dt_validade_preco > dt_inscricao),
    CONSTRAINT ck_inscricao_beneficio CHECK ((ce_beneficio IS NULL) = (dt_uso_beneficio IS NULL))
);

CREATE TABLE tbl_periodo_associacao (
    cp_id_periodo_associacao  bigint GENERATED ALWAYS AS IDENTITY,
    ce_pessoa                 bigint  NOT NULL,
    ce_inscricao_origem       bigint,
    dt_inicio_associacao      date    NOT NULL,
    dt_fim_associacao         date    NOT NULL,
    CONSTRAINT pk_periodo_associacao PRIMARY KEY (cp_id_periodo_associacao),
    CONSTRAINT fk_periodo_associacao_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT fk_periodo_associacao_inscricao FOREIGN KEY (ce_inscricao_origem) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT uq_periodo_associacao UNIQUE (ce_pessoa, dt_inicio_associacao),
    CONSTRAINT uq_periodo_associacao_origem UNIQUE (ce_inscricao_origem)
);

CREATE TABLE tbl_inscricao_atividade (
    cp_id_inscricao_atividade   bigint GENERATED ALWAYS AS IDENTITY,
    ce_inscricao                bigint       NOT NULL,
    ce_atividade                bigint       NOT NULL,
    dt_inclusao                 timestamp    NOT NULL,
    status_inscricao_atividade  varchar(20)  NOT NULL,
    dt_expira_reserva           timestamp,
    dt_cancelamento             timestamp,
    dt_presenca                 timestamp,
    CONSTRAINT pk_inscricao_atividade PRIMARY KEY (cp_id_inscricao_atividade),
    CONSTRAINT fk_inscricao_atividade_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_inscricao_atividade_atividade FOREIGN KEY (ce_atividade) REFERENCES tbl_atividade (cp_id_atividade),
    CONSTRAINT uq_inscricao_atividade UNIQUE (ce_inscricao, ce_atividade),
    CONSTRAINT ck_inscricao_atividade_status CHECK (status_inscricao_atividade IN ('RESERVADA', 'CONFIRMADA', 'CANCELADA', 'EXPIRADA'))
);

CREATE TABLE tbl_trabalho (
    cp_id_trabalho          bigint GENERATED ALWAYS AS IDENTITY,
    ce_edicao               bigint        NOT NULL,
    ce_inscricao_cobertura  bigint,
    cd_trabalho_externo     varchar(50)   NOT NULL,
    titulo_trabalho         varchar(500)  NOT NULL,
    tp_trabalho             varchar(20)   NOT NULL,
    status_trabalho         varchar(15)   NOT NULL,
    CONSTRAINT pk_trabalho PRIMARY KEY (cp_id_trabalho),
    CONSTRAINT fk_trabalho_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT fk_trabalho_inscricao FOREIGN KEY (ce_inscricao_cobertura) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT uq_trabalho UNIQUE (ce_edicao, cd_trabalho_externo)
);

CREATE TABLE tbl_item_financeiro (
    cp_id_item_financeiro   bigint GENERATED ALWAYS AS IDENTITY,
    ce_inscricao            bigint         NOT NULL,
    ce_inscricao_atividade  bigint,
    ce_trabalho             bigint,
    nr_item                 smallint       NOT NULL,
    tp_item                 varchar(20)    NOT NULL,
    vl_item                 numeric(10,2)  NOT NULL,
    status_item             varchar(15)    NOT NULL,
    dt_criacao              timestamp      NOT NULL,
    CONSTRAINT pk_item_financeiro PRIMARY KEY (cp_id_item_financeiro),
    CONSTRAINT fk_item_financeiro_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_item_financeiro_inscricao_atividade FOREIGN KEY (ce_inscricao_atividade) REFERENCES tbl_inscricao_atividade (cp_id_inscricao_atividade),
    CONSTRAINT fk_item_financeiro_trabalho FOREIGN KEY (ce_trabalho) REFERENCES tbl_trabalho (cp_id_trabalho),
    CONSTRAINT uq_item_financeiro UNIQUE (ce_inscricao, nr_item),
    CONSTRAINT ck_item_financeiro_tipo CHECK (tp_item IN ('INSCRICAO', 'ASSOCIACAO', 'ATIVIDADE', 'TAXA_PUBLICACAO', 'DESCONTO')),
    CONSTRAINT ck_item_financeiro_status CHECK (status_item IN ('VALIDO', 'SUBSTITUIDO', 'CANCELADO')),
    CONSTRAINT ck_item_financeiro_valor CHECK (vl_item >= 0),
    CONSTRAINT ck_item_financeiro_atividade CHECK ((tp_item = 'ATIVIDADE') = (ce_inscricao_atividade IS NOT NULL)),
    CONSTRAINT ck_item_financeiro_trabalho CHECK ((tp_item = 'TAXA_PUBLICACAO') = (ce_trabalho IS NOT NULL))
);

CREATE TABLE tbl_pagamento (
    cp_id_pagamento       bigint GENERATED ALWAYS AS IDENTITY,
    ce_inscricao          bigint         NOT NULL,
    dt_criacao            timestamp      NOT NULL,
    tp_pagamento          varchar(15)    NOT NULL,
    vl_pagamento          numeric(10,2)  NOT NULL,
    status_pagamento      varchar(15)    NOT NULL,
    dt_confirmacao        timestamp,
    dt_vencimento         date,
    cd_transacao_externa  varchar(100),
    vl_reembolso          numeric(10,2),
    dt_reembolso          timestamp,
    CONSTRAINT pk_pagamento PRIMARY KEY (cp_id_pagamento),
    CONSTRAINT fk_pagamento_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT uq_pagamento UNIQUE (ce_inscricao, dt_criacao),
    CONSTRAINT uq_pagamento_transacao UNIQUE (cd_transacao_externa),
    CONSTRAINT ck_pagamento_tipo CHECK (tp_pagamento IN ('CARTAO', 'BOLETO', 'FATURAMENTO', 'EMPENHO')),
    CONSTRAINT ck_pagamento_status CHECK (status_pagamento IN ('PENDENTE', 'CONFIRMADO', 'RECUSADO', 'CANCELADO', 'EXPIRADO', 'ESTORNADO')),
    CONSTRAINT ck_pagamento_valor CHECK (vl_pagamento > 0),
    CONSTRAINT ck_pagamento_reembolso CHECK (vl_reembolso <= vl_pagamento)
);

CREATE TABLE tbl_documento_comprovacao (
    cp_id_documento     bigint GENERATED ALWAYS AS IDENTITY,
    ce_inscricao        bigint        NOT NULL,
    ce_pessoa_analise   bigint,
    dt_envio            timestamp     NOT NULL,
    tp_documento        varchar(30)   NOT NULL,
    status_documento    varchar(10)   NOT NULL,
    ds_caminho_arquivo  varchar(500)  NOT NULL,
    dt_analise          timestamp,
    ds_motivo_rejeicao  varchar(500),
    CONSTRAINT pk_documento_comprovacao PRIMARY KEY (cp_id_documento),
    CONSTRAINT fk_documento_comprovacao_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_documento_comprovacao_pessoa FOREIGN KEY (ce_pessoa_analise) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT uq_documento_comprovacao UNIQUE (ce_inscricao, dt_envio),
    CONSTRAINT ck_documento_comprovacao_status CHECK (status_documento IN ('PENDENTE', 'APROVADO', 'REJEITADO')),
    CONSTRAINT ck_documento_comprovacao_analise CHECK (
        status_documento = 'PENDENTE' OR (dt_analise IS NOT NULL AND ce_pessoa_analise IS NOT NULL)
    )
);

CREATE TABLE tbl_termo (
    cp_id_termo         bigint GENERATED ALWAYS AS IDENTITY,
    nm_termo            varchar(100)   NOT NULL,
    nr_versao           varchar(10)    NOT NULL,
    ds_termo            varchar(4000)  NOT NULL,
    dt_inicio_vigencia  timestamp      NOT NULL,
    dt_fim_vigencia     timestamp,
    CONSTRAINT pk_termo PRIMARY KEY (cp_id_termo),
    CONSTRAINT uq_termo_versao UNIQUE (nm_termo, nr_versao)
);

CREATE TABLE tbl_certificado (
    cp_id_certificado   bigint GENERATED ALWAYS AS IDENTITY,
    ce_pessoa           bigint       NOT NULL,
    ce_edicao           bigint       NOT NULL,
    ce_atividade        bigint,
    cd_validacao        varchar(64)  NOT NULL,
    tp_certificado      varchar(20)  NOT NULL,
    dt_emissao          timestamp    NOT NULL,
    status_certificado  varchar(10)  NOT NULL,
    CONSTRAINT pk_certificado PRIMARY KEY (cp_id_certificado),
    CONSTRAINT fk_certificado_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT fk_certificado_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT fk_certificado_atividade FOREIGN KEY (ce_atividade) REFERENCES tbl_atividade (cp_id_atividade),
    CONSTRAINT uq_certificado_validacao UNIQUE (cd_validacao),
    CONSTRAINT ck_certificado_tipo CHECK (tp_certificado IN ('PARTICIPACAO', 'ATIVIDADE', 'AUTORIA', 'ORGANIZACAO')),
    CONSTRAINT ck_certificado_status CHECK (status_certificado IN ('VALIDO', 'REVOGADO'))
);

CREATE TABLE tbl_auditoria (
    cp_id_auditoria        bigint GENERATED ALWAYS AS IDENTITY,
    ce_pessoa_responsavel  bigint,
    nm_tabela              varchar(60)    NOT NULL,
    cd_registro            bigint         NOT NULL,
    tp_operacao            varchar(10)    NOT NULL,
    dt_operacao            timestamp      NOT NULL,
    ds_valor_anterior      varchar(4000),
    ds_valor_novo          varchar(4000),
    CONSTRAINT pk_auditoria PRIMARY KEY (cp_id_auditoria),
    CONSTRAINT fk_auditoria_pessoa FOREIGN KEY (ce_pessoa_responsavel) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT ck_auditoria_operacao CHECK (tp_operacao IN ('INSERT', 'UPDATE', 'DELETE'))
);
