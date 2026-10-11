# EventOS · MATA60 Bancos de Dados (UFBA, 2026.2)

Banco de dados do EventOS, sistema de gestão de eventos científicos da SBTC (Caso 1), em PostgreSQL.

## Estrutura

| Pasta | Conteúdo |
|-------|----------|
| `modelagem/` | MER conceitual (Peter Chen, brModelo), legenda de cores e modelo lógico, por versão |
| `sql/` | Implantação do Marco 1. `sql/main.sql` executa tudo na ordem |
| `marco2/` | Consultas, otimizações e benchmark do Marco 2 |
| `relatorio/` | Relatórios no modelo SBC, com versões e a versão final dividida por seção |
| `docs/` | Tutorial de reprodução detalhado |
| `docker/` | Ponto de entrada opcional para subir PostgreSQL e pgAdmin em containers |

## Marco 1 · o que está no banco

| Etapa | Arquivo(s) | Resultado |
|-------|------------|-----------|
| Schema | `sql/00_init.sql` | schema `eventos`, definido como padrão do banco |
| Tabelas | `sql/01_ddl/` | 24 tabelas: 20 entidades do MER e 4 relacionamentos N:N |
| Regras de negócio | `sql/02_constraints/` | CHECKs, triggers (ciclo da inscrição, pagamentos, vagas, benefícios, publicação, certificados, histórico, cardinalidades mínimas, auditoria) e 2 procedimentos |
| População | `sql/03_populacao/` | dados sintéticos; 7 tabelas com mais de 5.000 linhas |
| Visões e acesso | `sql/04_views/` | 12 relatórios do RF26, atributos derivados, visão mascarada e 5 papéis |
| Metadados | `sql/05_metadados/` | exploração do `information_schema` (execução manual) |
| Testes | `sql/99_testes/` | 73 casos de restrições e regras (execução manual, sem alterar dados) |

## Como executar

Requisitos: **PostgreSQL 14 ou superior** e `psql` (ou o *PSQL Tool* do pgAdmin). Não usa nenhuma extensão: só o PL/pgSQL, que já vem instalado em todo PostgreSQL. O usuário precisa poder criar banco e papéis; o superusuário `postgres` atende.

### Opção 1 · PostgreSQL nativo (linha de comando)

Na raiz do repositório:

```bash
createdb -U postgres -E UTF8 -T template0 eventos
psql -U postgres -d eventos -f sql/main.sql
```

Leva cerca de 30 segundos. Para conferir:

```bash
psql -U postgres -d eventos -f sql/99_testes/01_restricoes.sql
psql -U postgres -d eventos -f sql/05_metadados/01_metadados.sql
```

A última linha dos testes deve mostrar `73 | 73 | 0` (casos, OK, falhas).

Para recriar do zero: `dropdb -U postgres eventos` e repetir os passos.

No Windows, os mesmos comandos funcionam no *SQL Shell (psql)* ou no Prompt, trocando `/` por `\` nos caminhos.

### Opção 2 · apenas pgAdmin

1. Criar o banco `eventos` (aba *Definition*: Encoding `UTF8`, Template `template0`).
2. Clicar com o botão direito no banco e abrir o **PSQL Tool**. O *Query Tool* não executa os comandos `\ir` do script principal.
3. Executar `\i '/caminho/para/eventos-mata60/sql/main.sql'`.
4. Executar os testes da mesma forma: `\i '/caminho/para/eventos-mata60/sql/99_testes/01_restricoes.sql'`.

### Opção 3 · Docker (opcional)

```bash
docker compose up -d
```

Sobe PostgreSQL 16 e pgAdmin (http://localhost:5050) e executa `sql/main.sql` na primeira inicialização. Detalhes em [`docs/reproducao.md`](docs/reproducao.md).

## Situação

| Marco | Entrega | Status |
|-------|---------|--------|
| 1 · MIBD | DDL, regras, população, visões, metadados e testes | concluído |
| 1 · MIBD | Exportação final do MER, modelo lógico e relatório SBC | em produção |
| 2 · OCRA | Normalização, 50 consultas, otimização | não iniciado |

## Regras atendidas

- SQL ISO/IEC 9075 na DDL, na população e nas visões. Recursos específicos do PostgreSQL (triggers em PL/pgSQL, `SELECT … FOR UPDATE`, `current_setting`, papéis) estão justificados no relatório.
- Reprodução apenas com PostgreSQL e pgAdmin; o Docker é opcional.
- Nenhuma linguagem de propósito geral acessa o banco.
