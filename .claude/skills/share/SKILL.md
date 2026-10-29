---
name: share
description: Share results, charts and dashboards from this model with colleagues - as a Claude artifact (live data from the instance where possible), an instance query link, a draft dashboard, or Malloy saved in the repo. Use when someone wants to show, share, send or keep a result, chart or dashboard, or asks how colleagues can see it.
---

# Share results

Four places a result can live. Pick by how long it needs to last:

| Where | Use it for | History |
| --- | --- | --- |
| **Claude artifact** | A quick, good-looking answer to pass around or discuss | None of its own; it links to the instance query it came from |
| **Instance query link** | The exact Malloy query and chart behind a number | One link per query |
| **Draft dashboard on the instance** | A live page with a link anyone with access to the instance can open, without a PR | Re-saved in place; promoted into the repo when it should last |
| **Malloy in the repo** (a named `view:` on a source, or a dashboard) | A question people will ask again: reviewed in a PR, the same numbers for everyone, and visible on the instance to people who don't use Claude | Full git history |

Default: answer with an **artifact plus the instance link**. When the same
question comes up again, or the person says "keep this", offer to save it as
Malloy in the repo through a PR. When they want a page colleagues can open
right away, offer a draft dashboard.

## Draft dashboards

`yo_help("dashboards/drafts")` is the guide: one React component with inline
Malloy, saved with `save_draft_dashboard`, which returns a URL to share.
Re-save with the returned `slug` to update it. Promote it into the repo when
it should last (below).

## Artifacts

Load the `artifact-design` skill before writing one, and
`artifact-capabilities` before giving it live data.

- **Live (preferred).** Declare the `mcp` capability with the instance
  connector's `query` tool. The page runs the Malloy query as each viewer, so
  everyone sees current numbers with their own access to the instance. Read the
  connector's `query` input schema in this session first, never guess it. Show
  when the data was fetched, and link to the instance query (`ltool_link` from a
  real run). For viewers who haven't connected the instance, show "Connect <instance> in
  claude.ai to see live numbers" instead of a blank chart.
- **Snapshot (fallback).** If the person or their viewers have no instance
  connector, embed the rows and label the page "Snapshot taken <date>" with the
  instance link for the live version.
- Do the work in Malloy: grouping, ordering and limits belong in the query, so
  the instance link reproduces exactly what the artifact shows.
- Draw the chart in the page. Malloy's own chart tags (`# bar_chart` etc.)
  drive the instance's renderer, not the artifact's.

Artifacts start private. Tell the person they can share the link with the
team from the artifact's share menu.

## Malloy in the repo

- A one-off question that's worth keeping becomes a named `view:` on its
  source, with a `#"` line saying what it answers. Add a chart tag when it
  should draw on the instance.
- A set of views people check regularly becomes a dashboard. Use
  `yo_help("repo/datasets")` for where it goes and how it's written, and
  preview it with `malloyyo dashboard dev -C datasets/<name>`.
- A dashboard drafted on the instance (a **draft dashboard**) is brought into the
  repo with `malloyyo draft promote <slug>`.
- Either way: commit on a branch, open a PR, never merge without asking.
  Once it's merged, the instance publishes it.

## Sessions

A cloud session can be shared with **Team** visibility from its menu. That's a
read-only snapshot, good for handing work over, not for working together live.
The repo, the instance and artifacts are where the shared work lives.
