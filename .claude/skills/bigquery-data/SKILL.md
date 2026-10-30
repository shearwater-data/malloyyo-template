---
name: bigquery-data
description: Create BigQuery datasets and load data (CSV, JSONL or Parquet, from a file or URL) into the team's data project the documented way - one dataset per analysis, consistent names, an explicit schema with a description on every column, dataset and table descriptions, labels, and read access for the Malloyyo instance. Use whenever someone wants to upload, load, import or add data to BigQuery, or create a dataset or table.
---

# Load data into BigQuery

Everything goes into the team's **data project** (`dataProject` in
`.claude/bigquery-data.json`). It runs as the person, so they need a Google
sign-in first (`google-login` skill). The shared key is read-only and can't
load data.

Use `.claude/bin/bq-data`. It refuses a load whose schema is missing a
description or has a badly named column, so do the work up front.

## Conventions

- **One dataset per analysis.** Name it for the subject, in lowercase
  snake_case, with no dates or people's names, e.g. `co2_emissions`. When it
  backs a Malloy dataset, use the same name as `datasets/<name>/`.
- **Dataset description:** what it holds, why it exists, and where the data
  comes from. **Labels:** the defaults from `.claude/bigquery-data.json`, plus
  `purpose=<analysis>`.
- **Table names** say what one row is, in snake_case: e.g. `country_years`
  for one row per country and year. Keep the source's data as loaded; derive
  in Malloy, not by editing the table.
- **Table description:** what one row is, the source URL, its licence, and
  the date it was retrieved.
- **Columns:** snake_case; explicit types (`DATE` for dates, `INT64` for
  counts, `FLOAT64` for measurements); every column has a description,
  including units (e.g. "Annual CO2 emissions, million tonnes"). If the
  source publishes a codebook, use it for the descriptions.

## Steps

1. Agree the dataset and table names with the person, following the
   conventions above.
2. Create the dataset. This also gives the instance's service account read
   access, so the published model can read it:

   ```bash
   .claude/bin/bq-data create-dataset <dataset> --description "<what, why, source>" --label purpose=<analysis>
   ```

3. Write the schema as JSON in the session's scratch directory (not the
   repo): a list of `{"name", "type", "description"}` matching the file's
   columns, in order.
4. Load. A URL is downloaded first; `--replace` overwrites an existing table.
   It prints progress while it uploads and gives up after 15 minutes, so run
   it in one command with a long timeout (10 minutes) and nothing chained after:

   ```bash
   .claude/bin/bq-data load <dataset>.<table> <file-or-url> --schema <schema.json> --description "<one row is …; source; licence; retrieved YYYY-MM-DD>"
   ```

5. Check it: `.claude/bin/bq-data describe <dataset>.<table>` (row count,
   descriptions), and spot-check a few numbers with
   `malloyyo sql bigquery -e "…"` against the source.
6. In Malloy, refer to it by its full name:
   `bigquery.table('<dataProject>.<dataset>.<table>')`.

## If something fails

- **No Google sign-in:** use `google-login`.
- **"Access Denied" or "permission":** the person needs **BigQuery Data
  Editor** and **BigQuery Job User** on the data project (README step 7).
- **The instance can't read it after publishing:** run `bq-data describe
  <dataset>` and check "instance can read". Creating the dataset with
  `bq-data` sets this.
