# EventOS · MATA60 Bancos de Dados (UFBA, 2026.2)

Banco de dados do EventOS, sistema de gestão de eventos científicos da SBTC (Caso 1), em PostgreSQL.

## Estrutura

| Pasta | Conteúdo |
|-------|----------|
| `modelagem/` | MER conceitual (Peter Chen, brModelo) e modelo lógico, por versão |
| `sql/` | Implantação: schema, DDL, restrições, população, visões, metadados e testes. `sql/main.sql` executa tudo na ordem |
| `marco2/` | Consultas, otimizações e benchmark do Marco 2 |
| `relatorio/` | Relatórios no modelo SBC, com versões e a versão final dividida por seção |
| `docs/` | Tutorial de reprodução |
| `docker/` | Ponto de entrada do container PostgreSQL |

## Como reproduzir

```bash
docker compose up -d
```

Detalhes em [`docs/reproducao.md`](docs/reproducao.md).

## Situação

| Marco | Entrega | Status |
|-------|---------|--------|
| 1 · MIBD | Extensão, MER, DDL, população | em andamento |
| 2 · OCRA | Normalização, 50 consultas, otimização | não iniciado |

## Regras atendidas

- SQL ISO/IEC 9075; exceções do PostgreSQL justificadas no relatório.
- Reprodução apenas com PostgreSQL e pgAdmin.
- Nenhuma linguagem de propósito geral acessa o banco.
