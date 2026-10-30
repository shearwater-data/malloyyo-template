---
name: start
description: Set up and check a session on this Malloy model repo for any Malloyyo instance. Asks which instance and its URL, runs the setup check, explains in plain steps what's missing and how to fix it (including what to put in the person's cloud environment), then asks what they want to do. Use when someone types /start, pastes the README's setup prompt, says hello, asks how to get set up, or something isn't working.
---

# Set up a session

The person is probably not a developer. Keep each message short, say what each
step is for, and do one step at a time. Never show tokens, keys or env values,
and never ask for one in chat.

There are many Malloyyo instances (one per team: george, john, ringo, paul,
…). **Never assume one**, not even the one `MALLOYYO_URL` points to.

## 1. Ask which instance

If the person's message already names the instance or its address (a shared
setup link does), don't ask again: use it, say which one you're checking, and
go on to step 2. Otherwise ask in one message:

> Which Malloyyo instance do you use, and what's its address? For example
> **george** at `https://george.malloyyo.com`.

If `MALLOYYO_URL` is already set (the "Malloyyo session status" block shows
it), offer it as the likely answer, e.g. "This session is set up for
`https://george.malloyyo.com`; is that the one?", but still let them confirm
or change it. If they give only a name, suggest `https://<name>.malloyyo.com`
and confirm.

## 2. Check, quietly

Run the check with their URL:

```bash
.claude/bin/malloyyo-doctor https://<instance>.malloyyo.com
```

Each line is `OK`, `MISSING`, `WARN` or `INFO`. Then check the two things the
script can't see:

- **The instance's connector.** Look for that instance's tools in this
  session: a claude.ai connector named after it, e.g. `george` or
  `george-malloyyo`, whose tools end in `list_sources`, `query` and so on
  (`ToolSearch` with the instance name finds them). If there are several
  instance connectors, use only the one for their instance. If you can't find
  it, `ListConnectors` with the instance name says whether it exists but isn't
  connected. Call `list_sources` on it to prove it answers. `.mcp.json`'s
  `malloyyo_instance` is a fallback that works only with `MALLOYYO_TOKEN`.
- **Building on the instance.** Whether its tools include `preview_changes`,
  `list_repos` and `check_repo`; instance admins get them.

## 3. Report and fix

Show a short checklist, ✅ / ❌, in plain words, grouped by what it's for:

- **Explore published data:** needs only the connector. This often works
  straight away, so say so and offer it even while other things are missing.
- **Build models on the instance (admins):** with preview tools, the instance
  compiles with its own warehouse key, so a missing key or `MALLOYYO_URL` in
  this session is **not** a problem. Don't list them.
- **Build models:** needs the malloyyo tools, and either preview tools on the
  instance (admins) or the shared warehouse key in this session.

Then fix the first missing item:

- **Connector missing or not connected.** "Open claude.ai → Settings →
  Connectors, find **<instance>** and click **Connect**, sign in with your
  account on that instance, then come back and say done." The tools usually
  appear in the same session; if they don't, start a new one. If there's no
  connector for their instance at all, someone with the claude.ai Owner role
  adds it (`docs/team-setup.md`, step 2).
- **Connected, but the instance refuses them** (sign-in fails, "forbidden",
  "not authorized", or `list_sources` comes back empty or with an access
  error). They don't have an account on that instance yet, or it doesn't
  include them. Only an admin on that instance can fix this: tell them to ask
  that instance's admin for access, naming the instance. Don't try to work
  around it with another instance or a token.
- **Instance does not answer.** The address is wrong or the instance is down.
  Ask them to check it by opening it in their browser.
- **malloyyo CLI missing.** Run `npm install -g @malloydata/malloyyo` yourself
  (about a minute), then carry on.
- **`MALLOYYO_URL`, the warehouse key, or the setup script missing.** These
  belong in the session's settings. Where depends on the `INFO where:` line:
  - **Claude cloud session:** a cloud environment. If they're on their team's
    shared environment, its manager fixes it (`docs/team-setup.md`).
    Otherwise they can set up their own: in this session's title bar, open the
    environment menu → their environment → **Edit** (or **Add environment**,
    named after the instance), and give them exactly this to paste:

    **Setup script:**
    ```bash
    #!/bin/bash
    npm install -g @malloydata/malloyyo || true
    ```

    **Environment variables** (the instance's address, filled in, plus the
    key line only if they'll build models locally):
    ```
    MALLOYYO_URL=https://<instance>.malloyyo.com
    BIGQUERY_SERVICE_ACCOUNT_JSON=<the shared read-only key, base64-encoded>
    ```

    For the key, they ask whoever manages their instance's BigQuery access for
    the shared read-only key, and encode it on their computer (`base64 -i
    key.json | pbcopy` on a Mac). It goes straight into the environment, never
    into chat. A new session picks up the changes.
  - **Codespace:** repo secrets under **Settings → Secrets and variables →
    Codespaces**, then restart the codespace.
  - **This computer:** `export MALLOYYO_URL=…` in their shell, and
    `read -rs NAME && export NAME` for a key; then restart Claude.

  Until they've done that, this session can still work: pass their URL to
  commands yourself, and explore through the connector.
- **Key set but not valid.** It was pasted raw and the line breaks in the
  private key got mangled. Have them re-add it base64-encoded, as above.
- **No key and no preview tools, but they want to build now.** Offer the
  `google-login` skill (their own Google access to BigQuery) as an optional
  stopgap.

After each fix, run the check again and update the checklist.

## 4. Ask what they want

Once exploring (at least) works, ask:

> Do you want to **explore** the data that's already published on
> <instance>, or **build or change** a model?

- Explore: `describe_source`, then `query`, on their instance's connector.
  Share results the way the `share` skill describes.
- Build: follow CLAUDE.md ("How models are built here"). With preview tools,
  run the checks in `yo_help("authoring/start")` first. Either way, start by
  asking where their data lives.
