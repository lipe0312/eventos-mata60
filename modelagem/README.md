# Modelagem

MER na notação de Peter Chen, feito no brModelo (Regra 1).

## Versões

| Arquivo | Versão | Situação |
|---------|--------|----------|
| `conceitual/mer-conceitual-v1.pdf` | V1, primeira tentativa (34 entidades) | Histórico. Substituída após o feedback de escopo do professor |
| `conceitual/mer-conceitual-final.pdf` | Versão final, 20 entidades, 30 relacionamentos e todos os atributos | Atual. Atributos conferidos com as colunas do banco |
| `logico/` | Modelo lógico relacional | Pendente: completar, corrigir e exportar (ver `relatorio/README.md`) |

Da V1 para a versão final:
- o escopo caiu de 34 para 20 entidades: subtipos de pagamento, reembolso, políticas, regra de certificação, modalidade, sessão, credenciamento, histórico de status e usuário administrativo viraram atributos, relacionamentos ou foram absorvidos por Auditoria e Pessoa;
- as ligações, antes desenhadas como atributos `ce_*`, viraram relacionamentos (losangos) com cardinalidade, como exige a notação de Chen.

## Legenda de cores do diagrama

| Cor | Elemento | Itens |
|-----|----------|-------|
| Azul | Entidade forte | Pessoa, Evento, Instituição, Inscrição, Termo, Certificado, Auditoria |
| Amarelo | Entidade fraca | Edição, Categoria de Inscrição, Faixa de Inscrição, Atividade, Trabalho Científico, Período de Associação, Benefício, Documento de Comprovação, Pagamento, Item Financeiro |
| Rosa | Entidade associativa | Preço, Vínculo Institucional, Inscrição em Atividade |
| Verde | Autorrelacionamento | Agrega (Edição agregadora × edições agregadas) |
| Branco | Relacionamento | Demais losangos |

A cor só facilita a leitura. O tipo de cada entidade também está marcado no brModelo: propriedade *Fraco*, opção *Entidade associativa* e *Auto relacionamento*.

## Leitura das cardinalidades

O par (mín, máx) anotado junto a uma entidade diz quantas instâncias dela se ligam a **uma** instância da entidade do outro lado do losango. Exemplo: em Evento —(1,1)— Realiza —(1,n)— Edição, cada edição pertence a exatamente um evento, e cada evento realiza uma ou mais edições.
