# Malloyyo model template

A starting point for a Malloy model repo. You build the model by talking to
Claude, check it against real data, and publish it to your Malloyyo instance
by merging a pull request. Each team has its own instance (for example
**george**, **john**, **ringo** or **paul**); the examples here use george.

## Start here

1. Open [claude.ai/code](https://claude.ai/code) and start a session on this
   repo. If your team has a shared environment for its instance, pick it; if
   not, your default one is fine.
2. Copy this prompt into the session:

   ```text
   Set me up to work on this Malloy model repo. Ask me which Malloyyo instance
   I use and its address, then check everything this session needs for it
   (the malloyyo tools, my connection to the instance, and what's needed to
   build models). Tell me in plain steps what's missing and exactly what I
   need to do to fix it, one thing at a time. Don't ask me to paste any keys
   or passwords into the chat.
   ```

   (`/start` does the same.)

Claude asks which instance you use, checks what's ready and walks you through
anything missing. Often that's just connecting the instance with your own
account (one click in Claude's settings), after which you can already explore
its published data. To build models, it tells you exactly what to add to your
session's settings. Queries run through the instance, so there's no database
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
  `MALLOYYO_URL`, and run `claude` in the repo. Claude reaches the instance
  through its claude.ai connector, or set `MALLOYYO_TOKEN` as for a codespace.

## What's in the repo

| Path | Purpose |
| --- | --- |
| `CLAUDE.md` | How Claude works in this repo |
| `.claude/skills/` | `start`, `google-login`, `share`, `connect-database`, and two open-source Malloy skills ([docs/malloy-skills.md](docs/malloy-skills.md)) |
| `.claude/hooks/session-start.sh` | Installs the `malloyyo` tool if needed and tells Claude what's set up |
| `.claude/cloud-environment-setup.sh` | Setup script for the team's cloud environment |
| `.claude/bin/` | Helpers: the setup check (`malloyyo-doctor`), the local author server, optional personal Google sign-in |
| `.mcp.json` | `malloyyo_author` (local build tools) and `malloyyo_instance` (the instance at `MALLOYYO_URL`) |
| `.devcontainer/` | Codespace image |
| `malloy-config.json` | `bigquery` (reads `BIGQUERY_SERVICE_ACCOUNT_JSON`), and `duckdb` for the example only |
| `datasets/` | One directory per dataset; `example/` is a placeholder to replace |
| `docs/team-setup.md` | One-time setup for an organization |
