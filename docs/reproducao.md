# Reprodução

Stack: PostgreSQL e pgAdmin (Regra 5). O Docker é apenas uma forma de subir essa stack.

## Com Docker

```bash
git clone <url-do-repositorio>
cd eventos-mata60
cp .env.example .env          # opcional
docker compose up -d
```

- O PostgreSQL executa `sql/main.sql` na primeira inicialização.
- pgAdmin: http://localhost:5050 (credenciais em `.env.example`). Registrar o servidor com host `postgres`, porta `5432`.
- Recriar do zero: `docker compose down -v && docker compose up -d`.

## Sem Docker

Em um PostgreSQL 16 local, a partir da raiz do repositório:

```bash
createdb eventos
psql -d eventos -f sql/main.sql
```

## Testes e metadados

Após a carga:

```bash
docker compose exec postgres psql -U eventos -d eventos -f /sql/99_testes/01_restricoes.sql
docker compose exec postgres psql -U eventos -d eventos -f /sql/05_metadados/01_metadados.sql
```

Pelo pgAdmin, os mesmos arquivos podem ser abertos no Query Tool. O banco já usa o schema `eventos` como padrão.
