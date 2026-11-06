# Plan 0001: `lunar_calendar` package

Status: In progress (S1, S2 done; S0 ready; S3 blocked on a local Dart SDK). Requirements owner: Fox. Tracker: pending (no tracker chosen yet).

## Outcome

A pure-Dart package `packages/lunar_calendar` that converts between solar and Vietnamese lunar dates (UTC+7) for lunar years 1800 to 2199, exposes the leap-month query needed by ADR 0001, and is verified against an independent oracle. The app integration comes later, behind `LunarCalendarService`.

## Decisions

| ID | Decision | State |
|---|---|---|
| D1 | Astronomy computed in Dart at run time (not a generated table) | Decided: A |
| D2 | Supported range: lunar years 1800 to 2199 | Decided |
| D3 | Package name `lunar_calendar` | Decided |
| D4 | Anniversary resolver (ADR 0001) lives in the app, not the package | Proposed |
| D5 | SDK constraint for the package `pubspec.yaml` | Decided: `>=3.10.0 <4.0.0`, same as the app; `.fvmrc` is `stable` (lock requires Dart 3.12, Flutter 3.44) |
| D6 | Official published source for Tết dates, for an extra anchor | Open |
| D7 | Convention for events within about a minute of local midnight | Decided: author's convention (Meeus new moon, UTC+7), see ADR 0002 |

## Acceptance criteria

- LC-1: For every month in `oracle_months.json` (lunar years 1800 to 2199), the Dart engine returns the same start date, length, leap flag and leap month, except the 13 months pinned in `convention_differences.json`, where it follows the author's convention.
- LC-2: Published anchors in `anchors.json` pass (1984 and 1985 event tables, 1985 leap span, 1984 with no leap month, Tết 1985, 2007, 2030 and 2053).
- LC-3: `leapMonthOf(year)` returns the leap month number or `null`, consistent with the oracle's `leap_months`.
- LC-4: Out-of-range or non-existent input returns `null`; no exception and no guessed date.
- LC-5: No code is copied or translated from the original JavaScript; expected values come only from fixtures.

## Slices

| Slice | Content | Status |
|---|---|---|
| S0 | Scaffold `packages/lunar_calendar` (pubspec, analysis options, lib, test) | Ready to start |
| S1 | Oracle generator `tools/lunar_oracle/oracle.py`, fixtures, anchors, boundary list (tests ORC-001 to 010) | Done |
| S2 | Independent Python implementation `ours.py` and `compare.py` (tests ORS-001 to 007) | Done |
| S3 | Dart port of `ours.py` plus Dart tests reading the same JSON fixtures | Blocked: no Dart SDK in the sandbox |
| S4 | Differential run against `vnlunar` and `full_calender` (optional comparison) | Not started |
| S5 | Docs: ADR 0002 update, package README, workflow guide and standards refresh | Not started |

## Progress

- S1 done. Oracle uses `astronomy-engine==2.1.19` (SearchMoonPhase, SearchSunLongitude). Fixtures: `oracle_months.json` (4948 months, 148 leap years), `oracle_events.json`, `anchors.json`, `boundary_cases.json` (37 near-midnight events, 45 structural differences under a plus or minus 180 s sensitivity, 25 affected lunar years), `convention_differences.json`. Python tests: 10 pass.
- S2 done. `ours.py` (Meeus chapter 49 new moon, truncated VSOP87, Espenak and Meeus Delta T, low-accuracy aberration and nutation) differs from the oracle by a mean of 34.9 s on new moons (max 55.6 s) and at most 63.0 s on principal terms. 13 of 4948 months differ from the oracle (the convention-dependent set, D7). 7 Python tests pass; 17 in total.
- The author's 1985 table has a cell inconsistent with UTC+7 (principal term 1985-02-18T17:07:26). It is recorded in `anchors.json` under `known_source_inconsistencies`; ORC-002 skips it and ORC-010 asserts it is real.
- S3 is blocked: the Dart SDK download from the sandbox is rejected by the network allowlist (HTTP 403). Dart tests are run locally by Fox with `fvm dart test`.
- D7 decided by Fox's delegation: follow the author's convention, since it matches the author's published tables within 2.2 s and the apps derived from them.

## Verification

- Python: `tools/lunar_oracle/` tests, run with `python -m pytest` after `pip install -r requirements.txt`.
- Dart (after S0 and S3): `fvm dart analyze` with zero warnings, then `fvm dart test` in `packages/lunar_calendar`. Tests load the JSON fixtures; none hardcodes an expected solar date.
- Defect detection: a mutation check (for example shifting the time zone to UTC+8) must fail the 1985 and Tết anchors.

## Risks

- Far-future results depend on the Delta T model.
- The author's convention and the apparent-conjunction convention disagree on 13 months; neither is verified against an official calendar.
- The Python reference cannot prove the Dart port correct; only the Dart tests can.

## Next action

S0 scaffold, then S3 with local `fvm dart test`. Template cleanup is tracked separately in plan 0002.
