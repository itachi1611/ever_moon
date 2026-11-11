# ADR 0003: Local database (Drift)

Status: Accepted (2026-11-06, chosen by Fox from the options in plan 0004).

## Context

Evermoon v1 is offline-first: anniversaries live on the device and must survive restarts. Later, an optional login adds backup and sync (last write wins by `updatedAt`, deletes as `deletedAt`) and family groups. The template only has key-value stores (`shared_preferences`, `get_storage`), which suit settings, not records that need queries, migrations and change notifications.

Options checked on pub.dev on 2026-11-06: `drift` 2.35 (about 2.5k likes, 1.9M downloads), `sqflite` 2.4.5 (about 5.6k likes), `hive_ce` 2.22 (community continuation of Hive 2). The original `isar` 3.1 has little remaining use (about 4k downloads); a community fork exists.

## Decision

- Use Drift (SQLite) with `drift_flutter` for opening the database and `drift_dev` for code generation through the existing `build_runner`.
- One database, `AppDatabase`, in `lib/storage/database/`. Features reach it only through repositories in `lib/repositories/`.
- Every record has a client-generated UUID v4 primary key, `createdAt`, `updatedAt` (UTC) and a nullable `deletedAt` for soft deletes, so sync can be added without changing IDs.
- Invariants that the database can enforce are enforced there too (lunar day 1 to 30, month 1 to 12).

## Consequences

- Typed tables, schema versions with migrations, and reactive queries for the list screen.
- Tests run against an in-memory SQLite database, not mocks.
- Generated code (`*.g.dart`) is gitignored: after a fresh clone or a table change, run `fvm dart run build_runner build` before `analyze` and `test`.
- Schema changes (from v2, plan 0005 U2a): bump `schemaVersion`, run `fvm dart run drift_dev make-migrations`, write the new step in `AppDatabase.migration` and fill in the data test in `test/drift/app_database/migration_test.dart`. The snapshots in `drift_schemas/`, `app_database.steps.dart` and `test/drift/` are committed; the configuration is in `build.yaml`. `drift` and `drift_dev` must move together (2.35.x since 2026-11-11; drift_dev 2.34.0 did not compile against drift 2.34.4).
- Soft-deleted rows stay in the table until a later cleanup or sync step removes them.

## Alternatives considered

- `sqflite`: most used, no code generation, but handwritten SQL and mapping, manual migrations and change streams, and `sqflite_common_ffi` for tests.
- `hive_ce`: quickest to start, but weak querying and no real schema migrations, which matter once sync and groups arrive.
- `isar`: original package is largely abandoned; the fork adds a dependency on a smaller community.
