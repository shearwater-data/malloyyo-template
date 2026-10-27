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

The Malloyyo instance is whatever `$MALLOYYO_URL` says; never assume a
particular one. Secrets are repo-level Codespaces secrets, added by hand in
the repo's GitHub page (**Settings → Secrets and variables → Codespaces → New
repository secret**); never set them with `gh` or another command. If
`MALLOYYO_URL` or `MALLOYYO_TOKEN` is empty, tell the person to add it there,
then stop and restart the codespace.

`malloyyo_instance` is that instance's own MCP server. Use it for
`yo_help` and to query what's already published. Its authoring tools
(`list_repos`, `preview_changes`, `list_tables`, …) are usually not offered;
that is expected, so don't look for them, don't report their absence, and
don't suggest turning them on.

## Publishing

- Publishing normally happens on its own: the repo's GitHub webhook tells the
  instance about each push to `main`, so merging the PR publishes it. If a merge
  didn't show up on the instance, the webhook step in the README's setup guide
  is probably missing.
- The first time a dataset appears, or to publish by hand:
  `malloyyo publish -i "$MALLOYYO_URL" --repo <owner/name> --create-datasets`,
  with `--dry-run` first to show the person what would be sent. The repo has
  no publish target in `malloy-config.json`, so always pass `-i`. Creating a
  dataset needs an instance admin.
- The CLI reads `MALLOYYO_TOKEN` from the environment, so it needs no sign-in.
  Don't run `malloyyo login` in a codespace: its browser callback goes to a
  `localhost` port the person's browser can't reach. If a login is
  unavoidable, use `malloyyo login "$MALLOYYO_URL" --no-browser`; when the
  browser lands on a dead `http://localhost:<port>/callback?…` page, ask for
  that URL and deliver it from inside the container with `curl -s "<url>"`.
