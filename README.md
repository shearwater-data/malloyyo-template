# Malloyyo model template

A starting point for a Malloy model repo. You build the model by talking to
Claude, check it against real data, and publish it to your Malloyyo instance
by merging a pull request. The examples use an instance called **george**;
yours will have its own name.

## Start here

1. Open [claude.ai/code](https://claude.ai/code), pick your team's environment
   for the instance (e.g. **george**) and this repo.
2. Type `/start`.

Claude checks what's ready and walks you through anything missing. The first
time, that's connecting the instance with your own account (one click in
Claude's settings). Queries run through the instance, so there's no database
login.
Then tell it what you want, for example:

> what's in the published data?

> add a dataset for our orders table, with an overview dashboard

Never paste a key or password into the chat; Claude will tell you where one
goes if it's needed.

**First person in your organization?** Someone has to do a one-time setup
first: [docs/team-setup.md](docs/team-setup.md).

**New model repo?** On this page, **Use this template → Create a new
repository** (don't clone it: a clone still pushes here). Name it
`malloyyo-<usecase>`, then have an instance admin add it (team setup, step 3).

## Sharing

- **Results and charts:** Claude shares them as artifacts that show live
  numbers from the instance, as a draft dashboard on the instance with a link, or saves
  them into the model (see the `share` skill).
- **Sessions:** share a session's link with Team visibility from its menu to
  hand work over. It's a read-only snapshot.
- **The model:** this repo. Changes go through pull requests.

## Publishing

Claude opens a pull request; you review and merge it.

- After a merge, the instance publishes it through the webhook (team setup, step 3),
  or when someone clicks **Refresh from GitHub** on the repo's page on the instance.
- A **new** dataset has to be created once, by an instance admin: **Refresh and
  create missing datasets** on the repo's page.

The published model reads the database with **the instance's** credentials, so every
env name in `malloy-config.json` (such as `BIGQUERY_SERVICE_ACCOUNT_JSON`) must
be set on the instance under the same name. If publishing fails with "Could not load
the default credentials" followed by many "no such field" errors, that name is
missing on the instance.

## Other ways to work

- **Codespace:** **Code → Codespaces → Create codespace**, then run `claude` in
  its terminal. Add `MALLOYYO_URL`, `MALLOYYO_TOKEN` (a token with the **mcp**
  and **publish** scopes, from **Home → Tokens** on the instance) and, for
  BigQuery, `BIGQUERY_SERVICE_ACCOUNT_JSON` as **Settings → Secrets and
  variables → Codespaces** secrets on the repo first.
- **Laptop:** clone the repo, `npm install -g @malloydata/malloyyo`, set
  `MALLOYYO_URL`, run `claude` in the repo, and sign in to the instance
  through `/mcp`.

## What's in the repo

| Path | Purpose |
| --- | --- |
| `CLAUDE.md` | How Claude works in this repo |
| `.claude/skills/` | `start`, `google-login`, `share`, `connect-database`, and two open-source Malloy skills ([docs/malloy-skills.md](docs/malloy-skills.md)) |
| `.claude/hooks/session-start.sh` | Installs the `malloyyo` tool if needed and tells Claude what's set up |
| `.claude/cloud-environment-setup.sh` | Setup script for the team's cloud environment |
| `.claude/bin/` | Helpers: the local author server, the instance sign-in header, optional personal Google sign-in |
| `.mcp.json` | `malloyyo_author` (local build tools) and `malloyyo_instance` (the instance at `MALLOYYO_URL`) |
| `.devcontainer/` | Codespace image |
| `malloy-config.json` | `bigquery` (reads `BIGQUERY_SERVICE_ACCOUNT_JSON`), and `duckdb` for the example only |
| `datasets/` | One directory per dataset; `example/` is a placeholder to replace |
| `docs/team-setup.md` | One-time setup for an organization |
