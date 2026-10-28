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

Always ask; never default to a connection, `duckdb` included, even if it's
already in `malloy-config.json` (it exists only for the example placeholder).
Ask for the database type and the non-secret details: project or account,
database, schema, host. Don't guess them. If they don't know, stop and say who
usually does (whoever owns the warehouse).

The published model reads the credential from the **instance's** environment
under the same env name as here, so the instance must have it set under that
name too. A missing name builds fine here and then fails on the instance with
"Could not load the default credentials" plus a cascade of "no such field"
errors. Tell the person which name the admin needs to have on the instance.

## 2. Write the connection

Read `yo_help("connection-setup")` and the per-connector properties at
<https://docs.malloydata.dev/documentation/setup/config> before writing; don't
write property names from memory.

- **BigQuery is already set up.** The template ships a `bigquery` connection
  (project `shearwaterdata-dev-1`) that reads `BIGQUERY_SERVICE_ACCOUNT_JSON`,
  the key the codespace's create page asks for. Don't rename that env name. If
  `test -n "$BIGQUERY_SERVICE_ACCOUNT_JSON"` passes, skip step 3. If the data
  is in another project, change only `projectId`; the key's own project is
  `echo "$BIGQUERY_SERVICE_ACCOUNT_JSON" | jq -r .project_id` (prints only
  that field).
- For any other database, add the connection beside `duckdb` and `bigquery`
  (don't remove `duckdb` while `datasets/example/` uses it). Name it after
  what it is (`motherduck`, `analytics_pg`) and use that name in sources:
  `source: x is motherduck.table('…')`.
- Secrets as `{ "env": "NAME" }`, UPPER_SNAKE, saying what and whose, e.g.
  `MOTHERDUCK_TOKEN`, `ANALYTICS_PG_PASSWORD`.

Common shapes (check the docs for the rest):

| Database | Connection | Secret |
| --- | --- | --- |
| BigQuery | `"is": "bigquery"`, `"projectId"`, `"serviceAccountKeyJson": { "env": … }` | the whole service-account JSON, minified |
| MotherDuck | `"is": "duckdb"`, `"databasePath": "md:<database>"` | `MOTHERDUCK_TOKEN` (read by DuckDB itself; no property needed) |
| Postgres | `"is": "postgres"`, host / port / database / username, `"password": { "env": … }` | the password |
| Snowflake, Databricks, … | see the docs | per connector |

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

**To keep it** (every codespace for this repo): a repo secret, added by hand
in the repo's GitHub page: **Settings → Secrets and variables → Codespaces →
New repository secret**, name `NAME`. It needs admin on the repo. Then stop
and restart the codespace (or **Codespaces: Rebuild Container**). Don't set
secrets with `gh` or any other command; the person adds them in GitHub.

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
query the database, the Malloyyo server needs every env name from
`malloy-config.json` set in **its** environment, under exactly the same name.
That's an admin change: tell the person which names to ask for before they
publish.
