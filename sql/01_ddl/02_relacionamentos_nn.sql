SET SCHEMA 'eventos';

CREATE TABLE tbl_autoria (
    ce_pessoa    bigint NOT NULL,
    ce_trabalho  bigint NOT NULL,
    CONSTRAINT pk_autoria PRIMARY KEY (ce_pessoa, ce_trabalho),
    CONSTRAINT fk_autoria_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT fk_autoria_trabalho FOREIGN KEY (ce_trabalho) REFERENCES tbl_trabalho (cp_id_trabalho)
);

CREATE TABLE tbl_resposta_termo (
    ce_inscricao  bigint     NOT NULL,
    ce_termo      bigint     NOT NULL,
    ind_aceite    boolean    NOT NULL,
    dt_resposta   timestamp  NOT NULL,
    CONSTRAINT pk_resposta_termo PRIMARY KEY (ce_inscricao, ce_termo),
    CONSTRAINT fk_resposta_termo_inscricao FOREIGN KEY (ce_inscricao) REFERENCES tbl_inscricao (cp_id_inscricao),
    CONSTRAINT fk_resposta_termo_termo FOREIGN KEY (ce_termo) REFERENCES tbl_termo (cp_id_termo)
);

CREATE TABLE tbl_organizacao_edicao (
    ce_pessoa  bigint       NOT NULL,
    ce_edicao  bigint       NOT NULL,
    tp_papel   varchar(20)  NOT NULL,
    CONSTRAINT pk_organizacao_edicao PRIMARY KEY (ce_pessoa, ce_edicao, tp_papel),
    CONSTRAINT fk_organizacao_edicao_pessoa FOREIGN KEY (ce_pessoa) REFERENCES tbl_pessoa (cp_id_pessoa),
    CONSTRAINT fk_organizacao_edicao_edicao FOREIGN KEY (ce_edicao) REFERENCES tbl_edicao_evento (cp_id_edicao),
    CONSTRAINT ck_organizacao_edicao_papel CHECK (tp_papel IN ('COORD_GERAL', 'COORD_FINANCEIRA', 'APOIO_ADMIN'))
);

CREATE TABLE tbl_restricao_atividade (
    ce_atividade  bigint NOT NULL,
    ce_categoria  bigint NOT NULL,
    CONSTRAINT pk_restricao_atividade PRIMARY KEY (ce_atividade, ce_categoria),
    CONSTRAINT fk_restricao_atividade_atividade FOREIGN KEY (ce_atividade) REFERENCES tbl_atividade (cp_id_atividade),
    CONSTRAINT fk_restricao_atividade_categoria FOREIGN KEY (ce_categoria) REFERENCES tbl_categoria_inscricao (cp_id_categoria)
);
