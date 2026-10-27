# Malloyyo model template

Start a Malloy model repo that opens as a GitHub Codespace with Claude, the
`malloyyo` CLI and the Malloy extension already installed, and authors against
your Malloyyo instance.

## Workshop quickstart

1. **Create your repo:** open
   [this link](https://github.com/new?template_owner=shearwater-data&template_name=malloyyo-template)
   (or **Use this template** → **Create a new repository** on this page).
   Don't clone this repo: a clone still pushes to the template.
2. **Name it** `malloyyo-<usecase>`, lowercase with dashes, e.g.
   `malloyyo-retail-returns`. Pick your own account (or the workshop org, if
   you were told to).
3. **Get a Malloyyo token:** sign in to
   [shearwater.malloyyo.com](https://shearwater.malloyyo.com), go to
   [`/settings/tokens`](https://shearwater.malloyyo.com/settings/tokens) and
   create one with the `mcp` and `publish` scopes. Copy it now: it is shown
   only once.
4. **Open a codespace:** in your new repo, **Code → Codespaces → … → New with
   options**. Paste the token into the `MALLOYYO_TOKEN` field, leave the others
   empty, and **Create codespace**. The first start takes a few minutes.
5. **Start building:** in the codespace terminal run `claude` and describe your
   use case:

   > add a dataset for my use case from `<table>`, with an overview dashboard,
   > and remove the example dataset

`datasets/example/` is only there so the instance can register the repo. Leave
it until your own dataset exists, then delete it.

### If Claude says it can't use the instance

Instance previews need an author account and the repo registered on the
instance, which workshop accounts may not have. Work locally instead; the
result is the same, it just compiles inside the codespace:

- **BigQuery:** the facilitator sets `BIGQUERY_SHEARWATER_JSON` as an org
  Codespaces secret. If you created the codespace before that, rebuild it
  (**Codespaces: Rebuild Container** from the command palette). Check it
  arrived with `test -n "$BIGQUERY_SHEARWATER_JSON" && echo ok`.
- **No warehouse access:** use DuckDB on a CSV or Parquet file (a URL or a
  file in the repo). It needs no secret.

Then tell Claude to work locally, and check your work with:

```bash
malloyyo lint                                   # compile every dataset
malloyyo dashboard dev -C datasets/<name>       # preview on port 4173
```

The facilitator publishes finished datasets to the instance after the
workshop.

## Start a new model

1. **Use this template** → create the new repo.
2. Repo **Settings → Secrets and variables → Codespaces**, add:

   | Secret | Needed? | What |
   | --- | --- | --- |
   | `MALLOYYO_TOKEN` | **Yes** | `<instance>/settings/tokens`, scopes `mcp` + `publish` |
   | `MALLOYYO_URL` | No | Instance to use. Default `https://shearwater.malloyyo.com` |
   | `BIGQUERY_SHEARWATER_JSON` | No | Whole service-account JSON. Only for compiling inside the codespace |

   You can also set them once for the org or your user, and pick which repos
   get them.
3. Make sure the instance knows the repo (an admin adds it under **Add a
   repository**, or the first
   `malloyyo publish --repo <owner/name> --create-datasets`). The instance
   refuses a repo with no dataset directory, which is why the template ships
   `datasets/example/`: a tiny inline DuckDB table that compiles with no
   secrets. Replace it once you have a real dataset.
4. **Code → Codespaces → Create codespace**, then in the terminal:

   ```bash
   claude
   ```

   > add a `sales` dataset from the warehouse's orders table, with an overview dashboard

## How authoring works

**Default: the instance compiles.** Claude edits files here, sends them to
Malloyyo with `preview_changes`, and gets dashboard links and query results
back. The instance uses the warehouse credentials it already has, so the
codespace never holds them. Needs `REPO_AUTHORING=1` on the instance and an
author/admin account.

**Optional: compile here too.** With `BIGQUERY_SHEARWATER_JSON` set (or after
`gcloud auth application-default login --no-launch-browser`), the local tools
work as well:

```bash
malloyyo lint                                   # compile every dataset
malloyyo dashboard dev -C datasets/<name>       # preview on port 4173
```

DuckDB-only datasets work locally with no secret at all.

## Publish

Commit on a branch, open a PR, merge. Then either Claude calls `publish_repo`,
or:

```bash
malloyyo publish
```

Commit `.devcontainer/` before the first publish: that is what turns on the
codespace icon for the dataset in Malloyyo.

## What's in the repo

| Path | Purpose |
| --- | --- |
| `.devcontainer/devcontainer.json` | Prebuilt `malloyyo-devcontainer` image; asks for the secrets above |
| `.mcp.json` | `malloyyo_instance` (remote, default) and `malloyyo_author` (local) MCP servers |
| `.claude/` | Pre-approved tools, malloyyo skills |
| `CLAUDE.md` | Tells Claude to use instance previews first |
| `malloy-config.json` | `duckdb` + `bigquery` connections, secret by env name only |
| `malloy-config-local.json.example` | Laptop-only override with a key file path |
| `datasets/` | One directory per dataset; `example/` is a placeholder to replace |

## Adapting it

To point at another instance or warehouse, change the BigQuery `projectId`, the
env var name and the `prod` target in `malloy-config.json`. The env var name
must match one set on the Malloyyo server, because the instance resolves
`{ "env": … }` from its own environment. Then update the default URL in
`.mcp.json` and the secret names in `.devcontainer/devcontainer.json`.
