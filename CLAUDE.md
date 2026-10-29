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

## Where this runs

Usually Claude Code on the web, in the team's shared cloud environment for the
instance (see `docs/team-setup.md`); a codespace or a laptop also work. The
SessionStart hook installs the `malloyyo` CLI if it's missing and prints a
"Malloyyo session status" block. If someone is new or something is missing,
use the `start` skill.

The Malloyyo instance is whatever `$MALLOYYO_URL` says; never assume a
particular one, and use its name when talking to the person (george, in
examples here). Reach it through:

- **the instance's claude.ai connector** (in a cloud session; each person
  connects it once with their own account), or
- **`malloyyo_instance`** from `.mcp.json`, when `MALLOYYO_TOKEN` is set (a
  codespace, or a laptop). Without a token it shows as needing
  authentication; ignore that and use the connector.

Use whichever is connected; they're the same server.

## How models are built here

Two ways; prefer the first when it's available.

1. **Preview on the instance.** If the instance's tools include
   `preview_changes`, `list_repos` and `check_repo` (instance admins get them),
   follow `yo_help("authoring/start")`: explore with `list_tables` /
   `describe_table`, edit files here, and `preview_changes` compiles them with
   the **instance's own** warehouse connections and returns real numbers and
   dashboard links. No warehouse credentials are needed in this session.
2. **Locally**, with the `malloyyo_author` server (`compile_file`, `query`),
   `malloyyo sql`, `malloyyo lint` and `malloyyo dashboard dev`, using the
   shared read-only key the team environment provides (the same one the
   instance uses). For other databases, `connect-database`.

Questions about published data always go through the instance (`query`,
`describe_source`), never straight to the warehouse. Only use the
`google-login` skill (personal Google access to BigQuery) when the person asks
for it, or when there's no shared key and they can't wait for one.

Either way:

- **Never assume a connection.** Before exploring or writing any source, ask
  the person where their data lives, even when the request names a table.
  Offer the connections in `malloy-config.json` that aren't placeholders, plus
  "another database" and "files (CSV / Parquet)". Only then use it.
  - `bigquery` reads `BIGQUERY_SERVICE_ACCOUNT_JSON`, the shared key, here
    and on the instance; keep that env name. Only a personal Google sign-in
    uses `malloy-config-local.json` instead.
  - `duckdb` is there only for `datasets/example/`. It is not a default; don't
    pick it unless the person says their data is in files or DuckDB.
  - For another database, or when a source fails with "No connection named …",
    use the `connect-database` skill.
- Explore the data, ask what the model should answer, then write
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
- Charts: `yo_help("explore/charting-results")` and `dashboards/charts`.
- `malloy-gotchas-modeling` and `malloy-queries` are open-source Malloy skills
  (`docs/malloy-skills.md`) for compile errors and query habits. Where they
  differ from this file or `yo_help`, this file and `yo_help` win.

## Secrets

Never ask for, accept or print a secret. The one exception is the single-use
code Google shows during the optional `google-login`, which the person pastes
back.

- **Cloud sessions:** environment variables live on the team's cloud
  environment, which someone with the claude.ai Owner role manages. A missing
  one goes to them (`docs/team-setup.md`), not into chat.
- **Codespaces:** repo-level Codespaces secrets, added by hand in the repo's
  GitHub page (**Settings → Secrets and variables → Codespaces → New
  repository secret**); never set them with `gh` or another command. Restart
  the codespace after adding one.
- **Laptop:** `read -rs NAME && export NAME` in the terminal, then restart
  Claude.

## Sharing with colleagues

The repo is the shared source; a merge publishes it to the instance, which is
the shared live data. For results, charts and dashboards use the `share`
skill: a Claude artifact with live data from the instance for quick sharing, a
draft dashboard on the instance for a live page with a link, and Malloy in the
repo (named views, dashboards) for anything people will ask again.

## Publishing

- After the PR is merged, the instance picks it up through the repo's GitHub
  webhook, or when someone clicks **Refresh from GitHub** on the repo's page on
  the instance. If a merge didn't show up, the webhook is probably missing
  (`docs/team-setup.md`).
- A **new** dataset has to be created once, by an instance admin: **Refresh and
  create missing datasets** on the repo's page, or
  `malloyyo publish -i "$MALLOYYO_URL" --repo <owner/name> --create-datasets`
  (run `--dry-run` first and show the person what would be sent; the repo has
  no publish target in `malloy-config.json`, so always pass `-i`).
- The CLI reads `MALLOYYO_TOKEN` from the environment. `malloyyo login` is for
  laptops only; never run it in a codespace or cloud session.
