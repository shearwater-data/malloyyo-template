# Malloyyo model template

A Malloy model repo you build by talking to Claude and publish to your team's
Malloyyo instance (e.g. **george**, **john**, **ringo**, **paul**) by merging a
pull request.

## Start here

Start a session on this repo at [claude.ai/code](https://claude.ai/code) (in
your team's shared environment, if it has one) and paste:

```text
Set me up to work on this Malloy model repo. Ask me which Malloyyo instance
I use and its address, check everything this session needs for it, and tell
me step by step what's missing and how to fix it. Don't ask me to paste keys
or passwords into the chat.
```

(`/start` does the same.) Claude checks the tools, your connection to the
instance, and what building models needs, then walks you through each fix.
Then ask for what you want:

> what's in the published data?

> add a dataset for our orders table, with an overview dashboard

**First time for your organization or instance?** See
[docs/team-setup.md](docs/team-setup.md).

**New model repo?** **Use this template → Create a new repository** (don't
clone it: a clone still pushes here), then have an instance admin add it
(team setup, step 3).

## Publishing

Claude opens a pull request; merging it publishes through the repo's webhook,
or via **Refresh from GitHub** on the repo's page on the instance. A **new**
dataset is created once by an instance admin: **Refresh and create missing
datasets**.

The instance reads the database with its own credentials, so every env name in
`malloy-config.json` (e.g. `BIGQUERY_SERVICE_ACCOUNT_JSON`) must be set on the
instance too. "Could not load the default credentials" followed by "no such
field" errors means one is missing there.

## Other ways to work

In a codespace or on a laptop, install `malloyyo`
(`npm install -g @malloydata/malloyyo`; codespaces have it) and set
`MALLOYYO_URL`, `MALLOYYO_TOKEN` (an instance token with the **mcp** and
**publish** scopes, from **Home → Tokens**) and, for BigQuery,
`BIGQUERY_SERVICE_ACCOUNT_JSON`: codespace secrets under **Settings → Secrets
and variables → Codespaces**, or your shell. Then run `claude` in the repo.

## What's in the repo

| Path | Purpose |
| --- | --- |
| `CLAUDE.md` | How Claude works in this repo |
| `.claude/skills/` | `start`, `share`, `connect-database`, `google-login`, and two open-source Malloy skills ([docs/malloy-skills.md](docs/malloy-skills.md)) |
| `.claude/bin/`, `.claude/hooks/` | The setup check (`malloyyo-doctor`), run at session start; helpers |
| `.claude/cloud-environment-setup.sh` | Setup script for a cloud environment |
| `.mcp.json` | Local build tools, and the instance at `MALLOYYO_URL` |
| `malloy-config.json` | Connections: `bigquery`, and `duckdb` for the example |
| `datasets/` | One directory per dataset; `example/` is a placeholder to replace |
