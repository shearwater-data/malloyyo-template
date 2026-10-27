# Malloyyo model template

Start a Malloy model repo that opens as a GitHub Codespace with Claude, the
`malloyyo` CLI and the Malloy extension already installed. You connect your
database, build and check the model with Claude inside the codespace, and
merging to `main` publishes it to your Malloyyo instance.

## Workshop quickstart

1. **Create your repo:** open
   [this link](https://github.com/new?template_owner=shearwater-data&template_name=malloyyo-template)
   (or **Use this template** → **Create a new repository** on this page).
   Don't clone this repo: a clone still pushes to the template.
2. **Name it** `malloyyo-<usecase>`, lowercase with dashes, e.g.
   `malloyyo-retail-returns`. Pick your own account (or the workshop org, if
   you were told to).
3. **Get a Malloyyo token:** sign in to your Malloyyo instance (the
   facilitator gives you its address, e.g. `https://yourcompany.malloyyo.com`),
   go to `/settings/tokens` on it and create a token with the `mcp` and
   `publish` scopes. Copy it now: it is shown only once.
4. **Open a codespace:** in your new repo, **Code → Codespaces → … → New with
   options**. Fill in:
   - `MALLOYYO_URL`: the instance's address, with no trailing slash.
   - `MALLOYYO_TOKEN`: the token from step 3.

   Then **Create codespace**. The first start takes a few minutes.
5. **Connect your data:** in the codespace terminal run `claude`, then
   `/connect-database`. Claude asks which database, writes the connection, and
   tells you which secrets to set and where. Never paste a key or password into
   the chat. For a workshop, the facilitator may have set shared read-only
   secrets for everyone already. Data in a CSV or Parquet file needs no
   connection at all.
6. **Build:** describe your use case:

   > add a dataset for my use case from `<table>`, with an overview dashboard,
   > and remove the example dataset

   Check the result with `malloyyo lint` and see dashboards with
   `malloyyo dashboard dev -C datasets/<name>`. Claude opens a pull request
   when you're happy with it.

`datasets/example/` is only there so the instance can register the repo. Leave
it until your own dataset exists, then delete it.

## Set up a new model repo

1. **Use this template** → create the new repo.
2. **Codespaces secrets:** repo **Settings → Secrets and variables →
   Codespaces** (or once for your user or the org):

   | Secret | Needed? | What |
   | --- | --- | --- |
   | `MALLOYYO_TOKEN` | **Yes** | `<instance>/settings/tokens`, scopes `mcp` + `publish` |
   | `MALLOYYO_URL` | **Yes** | Your instance's address, e.g. `https://yourcompany.malloyyo.com`, no trailing slash |

   Database secrets come later, from `/connect-database`.
3. **Add the repo to Malloyyo:** an instance admin opens **Add a repository**
   on the instance and enters `<owner>/<name>` and branch `main`. The instance
   refuses a repo with no dataset directory, which is why the template ships
   `datasets/example/`: a tiny inline DuckDB table that compiles with no
   secrets.
4. **Publish on merge (GitHub webhook):** in the GitHub repo, **Settings →
   Webhooks → Add webhook**:

   | Field | Value |
   | --- | --- |
   | Payload URL | The webhook URL Malloyyo shows for this repo, of the form `https://<instance>/api/datasets/<id>/webhook/github` |
   | Content type | `application/json` |
   | Secret | The instance's `GITHUB_WEBHOOK_SECRET`, if it has one (ask its admin); otherwise empty |
   | Events | **Just the push event**, and **Active** ticked |

   From then on every push to `main`, which includes every merged pull
   request, refreshes the published model. GitHub's **Recent Deliveries** tab
   on the webhook shows whether each one got through.
5. **Code → Codespaces → Create codespace**, run `claude`, and start with
   `/connect-database`.

## How building works

Everything is built and checked in the codespace:

1. `/connect-database` adds the connection to `malloy-config.json`, with
   secrets as `{ "env": … }` names only, and walks you through setting them:
   `read -s` in the terminal for this session, or a Codespaces secret (GitHub →
   Settings → Codespaces) to keep them.
2. Claude explores the tables, asks what the model should answer, writes
   `datasets/<name>/`, and checks the numbers with real queries.
3. You check it too:

   ```bash
   malloyyo lint                                   # compile every dataset
   malloyyo dashboard dev -C datasets/<name>       # preview on port 4173
   ```

4. Claude commits on a branch and opens a pull request.

## Publish

Merge the pull request. The webhook from step 4 of the setup publishes it.

The **first** time a new dataset appears it has to be created, which an
instance admin does once by hand from the codespace (the CLI uses
`MALLOYYO_TOKEN`, so no sign-in is needed):

```bash
malloyyo publish -i "$MALLOYYO_URL" --repo <owner/name> --create-datasets --dry-run   # check first
malloyyo publish -i "$MALLOYYO_URL" --repo <owner/name> --create-datasets
```

The published model queries the database with the **instance's** credentials,
so the env names in `malloy-config.json` must also be set on the Malloyyo
server. For a database the instance doesn't have yet, ask its admin.

Commit `.devcontainer/` before the first publish: that is what turns on the
codespace icon for the dataset in Malloyyo.

### Signing in from a codespace

You shouldn't need to: `MALLOYYO_TOKEN` covers the CLI. If you do run
`malloyyo login "$MALLOYYO_URL"`, add `--no-browser`. After you sign in, your browser lands on
a page that won't load (`http://localhost:…/callback?…`), because that address
only exists inside the codespace. Copy that URL from the address bar and paste
it to Claude; it finishes the sign-in from inside the codespace. Do it quickly,
because the code expires in a few minutes.

## What's in the repo

| Path | Purpose |
| --- | --- |
| `.devcontainer/devcontainer.json` | Prebuilt `malloyyo-devcontainer` image; asks for the secrets above |
| `.mcp.json` | `malloyyo_author` (local build tools) and `malloyyo_instance` (the instance's help and published models) MCP servers |
| `.claude/` | Pre-approved tools, malloyyo skills, and `connect-database` |
| `CLAUDE.md` | How Claude builds here, how publishing works, and to explain in plain language |
| `malloy-config.json` | A `duckdb` connection; more via `/connect-database` |
| `datasets/` | One directory per dataset; `example/` is a placeholder to replace |

## Adapting it

Nothing in the repo names an instance: Claude, the MCP connection and
`malloyyo publish -i` all read `MALLOYYO_URL`. To move a repo to another
instance, change that Codespaces secret and restart the codespace.
