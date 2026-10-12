# Reprodução

Stack exigida: PostgreSQL e pgAdmin (Regra 5). Versão mínima: PostgreSQL 14, por causa dos procedimentos com corpo `BEGIN ATOMIC`. Testado em PostgreSQL 14 e 16.

Nenhuma extensão é necessária. A única linguagem procedural usada é o PL/pgSQL, instalado por padrão.

## 1. PostgreSQL nativo

A partir da raiz do repositório:

```bash
createdb -U postgres -E UTF8 -T template0 eventos
psql -U postgres -d eventos -f sql/main.sql
```

- `sql/main.sql` interrompe na primeira falha (`ON_ERROR_STOP`) e inclui os demais arquivos com caminho relativo (`\ir`). Por isso pode ser executado de qualquer pasta.
- Os objetos ficam no schema `eventos`. Para consultar sem prefixo, comece a sessão com `SET SCHEMA 'eventos';`.
- Os papéis (`papel_admin`, `papel_financeiro`, `papel_credenciamento`, `papel_organizacao`, `papel_relatorio`) são criados no servidor. Como papéis não pertencem a um banco, `dropdb` não os remove.

Recriar do zero:

```bash
dropdb -U postgres eventos
psql -U postgres -c "DROP ROLE papel_admin, papel_financeiro, papel_credenciamento, papel_organizacao, papel_relatorio"
createdb -U postgres -E UTF8 -T template0 eventos
psql -U postgres -d eventos -f sql/main.sql
```

## 2. pgAdmin

1. *Servers → Databases → Create → Database*: nome `eventos`. Na aba *Definition*, Encoding `UTF8` e Template `template0`.
2. Botão direito em `eventos` → **PSQL Tool**.
3. `\i '/caminho/para/eventos-mata60/sql/main.sql'`

O *Query Tool* não interpreta comandos do psql (`\ir`, `\set`). Para usá-lo, abra e execute os arquivos na ordem listada em `sql/main.sql`.

## 3. Docker (opcional)

```bash
cp .env.example .env          # opcional
docker compose up -d
```

- O PostgreSQL executa `sql/main.sql` na primeira inicialização (cerca de 35 segundos).
- pgAdmin: http://localhost:5050 (credenciais em `.env.example`). Registrar o servidor com host `postgres`, porta `5432`, usuário e senha `eventos`.
- Recriar do zero: `docker compose down -v && docker compose up -d`.

## 4. Testes e metadados

```bash
psql -U postgres -d eventos -f sql/99_testes/01_restricoes.sql
psql -U postgres -d eventos -f sql/05_metadados/01_metadados.sql
```

No Docker, prefixe com `docker compose exec postgres` e use os caminhos `/sql/...` com o usuário `eventos`.

O arquivo de testes roda dentro de uma transação desfeita ao final (`ROLLBACK`). Ele lista cada caso como `OK` ou `FALHA` e termina com o total. O esperado é `73 | 73 | 0`.
