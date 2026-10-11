SET SCHEMA 'eventos';

INSERT INTO tbl_documento_comprovacao (ce_inscricao, dt_envio, tp_documento, status_documento, ds_caminho_arquivo)
SELECT i.cp_id_inscricao,
       i.dt_inscricao + INTERVAL '1' HOUR,
       CASE WHEN c.ind_categoria_autor THEN 'DECLARACAO_POS_GRADUACAO' ELSE 'COMPROVANTE_MATRICULA' END,
       'PENDENTE',
       'documentos/' || CAST(i.cp_id_inscricao AS varchar(20)) || '/1.pdf'
  FROM tbl_inscricao i
  JOIN tbl_preco p ON p.cp_id_preco = i.ce_preco
  JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
 WHERE c.ind_exige_comprovacao
 ORDER BY i.cp_id_inscricao;

UPDATE tbl_inscricao
   SET status_inscricao = 'AGUARDANDO_VALIDACAO'
 WHERE ce_preco IN (
       SELECT p.cp_id_preco
         FROM tbl_preco p
         JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
        WHERE c.ind_exige_comprovacao
 );

UPDATE tbl_documento_comprovacao d
   SET status_documento = CASE WHEN MOD(d.ce_inscricao, 10) = 8 THEN 'REJEITADO' ELSE 'APROVADO' END,
       ds_motivo_rejeicao = CASE WHEN MOD(d.ce_inscricao, 10) = 8 THEN 'Documento ilegível' END,
       dt_analise = d.dt_envio + INTERVAL '1' DAY,
       ce_pessoa_analise = (
           SELECT o.ce_pessoa
             FROM tbl_inscricao i
             JOIN tbl_preco p ON p.cp_id_preco = i.ce_preco
             JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
             JOIN tbl_organizacao_edicao o ON o.ce_edicao = c.ce_edicao AND o.tp_papel = 'COORD_GERAL'
            WHERE i.cp_id_inscricao = d.ce_inscricao
       )
 WHERE MOD(d.ce_inscricao, 10) <> 9;

INSERT INTO tbl_documento_comprovacao (ce_inscricao, dt_envio, tp_documento, status_documento, ds_caminho_arquivo)
SELECT d.ce_inscricao,
       d.dt_envio + INTERVAL '2' DAY,
       d.tp_documento,
       'PENDENTE',
       'documentos/' || CAST(d.ce_inscricao AS varchar(20)) || '/2.pdf'
  FROM tbl_documento_comprovacao d
 WHERE d.status_documento = 'REJEITADO'
 ORDER BY d.ce_inscricao;

UPDATE tbl_documento_comprovacao d
   SET status_documento = 'APROVADO',
       dt_analise = d.dt_envio + INTERVAL '1' DAY,
       ce_pessoa_analise = (
           SELECT o.ce_pessoa
             FROM tbl_inscricao i
             JOIN tbl_preco p ON p.cp_id_preco = i.ce_preco
             JOIN tbl_categoria_inscricao c ON c.cp_id_categoria = p.ce_categoria
             JOIN tbl_organizacao_edicao o ON o.ce_edicao = c.ce_edicao AND o.tp_papel = 'COORD_GERAL'
            WHERE i.cp_id_inscricao = d.ce_inscricao
       )
 WHERE d.status_documento = 'PENDENTE'
   AND d.ds_caminho_arquivo LIKE '%/2.pdf';

UPDATE tbl_inscricao
   SET status_inscricao = 'AGUARDANDO_PAGAMENTO'
 WHERE status_inscricao = 'AGUARDANDO_VALIDACAO'
   AND cp_id_inscricao IN (
       SELECT ce_inscricao FROM tbl_documento_comprovacao WHERE status_documento = 'APROVADO'
 );

UPDATE tbl_inscricao
   SET status_inscricao = 'AGUARDANDO_PAGAMENTO'
 WHERE status_inscricao = 'INICIADA'
   AND MOD(cp_id_inscricao, 25) <> 0;
