# ADR 0001: Leap-month rule for yearly anniversaries

Status: Accepted (2026-11-04, decided by Fox). Scope: anniversary events on lunar dates.

## Context

Many families remember the day and month of a death but not the year. A lunar year sometimes has a leap month that repeats a month number (for example two "month 2" in a leap year), so a lunar date can be ambiguous. An anniversary must never disappear in a year that lacks the relevant leap month. Family customs for leap months vary, and no source confirmed a single common tradition.

## Decision

- Store `lunarDay` and `lunarMonth` (required) and `deathYear` (optional, never hard-validated).
- Store `diedInLeapMonth` only when `deathYear` is set and that year has a leap month with the same number as `lunarMonth`; otherwise it is ignored and stored as `false`. The UI shows the toggle only in that case.
- Month used in year Y: the regular month, unless `diedInLeapMonth` is true and year Y has a leap month with the same number, in which case that leap month.
- Day 30 in a 29-day month falls back to day 29.
- No manual per-event override in v1.

## Consequences

- Needs an engine query: "does lunar year Y have a leap month, and which number?" (see ADR 0002).
- An anniversary is always defined for every year.
- The rule reflects Fox's family practice, not a verified universal tradition. Confirm with relatives; revisit if they disagree.

## Alternatives considered

- Always use the regular month and ignore leap months: simplest, but loses the case where a person died in a leap month and the family follows it.
- Per-event override (regular, leap, both): flexible but adds UI and tests; deferred until the family asks for it.
