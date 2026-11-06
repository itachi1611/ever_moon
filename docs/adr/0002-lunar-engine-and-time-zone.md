# ADR 0002: Lunar calendar engine, time zone and verification

Status: Accepted (2026-11-05). Supersedes the earlier "library pending" state: the engine is our own package.

## Context

The Vietnamese lunar calendar depends on the time zone, so Chinese-calendar results (UTC+8) can differ on some dates; the rules' author lists 1985 and, for Tết, 2007, 2030 and 2053. A widely used Vietnamese reference algorithm is the one by Dr. Hồ Ngọc Đức, and published Dart packages for it have low adoption. Community sources note that such algorithms can differ from the official calendar by one day in rare edge cases. A wrong anniversary date destroys trust in the app. The license of the original JavaScript could not be confirmed.

## Decision

- Use the Vietnamese lunar calendar rules with time zone UTC+7. Do not use a Chinese-calendar library.
- Implement our own pure-Dart package `packages/lunar_calendar` from the published rules and astronomical formulas (Meeus, VSOP87 truncated, Espenak and Meeus Delta T). Do not copy or translate the original JavaScript.
- Supported lunar years: 1800 to 2199. Non-existent dates and out-of-range input return `null`; no exception and no guessed date.
- Convention for events within about a minute of local midnight: follow the author's published tables (Meeus new moon, no extra aberration term). The oracle uses the apparent conjunction and disagrees on 13 months in six years (1938, 1944, 1967, 2077, 2085, 2174 to 2175, none between 1990 and 2060); they are pinned in `convention_differences.json` and documented as convention-dependent.
- The app accesses the engine only through our own `LunarCalendarService` interface.
- Verify against the independent oracle in `tools/lunar_oracle/` (third-party astronomy library) and published anchors. Expected values never come from memory or from the implementation under test.
- Do not use the "year modulo 19" shortcut in code.

## Consequences

- More code to own and verify than adopting a package, but no single-maintainer dependency and an API shaped to our needs (leap-month query, existence checks).
- Dart cannot be run in the author's sandbox; Dart tests are run locally with `fvm dart test`. Python tools are the executable reference for the port.
- Far-future results depend on the Delta T model, whose uncertainty grows with the distance from the present.
- The official published source for Tết dates is still open (see the plan).

## Results (2026-11-06)

The decision was implemented in plan 0001, slices S0 to S3. Evidence:

- Python reference (`ours.py`) against the oracle: new moons differ by a mean of -34.9 s (max 55.6 s), principal terms by at most 63.0 s. The mean offset is the aberration convention described above.
- The Dart port reproduces `ours.py`: its periodic-term table and Delta T match to 5e-10 days and 2e-12 s, and a Python mirror of the Dart month builder produced all 4948 expected months before the Dart tests ran.
- Dart tests (`fvm dart test`, run by Fox, 18 pass) assert: event bounds against the oracle, all months except the 13 pinned ones, leap months, the author's anchors (Tết 1985, 2007, 2030, 2053; 1984 and 1985 tables), a round trip on every month, and `null` for out-of-range or non-existent input.
- Mutation check: with UTC+8 instead of UTC+7, 8 tests fail, including Tết 1985, which moves to the Chinese date 1985-02-20. The tests therefore detect the time-zone error this ADR exists to prevent.
- Months are computed on demand per span (month 11 to the next month 11) and cached, which keeps the run-time computation of decision D1 cheap enough for the app.

## Alternatives considered

- Adopt `vnlunar` or `full_calender`: less work, but low adoption and unconfirmed leap-month support (see the technical analysis). They remain optional comparison targets.
- A Chinese-calendar library: wider availability, but the UTC+8 basis can differ on some dates.
- Ship a generated table instead of computing at run time: lower port risk; declined by the user in favor of run-time computation.
- Follow the oracle's apparent-conjunction convention: more rigorous astronomically, but disagrees with the author's tables and the apps derived from them on edge cases, and neither is verified against an official calendar.
