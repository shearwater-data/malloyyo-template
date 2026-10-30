# Malloyyo model template

A Malloy model repo you build by talking to Claude and publish to your team's
Malloyyo instance (e.g. **george**, **john**, **ringo**, **paul**) by merging a
pull request. *All together now.*

## Start here

Start a session on this repo at [claude.ai/code](https://claude.ai/code) and
paste (or type `/start`):

```text
Set me up to work on this Malloy model repo. Ask me which Malloyyo instance
I use and its address, check everything this session needs for it, and tell
me step by step what's missing and how to fix it. Don't ask me to paste keys
or passwords into the chat.
```

Claude checks your session and tells you which of the steps below you need,
in order. Most people need only some of them, once.

To set up a colleague, send them a link that opens this repo with the prompt
filled in:
`https://claude.ai/code?repositories=<owner/repo>&prompt=<the prompt, URL-encoded>`.

## Hello George

*You say goodbye, and I say hello.* Once you're set up, this end-to-end test
loads public data into BigQuery, models it in Malloy, and finds a few
insights:

```text
Hello George. Load Our World in Data's CO2 dataset
(https://raw.githubusercontent.com/owid/co2-data/master/owid-co2-data.csv)
into the BigQuery dataset malloyo_hello_george in our data project, as a
table with a proper schema, using the codebook
(https://raw.githubusercontent.com/owid/co2-data/master/owid-co2-codebook.csv)
for the column descriptions. Model it in Malloy as datasets/hello_george/,
check the numbers, then give me 2 or 3 insights, each with a chart, in one
Claude artifact. Open a pull request; don't merge it.
```

It needs the setup steps below, including step 7 (loading data). After the pull
request is merged, an instance admin runs **Refresh and create missing
datasets** once, and `hello_george` appears on the instance. *Here comes the
sun.*

## Setup steps

Examples use the **george** instance (`https://george.malloyyo.com`); use your
instance's name and address. Steps 3 to 6 are in your cloud environment's
settings: in a session, open the environment menu in the title bar, then
**Edit**. If your team shares an environment, whoever manages it does these
([docs/team-setup.md](docs/team-setup.md)).

### Step 1: Connect your instance

*Come together, right now.* claude.ai → **Settings → Connectors** → your
instance (e.g. **george-malloyyo**) → **Connect**, and sign in with your
account on it. Then set its tools to **Always allow**, so Claude doesn't stop
to ask each time. If it isn't listed, a claude.ai Owner adds it
([team setup, step 2](docs/team-setup.md#2-add-the-instance-as-a-connector)).

### Step 2: Get access on the instance

*Help! I need somebody.* If the instance refuses you, ask one of its admins
for an account.

### Step 3: Let your environment reach the instance

*The long and winding road.* **Network access** → add under **Allowed
domains**, keeping **Allow package managers** ticked:

```text
george.malloyyo.com
```

If Claude later reports another blocked address (for example while loading
data), add it the same way.

### Step 4: Add the setup script

*Getting better all the time.* **Setup script**, so every session starts with
the `malloyyo` tool:

```bash
#!/bin/bash
npm install -g @malloydata/malloyyo || true
```

### Step 5: Add the instance's address

*Here, there and everywhere.* **Environment variables**:

```text
MALLOYYO_URL=https://george.malloyyo.com
```

### Step 6: Add the BigQuery key (to build models)

*Baby, you can drive my car*, but only to read. Ask whoever manages your
instance's BigQuery access for the shared read-only key file. On your
computer, encode it (this copies it on a Mac):

```bash
base64 -i key.json | pbcopy
```

Add it under **Environment variables**, never in chat:

```text
BIGQUERY_SERVICE_ACCOUNT_JSON=<paste>
```

### Step 7: Get access to load data

*Got to get you into my life.* The shared key can't load data, so loading
runs as you, in the team's data project, set in `.claude/bigquery-data.json`
(for george: `shearwater-malloyo-george`; to set one up, see
[team setup, step 6](docs/team-setup.md#6-a-data-project-for-loading-data)):

1. Ask the data project's owner to give your Google account **BigQuery Data
   Editor** and **BigQuery Job User** on it.
2. When you load data, Claude shows a Google sign-in link and a box for the
   code Google gives you. That's all; the sign-in lasts for the session.

### Step 8: Start a new session

*Tomorrow never knows*, but a new session does: environment changes apply to
new sessions. Start one and paste the prompt again; Claude confirms you're
ready.

Then ask for what you want, for example:

> what's in the published data?

> add a dataset for our orders table, with an overview dashboard

**New model repo?** **Use this template → Create a new repository** (don't
clone it: a clone still pushes here), then have an instance admin add it
([team setup, step 3](docs/team-setup.md#3-let-the-instance-read-the-repo-and-publish-on-merge)).

## Publishing

*We can work it out.* Claude opens a pull request; merging it publishes through the repo's webhook,
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
| `.claude/skills/` | `start`, `share`, `bigquery-data`, `connect-database`, `google-login`, and two open-source Malloy skills ([docs/malloy-skills.md](docs/malloy-skills.md)) |
| `.claude/bin/`, `.claude/hooks/` | The setup check (`malloyyo-doctor`), run at session start; `bq-data` for loading BigQuery; Google sign-in |
| `.claude/bigquery-data.json` | The team's BigQuery data project, location, and the instance's service account |
| `.claude/cloud-environment-setup.sh` | Setup script for a cloud environment |
| `.mcp.json` | Local build tools, and the instance at `MALLOYYO_URL` |
| `malloy-config.json` | Connections: `bigquery`, and `duckdb` for the example |
| `datasets/` | One directory per dataset; `example/` is a placeholder to replace |

*And in the end, the data you take is equal to the data you make.*
