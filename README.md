# Malloyyo model template

A starting point for a Malloy model repo that opens as a GitHub Codespace with
Claude Code, the `malloyyo` CLI and the Malloy extension already installed. You
connect your database, build the model with Claude inside the codespace, and
publish it to your Malloyyo instance.

## Set up

### 1. Create the repo

On this page, **Use this template → Create a new repository**. Don't clone the
template: a clone still pushes to it. A name like `malloyyo-<usecase>`,
lowercase with plain dashes, keeps model repos easy to find.

### 2. Give Malloyyo a GitHub token (private repos)

Malloyyo reads the model from GitHub, so for a private repo the instance needs
a token that can read it. It's one token for the whole instance, so if it's
already set, skip this step.

1. GitHub → your avatar → **Settings → Developer settings → Personal access
   tokens → Fine-grained tokens → Generate new token**.
2. **Token name**: e.g. `malloyyo <instance>`. **Expiration**: your choice;
   when it expires, private repos stop refreshing until it's replaced.
3. **Resource owner**: the account or organization that owns your model repos.
   An organization may need to approve the token before it works.
4. **Repository access**: **All repositories**, so new model repos work without
   editing the token, or **Only select repositories** if you prefer to list
   them.
5. **Permissions → Repository permissions → Contents: Read-only**. GitHub adds
   Metadata: Read-only on its own. Nothing else is needed.
6. **Generate token** and copy it (it starts with `github_pat_`).
7. Have the instance's admin set it as the instance's `GITHUB_TOKEN`. On a
   Malloyyo-hosted instance that's
   `malloyyo cloud secrets set GITHUB_TOKEN -i <instance>`; on a self-hosted
   one, it's an environment variable of the server.

### 3. Add the repo to Malloyyo

On the instance, **Add a repository** → `<owner>/<repo>`, branch `main`. This
needs an instance admin. It works straight away because the template ships
`datasets/example/`, a tiny placeholder dataset; delete it once your own
dataset exists.

To have every merge to `main` publish on its own, open the repo's page on the
instance, copy the **webhook payload URL** shown there
(`https://<instance>/api/repos/<id>/webhook/github`), and in the GitHub repo add
it under **Settings → Webhooks → Add webhook**: content type
`application/json`, **Just the push event**, **Active**. If the instance has a
`GITHUB_WEBHOOK_SECRET`, put the same value in the **Secret** field.

### 4. Add the repo secrets

In the GitHub repo, **Settings → Secrets and variables → Codespaces → New
repository secret**, once for each:

| Secret | Needed? | Value |
| --- | --- | --- |
| `MALLOYYO_URL` | Yes | The instance's address, e.g. `https://yourcompany.malloyyo.com`, no trailing slash |
| `MALLOYYO_TOKEN` | Yes | A token from `<instance>/settings/tokens` with the `mcp` and `publish` scopes. Copy it when it's created: it's shown only once |
| `BIGQUERY_SERVICE_ACCOUNT_JSON` | Only for BigQuery | The whole service-account key file |

Every codespace on the repo gets them, so add them before opening one; a
running codespace picks up changes after a stop and restart. They're shared by
everyone who uses the repo, so `MALLOYYO_TOKEN` acts as whoever created it.

### 5. Open a codespace

On the instance, click the **codespace icon** next to the dataset → **Create
new codespace** (or, in GitHub, **Code → Codespaces**). The first start takes a
few minutes.

### 6. Build

In the codespace terminal, run `claude` and describe what you want:

> add a dataset for my use case from `<table>`, with an overview dashboard,
> and remove the example dataset

Claude always asks where your data lives before it starts. For a database
other than BigQuery, `/connect-database` adds the connection and tells you which
secret to add. Never paste a key or password into the chat.

### 7. Review and open a pull request

Claude checks the numbers with real queries and shows you the results. To see
the dashboards yourself, run `malloyyo dashboard dev -C datasets/<name>` and
open the forwarded port 4173. When you're happy, Claude opens a pull request
for review.

### 8. Publish

Merge the pull request, then:

- **A new dataset** has to be created once, by an instance admin: on the repo's
  page on the instance, **Refresh and create missing datasets**. From the
  codespace, the same thing is
  `malloyyo publish -i "$MALLOYYO_URL" --repo <owner/repo> --create-datasets`.
- **After that**, each merge publishes through the webhook from step 3, or
  click **Refresh from GitHub** on the repo's page.

The published model reads the database with the **instance's** credentials, so
every env name in `malloy-config.json` (such as `BIGQUERY_SERVICE_ACCOUNT_JSON`)
must also be set on the instance under the same name. If publishing fails with
"Could not load the default credentials" followed by many "no such field"
errors, that name is missing on the instance.

## What's in the repo

| Path | Purpose |
| --- | --- |
| `.devcontainer/devcontainer.json` | Prebuilt `malloyyo-devcontainer` image |
| `.mcp.json` | `malloyyo_author` (local build tools) and `malloyyo_instance` (the instance at `MALLOYYO_URL`) MCP servers |
| `.claude/` | Pre-approved tools, malloyyo skills, and `connect-database` |
| `CLAUDE.md` | How Claude works in this repo |
| `malloy-config.json` | `bigquery` (reads `BIGQUERY_SERVICE_ACCOUNT_JSON`), and `duckdb` for the example only |
| `datasets/` | One directory per dataset; `example/` is a placeholder to replace |
