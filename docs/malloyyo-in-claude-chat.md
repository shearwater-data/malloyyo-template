# Malloyyo modelling from a regular claude.ai chat: findings and MCP design

Research date: 2026-10-30. Verification legend: **[V]** checked against a primary source in this session, **[S]** secondary or third-party source only, **[U]** unverified inference.

> **Status (2026-10-30):** the instance-side authoring tools this note builds
> on (`preview_changes`, `list_tables`, `check_repo`, `publish_repo`, branch
> previews) sit behind the server setting `REPO_AUTHORING`, which is off on
> george and which george's operator plans to remove. Assume they are **not
> available**. Model work stays in Claude Code: compile and query locally with
> `malloyyo_author`, preview dashboards with `malloyyo dashboard dev`, and
> publish by merging a pull request. The design below is kept as background.

## TL;DR

- **Today, from a claude.ai chat, a team can query published models (the read-only connector) and nothing more.** Authoring needs Claude Code because of git, a local compiler and a warehouse key.
- **Malloyyo's own admin authoring tools already remove most of the shell dependency.** `preview_changes` takes the **full text of changed files as tool arguments** (up to 200 files and 512KB) and compiles them server-side with the instance's warehouse connections. `list_tables`/`describe_table` explore the warehouse, `check_repo` checks a PR and `publish_repo` publishes. Its help assumes git only for computing `base`, the diff, and pushing or opening the PR. All of that can be replaced. [V: `yo_help("authoring/start")` on george]
- **So the shortest path to chat authoring is (1) expose those tools on the instance's claude.ai connector, (2) add a few small Malloyyo tools so the git steps happen server-side, and (3) solve data loading separately.** Loading is the hard part, because a file attached in chat can't be passed to an MCP tool in a practical way.
- A completely separate MCP server is possible: it would wrap the `malloyyo` CLI plus a GitHub App plus a BigQuery service account. It would largely re-implement `preview_changes`, though, so extending Malloyyo is the better choice.

## 1. What a claude.ai chat or Project can do today

| Capability | Fact | Source |
|---|---|---|
| Remote MCP connectors | Supported on web, desktop and mobile. Streamable HTTP (legacy SSE still accepted). Tools, prompts, resources, text and image tool results, and text and binary resources are supported. Resource subscriptions and sampling are not. | [V] claude.com/docs/connectors/building |
| Auth | OAuth 2.0 per user (DCR, or CIMD, or Anthropic-held client credentials). Spec revisions 2025-03-26, 2025-06-18 and 2025-11-25. Callback `https://claude.ai/api/mcp/auth_callback`. Token refresh is supported. **No `client_credentials` (machine-to-machine) grant.** A static org-wide header (API key) is in beta for a limited set of orgs. Traffic comes from 160.79.104.0/21. OAuth endpoints get 10s, refresh gets 30s. | [V] claude.com/docs/connectors/building/authentication |
| Team rollout | On Team and Enterprise, an Owner adds the connector for the org, and each member then connects their own account. Per-tool permissions are Always allow, Needs approval or Blocked. | [V] claude.com/docs/connectors/getting-started |
| Limits | Tool result is about 150,000 characters. Each tool call times out after **240 seconds**. A larger result is written to the code sandbox as a file. | [V] building index; MCP Apps troubleshooting |
| MCP Apps | Interactive UI from the server, rendered in the chat (sandboxed iframe on `{sha256(url)[:32]}.claudemcpcontent.com`). The app can call the server's tools, which are proxied through Anthropic. It can make direct fetches only to domains it declares in CSP `connectDomains`. | [V] for the domain and proxying, [S] for CSP and `callServerTool` (ext-apps docs) |
| File uploads | Chat: up to **500MB per file, 20 files**. Project knowledge: 30MB per file, and it must fit the context window. The code-execution feature page says 30MB per file for upload and download in the sandbox (the two pages conflict). | [V] support.claude.com 8241126, 12111783 |
| Code execution sandbox | Uploaded CSV and other data files are available in the sandbox. Egress modes are: off; package managers only (default on **Team**); package managers plus org-listed domains; or all domains. New **Enterprise** orgs start with egress off. MCP traffic is not governed by the egress setting. | [V] support.claude.com 12111783 |
| Skills / plugins | Skills and plugins (skills plus connectors) added in claude.ai work in chat. A Team or Enterprise Owner can install plugins for everyone. So the repo's Malloy skills (`malloy-gotchas-modeling`, `malloy-queries`, and an authoring skill) could be shipped to chat as a plugin bundled with the connector. | [V] claude.com/docs/extend/overview |
| GitHub in claude.ai | The built-in GitHub integration is **read-only** (file names and contents; no PRs, history or issues). In Projects it is available only in private projects. Writes need GitHub's own remote MCP server (`api.githubcopilot.com/mcp/`, OAuth or PAT, with a `/readonly` variant). That server has `create_branch`, `push_files` and `create_pull_request`. Whether claude.ai's OAuth works with it directly depends on GitHub's OAuth-app setup. | [V] for the integration, [S]/[U] for the remote server in claude.ai |
| Artifacts calling connectors | Reported as available for Pro, Max, Team and Enterprise, using each viewer's own connectors, but not on public artifacts. | [S] (community post); [U] for claude.ai chat specifically |

