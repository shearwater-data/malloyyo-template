# Malloyyo model template

Start a Malloy model repo that opens as a GitHub Codespace with Claude, the
`malloyyo` CLI and the Malloy extension already installed. You connect your
database, build and check the model with Claude inside the codespace, and
merging to `main` publishes it to your Malloyyo instance.

## Workshop quickstart

1. **Create your repo:** open
   [this link](https://github.com/new?template_owner=shearwater-data&template_name=malloyyo-template)
   (or **Use this template** → **Create a new repository** on this page).
   Don't clone this repo: a clone still pushes to the template. Name it
   `malloyyo-<usecase>`, lowercase with plain dashes, e.g.
   `malloyyo-retail-returns`, under the workshop org (`shearwater-data`) unless
   told otherwise.
2. **Add it to Malloyyo** (an instance admin, or the facilitator for
   everyone):
   - On the instance, **Add a repository** → `<owner>/<repo>`, branch `main`.
     It works straight away because the template ships `datasets/example/`, a
     tiny placeholder dataset. A private repo also needs the instance to have
     GitHub access to it.
   - In the GitHub repo, add the **webhook** so every merge publishes:
     **Settings → Webhooks → Add webhook**, filled in as in
     [step 4 of the setup guide](#set-up-a-new-model-repo).
3. **Open a codespace:** on the instance, click the **codespace icon** next to
   the new dataset → **Create new codespace**. The first start takes a few
   minutes.
4. **Set your secrets:** GitHub → your avatar → **Settings → Codespaces →
   Codespaces secrets**:
   - `MALLOYYO_URL`: the instance's address (the facilitator gives it to you),
     e.g. `https://yourcompany.malloyyo.com`, with no trailing slash.
   - `MALLOYYO_TOKEN`: on the instance, go to `/settings/tokens` and create a
     token with the `mcp` and `publish` scopes. Copy it straight away: it is
     shown only once.
   - `BIGQUERY_SERVICE_ACCOUNT_JSON`: only if your data is in BigQuery. Paste
     the whole key file.

   For each one, under **Repository access**, pick your new repo. If you
   already have them from an earlier session, just add the repo to their
   access. Then **stop and restart the codespace** (or **Codespaces: Rebuild
   Container** from the command palette) so it picks them up. Check with
   `test -n "$MALLOYYO_TOKEN" && echo ok`.
5. **Build:** in the codespace terminal run `claude`, then
   `/connect-database`. Claude always asks where your data lives (BigQuery,
   another database, or files) and never picks one for you. Never paste a key
   or password into the chat. Then describe your use case:

   > add a dataset for my use case from `<table>`, with an overview dashboard,
   > and remove the example dataset
6. **Review:** check the model with `malloyyo lint` and see the dashboards with
   `malloyyo dashboard dev -C datasets/<name>`. When you're happy, Claude opens
   a pull request for your team to review.
7. **Publish:** merge the pull request and the webhook publishes it. The
   first time a new dataset appears, it has to be created once, which an
   instance admin does from the codespace:

   ```bash
   malloyyo publish -i "$MALLOYYO_URL" --repo <owner/repo> --create-datasets
   ```

   After that, every merge updates it on its own.

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
   | `BIGQUERY_SERVICE_ACCOUNT_JSON` | Only for BigQuery | The whole service-account key file |

   These are also asked for on **New with options** when the codespace is
   created. Other databases' secrets come from `/connect-database`.
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
so every env name in `malloy-config.json` must also be set on the Malloyyo
server under the same name: `BIGQUERY_SERVICE_ACCOUNT_JSON` for BigQuery. For a
name the instance doesn't have yet, ask its admin to add it.

If a publish fails with "Could not load the default credentials" followed by
many "no such field" errors, the config's env name isn't set on the server.

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
| `malloy-config.json` | `bigquery` reading `BIGQUERY_SERVICE_ACCOUNT_JSON`, and `duckdb` for the example only; Claude asks which to use, and adds more via `/connect-database` |
| `datasets/` | One directory per dataset; `example/` is a placeholder to replace |

## Adapting it

Nothing in the repo names an instance: Claude, the MCP connection and
`malloyyo publish -i` all read `MALLOYYO_URL`. To move a repo to another
instance, change that Codespaces secret and restart the codespace.
