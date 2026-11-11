# Plan 0004: Anniversary entity and local storage (A3)

Status: Done (2026-11-06). UI and reminders follow in later plans. Requirements owner: Fox. Tracker: pending (no tracker chosen yet).

## Outcome

Anniversaries can be created, read, updated, soft-deleted and watched as a live list, stored offline on the device with stable IDs, ready for sync later. No UI and no reminders in this plan.

## Decisions

| ID | Decision                                                                                                                                                                                           | State          |
|----|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------|
| D1 | Database: Drift (ADR 0003)                                                                                                                                                                         | Decided by Fox |
| D2 | Entity fields v1: `id` (UUID v4), `name`, `AnniversaryDate` (day, month, optional death year, leap flag), optional `note`, `reminderEnabled` (default true), `createdAt`, `updatedAt`, `deletedAt` | Decided        |
| D3 | Deceased profiles (relationship, burial place, offerings) stay deferred (product brief)                                                                                                            | Decided        |
| D4 | The repository normalizes the leap flag on every write through `AnniversaryResolver.normalize`, so stored data always follows ADR 0001                                                             | Decided        |
| D5 | Timestamps come from an injected clock (UTC) so tests are deterministic                                                                                                                            | Decided        |
| D6 | Delete is soft (`deletedAt`); reads and the live list exclude deleted rows                                                                                                                         | Decided        |

## Acceptance criteria

- ST-1: `create` assigns a new UUID and equal `createdAt` and `updatedAt` from the clock; the record appears in `watchAll` and `findById`.
- ST-2: `update` keeps `id` and `createdAt`, sets `updatedAt` from the clock and persists every field.
- ST-3: `delete` sets `deletedAt` and `updatedAt`; the record leaves `watchAll` and `findById` but the row stays in the table.
- ST-4: A leap flag that cannot apply (no death year, or the death year has no leap month with that number) is stored as `false`; a valid one is kept.
- ST-5: `watchAll` emits a new list after each write.
- ST-6: The table rejects a lunar day outside 1 to 30 or a month outside 1 to 12.
- ST-7: Tests use an in-memory database and a fake lunar calendar; no mocks of the database.

## Slices

| Slice | Content                                                                                                    | Status                                                                                                                   |
|-------|------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| B1    | Dependencies (`drift`, `drift_flutter`, `drift_dev`, `uuid`), `AppDatabase` with the `anniversaries` table | Done: resolved `drift` 2.34.4, `drift_dev` 2.34.0, `drift_flutter` 0.3.1; `build_runner` generated `app_database.g.dart` |
| B2    | `Anniversary` entity, `AnniversaryRepository` interface and Drift implementation, getter                   | Done: `fvm flutter analyze` no issues                                                                                    |
| B3    | Repository tests (ST-1 to ST-7)                                                                            | Done: 8 repository tests pass; full suite 34 pass                                                                        |

## Verification

```bash
fvm flutter pub get
fvm dart run build_runner build
fvm flutter analyze
fvm flutter test
```

Expected: `build_runner` writes `lib/storage/database/app_database.g.dart`; `analyze` reports no issues; all tests pass, including `test/repositories/`.

## Notes

- Drift's `check(column.isBetweenValues(...))` pattern trips the `recursive_getters` lint; it is suppressed on those two lines with a reason, because the generator reads the getter symbolically.
- Checks were run by Claude on Fox's Mac through the terminal access Fox granted on 2026-11-06.

## Risks

- Dependency resolution: `drift_dev` must agree with the `analyzer` and `build_runner` versions already pinned by `retrofit_generator` and `json_serializable`. If `pub get` fails, adjust the version ranges, not the other generators.
- The schema is version 1. Any later column change needs a migration step and a test.