## 2. How others connect warehouses and semantic layers to Claude (outside Claude Code)

| Product | Remote / auth | Writes or authoring from chat? | Versioning and safety |
|---|---|---|---|
| **Google BigQuery remote MCP** (`bigquery.googleapis.com/mcp`) | OAuth plus IAM (`roles/mcp.toolUser` and others) | `execute_sql` can run DDL and DML, so `LOAD DATA ... FROM FILES(uris=['gs://...'])` should work [U]. `execute_sql_readonly` is also available. **There is no upload tool.** 3,000-row results and a 3-minute query cap. The docs say "custom redirect URIs aren't supported", so whether it can be added as a claude.ai custom connector is [U]. | IAM deny policy can block `execute_sql`; Model Armor. No model versioning. [V] |
| **MCP Toolbox / Looker** | Looker-managed remote MCP (recommended), or self-hosted Toolbox behind HTTPS with OAuth | **Yes, authoring:** `dev_mode`, `create_project_file`, `update_project_file`, `delete_project_file`, plus connection, schema and table introspection | Writes go to Looker **Development Mode**, which is Looker's per-user git branch. There's no validate or branch tool in the list. [V] The closest analogue to what Malloyyo would need. |
| **dbt MCP** | Remote server on dbt platform (OAuth or token) or local | The remote server is **read-only**: Semantic Layer, SQL, Discovery, Admin API and Fusion tools. CLI and codegen (building models) are **local-only**. | Model changes still go through git or the local CLI. [V/S] |
| **Snowflake managed MCP** | OAuth via a security integration, **no DCR** (so a client ID and secret go into the connector's advanced settings) | Cortex Analyst over **semantic views** returns SQL; Cortex Search. Read-oriented, with no semantic-view authoring tool found. | Role grants plus the semantic view boundary. [V/S] |
| **Databricks managed MCP** (Beta) | Workspace OAuth or PAT | Genie is read-only Q&A. UC functions are scoped to a schema. DBSQL is documented "to author data pipelines with AI coding tools" (that is, coding agents, not chat). | UC permissions. [V/S] |
| **MotherDuck remote MCP** | claude.ai directory connector | `query` plus a **`query_rw`** read-write tool (the docs conflict). The admin can leave it on approval or block it. | No versioning. [S] |
| **Neon MCP** (`mcp.neon.tech`, OAuth) | Remote, OAuth | **Yes:** `prepare_database_migration` applies the change on a **temporary branch** for testing, and `complete_database_migration` applies it to main. | Branch-preview-then-commit, the clearest "preview, then apply" pattern found. [S] |
| **Supabase MCP** (`mcp.supabase.com`, OAuth) | Remote, OAuth | `apply_migration`, branch create, merge and rebase (experimental). `read_only` and `project_ref` URL parameters narrow it. | Read-only recommended by default; project scoping. [S] |
| **Cube** | Per-tenant hosted MCP, OAuth, admin-enabled | Querying the semantic layer. No modelling tools found. [S] | n/a |
| **Omni** | Hosted MCP, enabled by support, API key or OAuth | Query only (models, topics, query). No model-editing tools found. [S] | n/a |
| **Hex** | Only community MCP servers found [S] | Run and list projects | n/a |

**Pattern:** almost every semantic layer exposes **read/query** to chat and keeps **model authoring in git and IDEs**. The exceptions are Looker (file CRUD in dev mode, a server-side branch) and the database branching tools (Neon, Supabase). **None of them offers "upload a file from chat into the warehouse".** Malloyyo's `preview_changes` (compile a proposed file set against a base commit and return live results and dashboards) is already more capable than any of them for safe authoring.

## 3. Design sketch: Malloyyo authoring from claude.ai

### 3a. What already exists (instance admin tools; not exposed on george 0.2.72)

`list_repos`, `list_tables`, `describe_table`, `preview_changes(repo, label, base, files, deleted)`, then `query`/`describe_source` with `model_ref = <repo>@<label>:<dataset>`, then `check_repo(repo, pull_request)`, `fetch_branch(repo, branch)` and `publish_repo(repo)`. Previews are visible to admins only, and new datasets get `status:"new"` until publish. [V]

**Everything here works without a shell, except that the help tells Claude to use git for `base`, the diff and the PR.** In chat, Claude knows exactly which files it wrote, so `files` is just those texts.

### 3b. Small additions needed for chat (Malloyyo product changes)

| Tool | Purpose | Why it's needed in chat |
|---|---|---|
| `read_repo_file(repo, path, ref?)` / `list_repo_files(repo, ref?)` | Read the existing model, `dashboards/*.malloy` and `malloy-config.json` through the instance's GitHub App | There's no clone in chat. The built-in GitHub integration can't be used in shared Projects. |
| `list_repos` → include the published branch **head SHA** | Use it as `base` | Replaces `git merge-base` |
| `propose_change(repo, label, base, files, deleted, title, body)` | The instance's GitHub App creates the branch, commits (author = the signed-in user, co-author = Claude) and opens a PR. It returns the PR URL, then runs `check_repo` automatically. | No git or GitHub connector needed; works for non-developers; one consistent identity |
| `update_change(pr, files, deleted)` | Push follow-up commits after review comments | Iteration |
| An **author** role, separate from admin | Lets non-admin modellers preview and propose (but not publish) | Today the preview tools are admin-only |
| Updated `yo_help("authoring/chat")` | The loop without git | Guidance |

Merge stays a human action on GitHub (or a `merge_change` tool that needs explicit confirmation and is "Needs approval" by default). Publish of a **new** dataset stays admin-only (`publish_repo`), as now.

*Alternative without product changes to the git side:* add GitHub's remote MCP server as a second connector and have Claude call `create_branch`, `push_files` and `create_pull_request` itself. That works for people with GitHub write access, but it's two sign-ins, the identities are split, and the docs say each host needs a GitHub OAuth app set up [S/U].

### 3c. Data loading (the hard part)

Constraints: tool arguments are generated tokens, and results are capped at about 150k characters. So **bytes of an attached file can't realistically go through a tool call** beyond toy sizes [U, inferred from limits]. Each tool call also has a 240s timeout.

Options, from the best fit downward:

1. **Signed upload URL + async load job (product change).** `create_upload(filename, size, dataset, table)` returns a short-lived signed URL (GCS or the instance). Claude's **code sandbox** `curl -T`s the attached file to it. `load_table(upload_id, dataset, table, schema[{name,type,description}], table_description, labels)` starts a BigQuery load job server-side and returns a `job_id`. `get_job(job_id)` polls the status. This requires the org's sandbox egress to allow the upload host. That isn't the default on Team (package managers only) or Enterprise (egress off), so an Owner adds the domain. File size is limited to about 30MB (sandbox) or 500MB (chat), depending on which page is right.
2. **MCP App upload widget (product change).** A tool renders a file picker. The browser uploads directly to the instance (`connectDomains`), so no sandbox egress is needed and files can be large. Whether a file input works inside Claude's sandboxed iframe is [U]. Prototype this first.
3. **Load from a URL or cloud location (product change, easy).** `load_table(source_uri = https://… | gs://… | Drive link)` is handled server-side. It covers public data and files already in GCS. For Drive, the instance would need its own Google access (the claude.ai Drive connector's token isn't shareable).
4. **BigQuery remote MCP `execute_sql` + `LOAD DATA FROM FILES(gs://…)`** with the person's own Google OAuth. This works only when the file is already in GCS, and the redirect-URI support is [U].

`create_dataset(name, description, labels)` and the read grant to the instance's service account should be part of the same tool family. They reproduce the `bigquery-data` skill's conventions server-side: one dataset per analysis, a description on every column, labels.

**Credentials for loading:**
- (a) **Instance-held service account** with BigQuery Data Editor on a dedicated "team data" project only, with the person's Malloyyo OAuth identity recorded in labels and the audit log. This is simple, but every author can write.
- (b) **Google OAuth passthrough:** the Malloyyo authorization server federates to Google with the `bigquery` scope and acts as the user. This is closer to today's "runs as the person", but more work.

Either way, the shared read-only key used for modelling never gets write access.

### 3d. End-to-end chat flow (target)

1. The person attaches `returns.csv`. Claude inspects it in the sandbox.
2. `create_dataset`, then `create_upload` + sandbox PUT (or the widget), then `load_table` with a described schema, then `get_job`.
3. `list_tables`/`describe_table`, then Claude asks what the model should answer.
4. Claude writes `datasets/returns/index.malloy` in the chat, then calls `preview_changes`. It checks the numbers with `query` against `…@label:returns` and shares the preview dashboard links.
5. `propose_change` opens a PR. `check_repo` runs. A human reviews and merges on GitHub.
6. An admin runs `publish_repo` (creating the dataset). The team then queries it through the normal read-only connector.

Project setup: a claude.ai Project per team, with custom instructions (the essentials of the repo's CLAUDE.md) and a **plugin** bundling the connector with Malloy skills. Project knowledge is fine for docs, but not for data (30MB limit, and it is put into the context).

### 3e. Separate MCP vs. Malloyyo changes

| Piece | Separate MCP server could do it | Needs Malloyyo |
|---|---|---|
| Compile and preview with live data | Yes: wrap `malloyyo mcp --develop` / the CLI server-side with a per-session working tree and the shared key. But it duplicates `preview_changes`, and its preview dashboards wouldn't be the instance's. | Already exists; just expose it |
| Read repo files, open PRs | Yes (GitHub App) | Better inside, because it reuses the instance's GitHub App and repo registry |
| Author role, per-user audit | Its own OAuth, separate from Malloyyo | Yes, for one identity and roles |
| Upload and load to BigQuery | Yes: a standalone "warehouse loader" MCP (signed URLs, load jobs, schema descriptions). This is also reusable without Malloyyo. | Optional |
| Create dataset on instance | No (needs instance admin API) | Yes (`publish_repo`, exists) |

## 4. Gaps and risks

- **File size:** 500MB chat versus 30MB sandbox/project (the docs conflict), and tool payloads are about 150k characters. Large or ongoing loads belong in a scheduled pipeline, not chat.
- **Long jobs:** the 240s tool timeout means load jobs and big previews must be async (job IDs plus polling). Chat has no background wake-up, so the person re-asks (or uses an MCP App that polls).
- **Sandbox egress:** the upload route needs an Owner to allowlist the instance or GCS host. Enterprise orgs default to egress off.
- **Secrets:** OAuth only. No `client_credentials`. Never put warehouse keys in chat, Project knowledge or tool arguments. Signed URLs should be single-use and short-lived. Static header keys (beta) are org-wide and anonymous, so they are unsuitable for authoring.
- **Permissions:** today the preview tools are admin-only, and preview dashboards are visible to admins only. A modeller role is needed. Load rights should be confined to one project. Write tools should default to "Needs approval".
- **Review and safety:** PR review stays the gate. `check_repo` catches drift from main. Merge and publish should never be automatic. Tool results containing warehouse rows are untrusted data (prompt injection).
- **Context:** `preview_changes` caps at 200 files and 512KB. Large repos need `fetch_branch` (which needs a pushed branch, which `propose_change` would provide).
- **Dashboards:** `dashboards/*.malloy` are currently only readable in the clone, so `read_repo_file` is needed for edits from chat.
- **Unverified items** to test before building: the file input in the MCP App iframe; artifacts calling connectors in claude.ai chat; the GitHub remote MCP via claude.ai OAuth; the BigQuery remote MCP as a claude.ai custom connector; the actual sandbox upload size limit.

## Sources

- Claude connectors: https://claude.com/docs/connectors/getting-started.md · https://claude.com/docs/connectors/building/index.md · https://claude.com/docs/connectors/building/authentication.md · https://claude.com/docs/connectors/building/mcp-apps/getting-started.md · https://claude.com/docs/connectors/building/mcp-apps/troubleshooting.md · https://claude.com/docs/connectors/github/index.md · https://claude.com/docs/extend/overview.md
- Claude files and sandbox: https://support.claude.com/en/articles/8241126-uploading-files-to-claude · https://support.claude.com/en/articles/12111783-create-and-edit-files-with-claude
- Malloyyo: `yo_help("authoring/start")` on https://george.malloyyo.com (read 2026-10-30)
- BigQuery MCP: https://docs.cloud.google.com/bigquery/docs/use-bigquery-mcp · LOAD DATA: https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/load-statements
- Looker / Toolbox: https://docs.cloud.google.com/looker/docs/connect-ide-to-looker-using-mcp-toolbox
- dbt: https://docs.getdbt.com/docs/dbt-ai/about-mcp
- Snowflake: https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-agents-mcp
- Databricks: https://docs.databricks.com/aws/generative-ai/mcp/managed-mcp
- MotherDuck: https://motherduck.com/docs/key-tasks/ai-and-motherduck/mcp-setup/ · https://motherduck.com/docs/sql-reference/mcp
- Neon: https://neon.com/docs/ai/neon-mcp-server · https://github.com/neondatabase/mcp-server-neon
- Supabase: https://github.com/supabase/mcp
- Cube: https://docs.cube.dev/docs/integrations/mcp-server · Omni: https://docs.omni.co/docs/ai/mcp
- GitHub remote MCP: https://github.com/github/github-mcp-server
- MCP Apps SDK: https://apps.extensions.modelcontextprotocol.io/api/documents/Patterns.html
