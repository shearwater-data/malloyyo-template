# Open-source Malloy skills

`.claude/skills/malloy-gotchas-modeling/` and `.claude/skills/malloy-queries/`
are copied from the open-source Malloy skills,
[`@malloy-publisher/skills`](https://www.npmjs.com/package/@malloy-publisher/skills)
0.1.47 (MIT, © Credible Data Inc.; source in
[malloydata/publisher](https://github.com/malloydata/publisher/tree/main/skills)).
Each has a short note at the top that maps Publisher's tool names to this
repo's.

They're the language-level ones: compile errors, dates, joins, aggregates, and
the mistakes SQL habits cause. The rest of that package is written for Malloy
Publisher's package layout and tools, which this repo doesn't use. Charts,
dashboards and documentation are covered by the instance's own `yo_help`.

To update, copy the two `SKILL.md` files from a newer version of the package
(`npm pack @malloy-publisher/skills`) and keep the note at the top.
