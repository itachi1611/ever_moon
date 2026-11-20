# Plan 0003: `LunarCalendarService` and the anniversary resolver

Status: A1 and A2 done (2026-11-06); A3 is plan 0004 (done) and A4 is plan 0006 (implemented, see its status). Requirements owner: Fox. Tracker: pending (no tracker chosen yet).

## Outcome

The app can answer, for any anniversary stored as lunar day and month (plus an optional death year and leap flag), "on which Gregorian date does it fall in lunar year Y?" and "when is the next occurrence from today?", following ADR 0001. The app reaches the lunar engine only through its own `LunarCalendarService` interface (ADR 0002). No UI, storage or reminders in this plan.

## Decisions

| ID | Decision                                                                                                                                                      | State   |
|----|---------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|
| D1 | The resolver lives in the app, not in `packages/lunar_calendar` (plan 0001, D4)                                                                               | Decided |
| D2 | `LunarCalendarService` is an interface with one engine-backed implementation; features use the top-level getter `lunarCalendarService`                        | Decided |
| D3 | The service re-exports the package's `LunarDate` value instead of a duplicate app type; features import only the service file, never `package:lunar_calendar` | Decided |
| D4 | `diedInLeapMonth` is normalized to `false` unless the death year is known and has a leap month with the same number (ADR 0001)                                | Decided |
| D5 | Anniversary entity, persistence and stable IDs are out of scope; the resolver works on a value type `AnniversaryDate` that the future entity will carry       | Decided |

## Acceptance criteria

- AR-1: No death year, or `diedInLeapMonth` false: the regular month of year Y is used.
- AR-2: `diedInLeapMonth` true and year Y has a leap month with the same number: the leap month is used.
- AR-3: `diedInLeapMonth` true and year Y has no such leap month: the regular month is used (the anniversary never disappears).
- AR-4: Day 30 in a 29-day month falls back to day 29; any other non-existent day is not shifted.
- AR-5: `canBeLeapMonth` is true only when the death year has a leap month with the same number; normalization clears the flag otherwise.
- AR-6: `nextOccurrence` returns today when the anniversary is today, otherwise the first later date; `null` only outside the engine's range.
- AR-7: Features import `lunar_calendar` only through `lib/services/lunar/`.
- AR-8: Tests use a fake service for the rules and oracle fixtures for the integration check; no expected solar date comes from memory or from the code under test.

## Slices

| Slice | Content                                                                                            | Status                                                                                                          |
|-------|----------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| A1    | Path dependency on `lunar_calendar`; `LunarCalendarService`, `EngineLunarCalendarService`, getter  | Done: Fox ran `fvm flutter pub get` (`lunar_calendar` resolved from path) and `fvm flutter analyze` (no issues) |
| A2    | `AnniversaryDate` value, `AnniversaryResolver`, tests (fake service and fixture-based integration) | Done: `fvm flutter test`, 19 pass (3 routing, 16 in `test/services/lunar/`)                                     |
| A3    | Anniversary entity with stable ID and local persistence                                            | Plan 0004                                                                                                       |
| A4    | Local reminders on the exact day (ADR 0001, reminders v1)                                          | Later plan                                                                                                      |

## Verification

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

Expected: `analyze` reports no issues; all tests pass, including `test/services/lunar/`.

## Notes

- `pub get` reported `intl_utils` as discontinued. Replaced on 2026-11-06 by Flutter `gen-l10n` (`l10n.yaml`): same import `lib/generated/l10n.dart` and class `S`, `nullable-getter: false`. `S.current` does not exist in gen-l10n, so `onValidate` and `NotifyType.title`/`message` now take an `S` argument and the setting page uses `S.of(context)`. The template's `onValidate` rejected every non-empty value (inverted `isValidate` check); fixed and covered by `test/utils/app_validator_test.dart`. The Localizely `flutter_intl` block was removed from `pubspec.yaml`.

## Risks

- The leap-month custom is Fox's family practice, not a verified tradition (ADR 0001 open question). The rule is isolated in one method so it can change.
- The engine computes months on first use; the first call in a session costs a few milliseconds per lunar year. Not measured on a device yet.
