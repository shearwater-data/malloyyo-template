---
name: google-login
description: Optional - sign the person in to Google so models can be built and checked against BigQuery with their own access instead of the shared key, from a cloud session that has no browser. Use only when the person asks to use their own Google access, or there's no shared BigQuery key and they can't wait for one.
---

# Google sign-in for BigQuery

Optional. By default, BigQuery is read through the instance or with the
shared key from the team environment. This skill instead reads BigQuery as
the person, with their own Google account. Nothing is stored in the repo: the sign-in lives in this session only
and ends with it.

## 1. Start the sign-in

Run:

```bash
.claude/bin/google-login start
```

It prints one long `https://accounts.google.com/...` link. Give the person the
link and say:

> Open this link, sign in with your work Google account and allow access.
> Google then shows a code. Paste that code here.

The script waits 10 minutes for the code. If it runs out, start again.

## 2. Finish it

The code is single-use and only works with the sign-in you just started, so
it's fine for the person to paste it into the chat. It is the only sign-in
value that may be pasted. Run:

```bash
.claude/bin/google-login finish 'THE_CODE'
```

On success it also writes `malloy-config-local.json`: the same connections as
`malloy-config.json`, but BigQuery without the service-account key, so it uses
the sign-in. That file **replaces** `malloy-config.json` while building here.
`.gitignore` keeps it out of git and publish refuses it, so the published model
still uses the instance's own credentials.

## 3. Check it, then reconnect the author tools

The local `malloyyo_author` server read the config when it started, so restart
it after writing the local file (ask the person to run `/mcp` and reconnect
`malloyyo_author`, or start a new session). Then probe:

```bash
malloyyo sql bigquery -e "select 1 as one"
```

## When it doesn't work

- **"Access Denied" / "permission"**: their Google account can't read that
  project. The person who manages Google Cloud grants them **BigQuery Data
  Viewer** on the datasets and **BigQuery Job User** on the project.
- **"Unable to detect a Project Id"**: the sign-in didn't complete, or gcloud
  has no default project. Run `.claude/bin/google-login status`, then
  `.claude/bin/google-login local-config`, which sets gcloud's project to the
  `bigquery` connection's `projectId` (without a key, queries run in gcloud's
  project, not the connection's).
- **"User does not have bigquery.jobs.create permission in project …"**: the
  sign-in worked, but their account can't run queries in that project. Same
  fix as "Access Denied" above.
- **Back to the shared key.** Delete `malloy-config-local.json`; the shared
  key from the team environment is used again (`docs/team-setup.md`, step 5).
