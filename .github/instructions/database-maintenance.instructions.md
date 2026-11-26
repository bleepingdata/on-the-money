---
description: Rules for keeping deploy.ps1 and drop scripts in sync whenever database objects are created, renamed, or deleted. Apply when creating, editing, or reviewing any file under sql/, drop-scripts/, or deploy.ps1.
applyTo: "sql/**,drop-scripts/**,deploy.ps1"
---

# On The Money — Database Maintenance Rules

Any change that creates, renames, or deletes a database object under `sql/` is **incomplete** unless the drop scripts below are also updated in the same change.

## 1 — Deployment Discovery

`deploy.ps1` runs the CREATE scripts in each `sql/` folder in file-name order, so no registration is needed in the script. When adding or renaming files:

- Use numeric prefixes (`01_`, `02_`, …) wherever creation order matters within a folder (for example, tables that reference other tables, or views that depend on other views).
- Keep the prefix in step with the file's position in the dependency chain.

Do not add object lists to `deploy.ps1`; it must stay folder-driven.

## 2 — Keep Drop Scripts in Sync

Drop scripts live in `drop-scripts/database/` and must be executed in dependency order:

| Order | File | Object types |
|-------|------|-------------|
| 1st | `drop-views.sql` | Views (depend on tables — drop first) |
| 2nd | `drop-functions.sql` | Functions |
| 3rd | `drop-other-objects.sql` | Sequences |
| 4th | `drop-tables-and-schema.sql` | Tables and schemas (drop last) |

### What to do

| Event | Action |
|-------|--------|
| New object created | Add a `DROP … IF EXISTS` statement to the correct file |
| Object deleted | Remove its `DROP` statement from the correct file |
| Object renamed | Update the `DROP` statement to use the new name |

A change is incomplete if the drop scripts do not reflect the new database state.

## Scope of These Rules

Applies to objects defined under:
`sql/database/`, `sql/schema/`, `sql/tables/`, `sql/sequence/`, `sql/views/`, `sql/functions/`, `sql/default-data/`
