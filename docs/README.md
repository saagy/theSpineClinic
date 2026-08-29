# The Spine Clinic — Documentation

Welcome. This folder holds the engineering documentation for the Spine Clinic
app (Flutter + Riverpod + Supabase). The product brief is
[`PRODUCT.md`](../PRODUCT.md); the showcase README is
[`README.md`](../README.md).

## Start Here

1. **[Product Brief](../PRODUCT.md)** — who uses the app and the design principles behind it.
2. **[Architecture](architecture.md)** — layered design, data-flow contract, state management, routing.
3. **[Contributing](../CONTRIBUTING.md)** — environment setup, commands, and validation gates.

## Reference

| Document | Contents |
| --- | --- |
| [Database Overview](database-overview.md) | System-of-record orientation, migration history, database change workflow. |
| [Database Schema](database-schema.md) | Canonical tables, columns, enums, indexes, RPCs, triggers, RLS summary. |
| [Security Model](security-model.md) | Roles, RLS enforcement layers, staff application flow, repo safety rules. |
| [Testing](testing.md) | Dart suite layout and SQL sanity scripts. |
| [AGENTS.md](../AGENTS.md) | Engineering rules for humans and AI agents working in this repo. |

## Source of Truth

- **Database DDL**: [`supabase/full_schema.sql`](../supabase/full_schema.sql) — recreate the schema from scratch.
- **Migrations**: [`supabase/migrations/`](../supabase/migrations/) — incremental changes.
- Schema changes must update `full_schema.sql` and [database-schema.md](database-schema.md) together.
