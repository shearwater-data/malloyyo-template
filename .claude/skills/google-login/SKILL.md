---
name: google-login
description: Sign the person in to Google so models can be built and checked against BigQuery with their own access, from a cloud session that has no browser. Use when building against BigQuery and the session status shows no BigQuery key and no Google sign-in, or when BigQuery fails with "Unable to detect a Project Id" or "Could not load the default credentials".
---

# Google sign-in for BigQuery

Building a model here reads BigQuery as the person, with their own Google
account. Nothing is stored in the repo: the sign-in lives in this session only
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
- **"Unable to detect a Project Id"**: the sign-in didn't complete, or
  `malloy-config-local.json` is missing. Run `.claude/bin/google-login status`.
- **Can't get it working.** Fall back to the shared read-only key described in
  `docs/team-setup.md`: whoever manages the team environment adds it, and you
  delete `malloy-config-local.json` so the key is used.
