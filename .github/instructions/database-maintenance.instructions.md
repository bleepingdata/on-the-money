---
description: Rules for keeping the database init script and drop scripts in sync whenever database objects are created, renamed, or deleted. Apply when creating, editing, or reviewing any file under sql/, drop-scripts/, or initialisation/.
applyTo: "sql/**,drop-scripts/**,initialisation/**"
---

# On The Money — Database Maintenance Rules

Any change that creates, renames, or deletes a database object under `sql/` is **incomplete** unless the two downstream files below are also updated in the same change.

## 1 — Keep `initialisation/database-init.ps1` in Sync

`initialisation/database-init.ps1` runs all CREATE scripts at setup time. It must:

- **Include** any newly created object's script.
- **Remove** any reference to a deleted or renamed object.

A change is incomplete if the init script still references deleted objects or does not include newly required ones.

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
