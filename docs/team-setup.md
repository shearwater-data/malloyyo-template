# One-time team setup

Do this once per Malloyyo instance. Afterwards, a colleague starts by opening
a model repo at claude.ai/code and typing `/start`.

Below, `<instance>` is your instance's name and `https://<instance>.malloyyo.com`
its address. The examples use **george** (`https://george.malloyyo.com`);
put in your own.

Steps 1 and 2 need someone with the **Owner** role in your claude.ai
organization. To check whether that's you, open claude.ai → **Admin settings**:
if you see a **Cloud environments** page, you're an Owner. Step 3, and setting
the key on the instance in step 4, need an admin on the instance.

## 1. Create the shared cloud environment

A cloud environment is what Claude Code on the web runs in: which tools get
installed and which settings it has. One shared environment means nobody has
to set this up themselves.

1. claude.ai → **Admin settings → Cloud environments → Add**.
2. **Name:** the instance's name, e.g. `george`, so people can tell
   environments apart when there's more than one instance.
3. **Network access:** Trusted (the default).
4. **Setup script:** paste the contents of
   [`.claude/cloud-environment-setup.sh`](../.claude/cloud-environment-setup.sh).
   It installs the `malloyyo` tool before each session starts. Claude saves
   the result, so later sessions start quickly.
5. **Environment variables:**

   ```
   MALLOYYO_URL=https://<instance>.malloyyo.com
   BIGQUERY_SERVICE_ACCOUNT_JSON=<the shared key, base64-encoded: step 5>
   ```

   For george, the first line is `MALLOYYO_URL=https://george.malloyyo.com`.
6. Save it, then at **Admin settings → Claude Code**, make it the
   organization's **default environment**. Colleagues then get it without
   picking it.

Every member can read this environment's variables. That's why the BigQuery
key here should be a read-only key made just for this, and never anyone's
personal key.

## 2. Add the instance as a connector

This lets each person reach the instance from Claude with their **own**
account on it, in chat, in cloud sessions, and inside shared artifacts that show
live numbers.

1. claude.ai → **Admin settings → Connectors → Add custom connector**.
2. **Name:** `<instance>`. **URL:** `https://<instance>.malloyyo.com/mcp`
   (for george: `george`, `https://george.malloyyo.com/mcp`).
3. Save. Each colleague then clicks **Connect** on it once (Settings →
   Connectors) and signs in to the instance.

## 3. Let the instance read the repo, and publish on merge

Unchanged from before; on the instance, as an admin:

1. The instance needs a GitHub token that can read the repo (once per instance, if
   it's private): a fine-grained token with **Contents: Read-only** on the model
   repos, set as the instance's `GITHUB_TOKEN`.
2. **Home → Admin → General → + Add Malloy model from GitHub**: `<owner>/<repo>`,
   branch `main`.
3. To publish every merge automatically, copy the **webhook payload URL** from
   the repo's page on the instance into the GitHub repo's **Settings → Webhooks → Add
   webhook** (content type `application/json`, just the push event, plus the
   instance's `GITHUB_WEBHOOK_SECRET` if it has one).

## 4. How queries run

By default, everything goes through the instance:

- **Asking questions** of published models: the instance runs the query with
  its own BigQuery key. People only need the instance's connector.
- **Building models, as an instance admin:** the instance compiles changes and
  shows previews with its own key (`preview_changes`).
- **Building models, as anyone else:** Claude compiles and checks the model in
  the session with the shared key from step 1, which is the same key the
  instance uses.

So the instance and the shared environment hold the **same** key, under the
same name, `BIGQUERY_SERVICE_ACCOUNT_JSON`. On a Malloyyo-hosted instance, an
instance admin sets it with
`malloyyo cloud secrets set BIGQUERY_SERVICE_ACCOUNT_JSON -i <instance>`; on a
self-hosted one, it's an environment variable of the server.

**Optional, personal access.** Anyone can instead query BigQuery as
themselves: Claude shows a Google sign-in link (the `google-login` skill).
Their Google account then needs its own **BigQuery Job User** on the project
and **BigQuery Data Viewer** on the datasets.

## 5. The shared BigQuery key

1. In Google Cloud, create a service account with **BigQuery Data Viewer** on
   the model's datasets and **BigQuery Job User** on the project, and download a
   JSON key. (If the instance already has a key for this project, reuse that
   one.)
2. Encode it on one line: `base64 -w0 key.json` (macOS: `base64 -i key.json`).
   Pasted raw, the line breaks inside the private key get mangled and the key
   stops working.
3. Put the base64 text in the shared environment from step 1 as
   `BIGQUERY_SERVICE_ACCOUNT_JSON`, and on the instance under the same name
   (step 4).
