---
name: google-login
description: Sign the person in to Google from a cloud session (no browser), so BigQuery work runs as them. Needed to create datasets or load data into the team's data project (bigquery-data skill); otherwise only when they ask to use their own Google access. Also use when BigQuery fails with "Unable to detect a Project Id" or "Could not load the default credentials".
---

# Google sign-in

The sign-in lives in this session only and ends with it; nothing goes into the
repo.

## 1. Start it

```bash
.claude/bin/google-login start
```

It prints one long `https://accounts.google.com/...` link.

## 2. Show the link and collect the code in one box

Use the `AskUserQuestion` tool, with the link **inside the question**, so the
person sees it and the code field together (a box shown under a link covers
the link):

- question: "Open this link, sign in with your work Google account and click
  **Allow**: <the full link>. Then paste the code Google shows into **Other**."
- header: "Google code"
- options: "I need a new link" (start again) and "Cancel".

Don't ask in the same turn for anything else. The code is single-use and
only works with this link, so it's fine to receive it; it's the only sign-in
value that may be. If `AskUserQuestion` isn't available, show the link and ask
them to paste the code in the chat. The script waits 10 minutes; after that,
start again.

## 3. Finish it

```bash
.claude/bin/google-login finish 'THE_CODE'
```

On success it writes `malloy-config-local.json` (the same connections, but
BigQuery uses the sign-in instead of the shared key) and points gcloud at the
team's data project from `.claude/bigquery-data.json`, where people have Job
User. `.gitignore` keeps the file out of git and publish refuses it.

Restart the `malloyyo_author` server so it reads the new config (the person
runs `/mcp` and reconnects it, or starts a new session), then probe:

```bash
malloyyo sql bigquery -e "select session_user() as who"
```

## When it doesn't work

- **"Access Denied" / "permission"**: their account has no access to the data
  project. Its owner grants **BigQuery Data Editor** and **BigQuery Job User**
  (README step 7).
- **"Unable to detect a Project Id"**: run `.claude/bin/google-login status`,
  then `.claude/bin/google-login local-config`.
- **Back to the shared key**: delete `malloy-config-local.json`.
