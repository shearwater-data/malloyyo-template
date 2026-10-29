---
name: start
description: First stop in a new session on this model repo. Checks that george (the Malloyyo instance), the malloyyo tools and, for building models, Google/BigQuery are ready, walks the person through whatever is missing one step at a time, then asks what they want to do. Use when someone types /start, says hello, asks how to get going, or asks what Claude can do here.
---

# Start a session

The person is probably not a developer. Keep each message short, say what each
step is for, and do one step at a time. Never show tokens, keys or env values.

The SessionStart hook has already printed a "Malloyyo session status" block
into the conversation. Use it; don't re-run checks it already answers.

## 1. Check, quietly

Work out each of these before saying anything:

| Check | How | Ready when |
| --- | --- | --- |
| malloyyo tools | the status block's `malloyyo CLI` line, and that `mcp__malloyyo_author__*` tools exist | a version is shown and the tools are listed |
| george | which george tools you have: a claude.ai connector (its tools are named after the connector, e.g. `mcp__george__*`) or the repo's `malloyyo_instance` server. Call `list_sources` on it | it answers |
| Building on george | only needed to build or change models. george's tools include `preview_changes`, `list_repos` and `check_repo` (george admins get them) | present: no data access is needed here, george compiles with its own |
| Building locally | only if george can't preview for them. For each connection in `malloy-config.json` they'll use: its env names are `set` in the status block, **or** for BigQuery, `Google sign-in: active` | one of those |

Querying what's already published needs only george: george reads the
warehouse with its own credentials. Don't ask someone who only wants answers
to sign in to Google, and don't ask someone george can preview for either.

## 2. Report and fix

Tell the person in one short checklist what's ready and what isn't, then fix
the first missing item:

- **malloyyo tools missing.** The environment's setup script didn't run or
  failed. Tell them the team environment needs
  `.claude/cloud-environment-setup.sh` as its setup script (the person who
  manages it can follow `docs/team-setup.md`). Meanwhile, run
  `npm install -g @malloydata/malloyyo` yourself and continue.
- **george not connected.** Say: "Open claude.ai → Settings → Connectors, find
  **george** and click **Connect**, sign in with your george account, then come
  back and say done. You only do this once." If there's no george connector to
  click, the organization hasn't added it yet: point them to step 2 of
  `docs/team-setup.md` for whoever manages Claude. After they say done, a new
  session may be needed for the tools to appear; say so if they don't.
- **Can't build yet.** Building on george needs a george admin to give them
  admin, or someone already an admin to do it. Otherwise build locally: for
  BigQuery use the `google-login` skill, for other databases
  `connect-database`.

## 3. Ask what they want

Once the basics are ready, ask one question:

> Do you want to **explore** the data that's already published on george, or
> **build or change** a model?

- Explore: `describe_source`, then `query` on george. Share results the way
  the `share` skill describes.
- Build: follow CLAUDE.md ("How models are built here"). On george, run the
  checks in `yo_help("authoring/start")` first; either way, start by asking
  where their data lives.
