---
name: connect-database
description: Connect this model repo to a database (BigQuery, MotherDuck, Postgres, Snowflake, Databricks, MySQL, Trino, Presto, or DuckDB files) from inside a codespace. Use when someone wants to model data that isn't in the repo, asks to "connect to" or "set up" a warehouse, or a source fails with "No connection named …". Writes the connection into malloy-config.json with secrets as env references only, and walks the user through setting those secrets as Codespaces secrets without ever pasting them into chat.
---

# Connect a database

The connection goes in `malloy-config.json` at the repo root. That exact file is
published, and the Malloyyo instance resolves it against **its own**
environment, so every secret must be an `{ "env": "NAME" }` reference and the
same name must work in both places.

**Never ask for, accept, echo or write a secret value.** Not in chat, not in a
file, not in a command. If the user pastes one, tell them to rotate it. Secrets
reach this environment only as Codespaces secrets or a shell `read -s`.

## 1. Ask what they're connecting to

Ask for the database type and the non-secret details: project or account,
database, schema, host. Don't guess them. If they don't know, stop and say who
usually does (whoever owns the warehouse).

## 2. Write the connection

Read `yo_help("connection-setup")` and the per-connector properties at
<https://docs.malloydata.dev/documentation/setup/config> before writing; don't
write property names from memory.

- Add the connection beside the existing `duckdb` one; don't remove that one
  while `datasets/example/` still uses it.
- Name it after what it is (`bigquery`, `motherduck`, `analytics_pg`), and use
  that name in sources: `source: x is motherduck.table('…')`.
- Secrets as `{ "env": "NAME" }`. Use an UPPER_SNAKE name that says what it is
  and whose it is, e.g. `BIGQUERY_ANALYTICS_JSON`, `MOTHERDUCK_TOKEN`,
  `ANALYTICS_PG_PASSWORD`. If this connection will be published to an
  instance that already has the database, ask the admin which env name the
  server uses and use that one.

Common shapes (check the docs for the rest):

| Database | Connection | Secret |
| --- | --- | --- |
| BigQuery | `"is": "bigquery"`, `"projectId"`, `"serviceAccountKeyJson": { "env": … }` | the whole service-account JSON, minified |
| MotherDuck | `"is": "duckdb"`, `"databasePath": "md:<database>"` | `MOTHERDUCK_TOKEN` (read by DuckDB itself; no property needed) |
| Postgres | `"is": "postgres"`, host / port / database / username, `"password": { "env": … }` | the password |
| Snowflake, Databricks, … | see the docs | per connector |

BigQuery has a no-secret option for working in the codespace only: run
`gcloud auth application-default login --no-launch-browser` in the terminal and
drop `serviceAccountKeyJson`. The instance still needs its own credential to
publish.

## 3. Get the secret into the codespace

Give the user both options, in this order, and tell them which env names to use.

**To use it right now** (lasts until the codespace stops). In the terminal
outside Claude, then restart Claude so the MCP server picks it up:

```bash
read -rs NAME && export NAME
claude
```

`read -s` keeps the value off the screen and out of shell history. Repeat for
each name.

**To keep it** (every codespace for this repo): GitHub → their avatar →
**Settings → Codespaces → Secrets → New secret**, name `NAME`, and grant it to
this repo. Then stop and restart the codespace (or **Codespaces: Rebuild
Container**). For a workshop, an org admin can set it once at the org level.

Check it arrived without printing it: `test -n "$NAME" && echo set`.

## 4. Prove the connection before modelling

Compile a probe against the new connection and run it:

```malloy
source: _probe is <connection>.sql("SELECT 1 AS one")
run: _probe -> { select: one }
```

If it fails, fix the connection first: a broken connection empties the schema
and every later error (`field-not-found` …) is noise. Then list a few tables to
confirm the user can see what they expect.

## 5. The instance side

Building and checking the model now works here. For the published model to
query the database, the Malloyyo server needs the same env name set in **its**
environment. If the instance doesn't already have this database, that's an
admin change: tell the user which name to ask for before they publish.
