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

Each line is `OK`, `MISSING`, `WARN` or `INFO`. Then check the one thing the
script can't see, **the instance's connector**: a claude.ai connector named
after the instance (e.g. `george-malloyyo`), whose tools end in
`list_sources`, `query` and so on (`ToolSearch` with the instance name finds
them). If there are several instance connectors, use only the one for their
instance. If you can't find it, `ListConnectors` with the instance name says
whether it exists but isn't connected. Call `list_sources` on it to prove it
answers. `.mcp.json`'s `malloyyo_instance` is a fallback that works only with
`MALLOYYO_TOKEN`.

## 3. Report, then walk through the README's steps

The README's **Setup steps** section is the single source for fixes, with
copy-paste values. Link to it rather than rewriting it: build each link from
the repo (`INFO repo:` line) as
`https://github.com/<owner/repo>/blob/main/README.md#<anchor>`, with these
anchors:

| Finding | README step | Anchor | Button topic |
| --- | --- | --- | --- |
| Instance's connector missing, not connected, or tools off | 1 | `step-1-connect-your-instance` | `connectors.add` (`connectors.tool_off` if connected) |
| Instance refuses them (forbidden, not authorized, empty `list_sources` with an access error) | 2 | `step-2-get-access-on-the-instance` | none |
| `WARN … network settings block` | 3 | `step-3-let-your-environment-reach-the-instance` | `environment.network` |
| `malloyyo CLI` was missing at session start | 4 | `step-4-add-the-setup-script` | `environment.dependencies` |
| `MALLOYYO_URL` not set or wrong | 5 | `step-5-add-the-instances-address` | `environment.secrets` |
| Warehouse key missing or not valid | 6 | `step-6-add-the-bigquery-key-to-build-models` | `environment.secrets` |
| They want to load data, and the check says `MISSING you can't load data` or there's no Google sign-in | 7 | `step-7-get-access-to-load-data` | none (sign-in: `google-login` skill) |
| Any of steps 3 to 6 needed | 8 | `step-8-start-a-new-session` | none |

1. Show a short ✅ / ❌ checklist in plain words, grouped by what it's for:
   **explore published data** (needs only the connector, so offer it even
   while other things are missing) and **build models** (the malloyyo tools
   and the warehouse key here). Report only what you checked; don't mention
   tools or features this session doesn't have.
2. Say which steps they need, in order, as one line of links, e.g. "You need
   steps [1], [3], [5], [6] and [8], in that order. I'll walk you through
   them." On a shared team environment, steps 3 to 6 are its manager's job
   (`docs/team-setup.md`); say so instead.
3. Walk through them one at a time: name the step, link it, and repeat only
   the values to paste, with this instance's name and address filled in. In
   a Claude cloud session, also call `read_documentation` (the
   `claude-code-remote` server) once per topic in the table, with
   `situation: "blocked"`: the person gets a button to that settings page.
4. After each step, run the check again. Steps 3 to 6 only take effect in a
   new session, so batch them and then send them to step 8.

Other cases:

- **Instance does not answer.** The address is wrong or the instance is down;
  ask them to open it in a browser.
- **malloyyo CLI missing right now.** Run `npm install -g @malloydata/malloyyo`
  yourself (about a minute) and carry on; step 4 makes it permanent.
- **Codespace or this computer** (`INFO where:` line). Settings go in
  Codespaces secrets or their shell instead; see the README's "Other ways to
  work".
- **No key yet but they want to build now.** Offer the `google-login` skill.
- **Never** ask for or accept a key in chat.

## 4. Ask what they want

Once exploring (at least) works, ask:

> Do you want to **explore** the data that's already published on
> <instance>, or **build or change** a model?

- Explore: `describe_source`, then `query`, on their instance's connector.
  Share results the way the `share` skill describes.
- Build: follow CLAUDE.md ("How models are built here"), starting by asking
  where their data lives.
