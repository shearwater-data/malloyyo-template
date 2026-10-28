# Malloy model repo

A repo publishes one dataset per directory under `datasets/`, and publishes as a
unit. Connections live in `malloy-config.json`; secrets are only ever
`{ "env": … }` references, and never pasted into chat or files.

The person you're working with may not be a developer. Explain in plain
language, say what each step is for, and give commands they need to run as
copy-paste blocks.

`datasets/example/` is a placeholder that exists only so the instance accepts
the repo (it refuses one with no dataset directory). Once the first real
dataset compiles, delete it.

## How models are built here

Everything is built and checked **in this container**, with the local
`malloyyo_author` server (`compile_file`, `query`), `malloyyo sql`,
`malloyyo lint` and `malloyyo dashboard dev`. That is the intended workflow,
not a fallback.

- **Never assume a connection.** Before exploring or writing any source, ask
  the person where their data lives, even when the request names a table.
  Offer the connections in `malloy-config.json` that aren't placeholders, plus
  "another database" and "files (CSV / Parquet)". Only then use it.
  - `bigquery` reads `BIGQUERY_SERVICE_ACCOUNT_JSON`; keep that env name, the
    instance uses the same.
  - `duckdb` is there only for `datasets/example/`. It is not a default; don't
    pick it unless the person says their data is in files or DuckDB.
  - For another database, or when a source fails with "No connection named …",
    use the `connect-database` skill.
- Before modelling, check the chosen connection's secrets are set: for each
  `{ "env": NAME }` it uses, `test -n "$NAME"` (never print the value). If one
  is missing, `connect-database` covers how to set it.
- Explore the data with `malloyyo sql <connection> -e "…"` against the
  database's information schema, ask what the model should answer, then write
  `datasets/<name>/`, compile, and check the numbers with real queries.
- Commit on a branch and open a PR. Never publish or merge without asking.

Writing a dataset (`yo_help("repo/datasets")` has the details):

- The directory name is the dataset's name and identity: a short lowercase
  slug, e.g. `datasets/sales/`.
- At the top of its `index.malloy`, `##" What this dataset is.` and
  `## dataset { title="…" }`. Two hashes: a single `#"` documents the next
  source instead.
- Give every exported source a one-sentence `#"` and `#(agent)` lines on how to
  query it, and each measure a `#"`. People and Claude read these in
  `describe_source`.

The Malloyyo instance is whatever `$MALLOYYO_URL` says; never assume a
particular one. Secrets are repo-level Codespaces secrets, added by hand in
the repo's GitHub page (**Settings → Secrets and variables → Codespaces → New
repository secret**); never set them with `gh` or another command. If
`MALLOYYO_URL` or `MALLOYYO_TOKEN` is empty, tell the person to add it there,
then stop and restart the codespace.

`malloyyo_instance` is that instance's MCP server: use it for `yo_help` and to
query what's already published, nothing else.

## Publishing

- After the PR is merged, the instance picks it up through the repo's GitHub
  webhook, or when someone clicks **Refresh from GitHub** on the repo's page on
  the instance. If a merge didn't show up, the webhook (README step 3) is
  probably missing.
- A **new** dataset has to be created once, by an instance admin: **Refresh and
  create missing datasets** on the repo's page, or
  `malloyyo publish -i "$MALLOYYO_URL" --repo <owner/name> --create-datasets`
  (run `--dry-run` first and show the person what would be sent; the repo has
  no publish target in `malloy-config.json`, so always pass `-i`).
- The CLI reads `MALLOYYO_TOKEN` from the environment; never run
  `malloyyo login` in a codespace.
