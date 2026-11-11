# Technical analysis: lunar calendar engine

Date: 2026-11-05. Decision recorded in [ADR 0002](adr/0002-lunar-engine-and-time-zone.md).

## Requirement

Vietnamese lunar calendar (UTC+7), lunar years 1800 to 2199, with a leap-month query, running offline on Android and iOS.

## Options evaluated

| Option                                              | Notes                                                                            | Verdict                |
|-----------------------------------------------------|----------------------------------------------------------------------------------|------------------------|
| `vnlunar` (BSD-3)                                   | Covers 1800 to 2199; exposes `Lunar.date(...leapMonth)`. Low adoption.           | Comparison target only |
| `full_calender` (MIT)                               | Leap-month support unconfirmed.                                                  | Comparison target only |
| `lunar`, `tyme`, `chinese_lunar_calendar`           | Chinese calendar (UTC+8); can differ from the Vietnamese calendar on some dates. | Excluded               |
| `lunar_calendar`, `vietnam_holidays` (pub.dev, old) | Outdated.                                                                        | Excluded               |
| Own pure-Dart package                               | Full control, API shaped to ADR 0001, verifiable. More code to own.              | Chosen                 |

Adoption and activity figures were read from the pub.dev API at the time of the analysis and can change.

## Algorithm

Published rules of Dr. Hồ Ngọc Đức: day 1 is the local (UTC+7) day containing the new moon; the month containing the December solstice (sun longitude 270 degrees) is month 11; 13 months between consecutive month 11s means a leap year; the leap month is the first month after month 11 without a principal term (sun longitude multiple of 30 degrees).

Own implementation: Meeus chapter 49 new moon, truncated VSOP87 Earth series, Espenak and Meeus Delta T, low-accuracy aberration and nutation.

## Verification strategy

- Independent oracle in Python (`astronomy-engine`), no shared code with the implementation.
- Published anchors from the author's tables (1984, 1985) and Tết dates (1985, 2007, 2030, 2053).
- Boundary list: events within 180 s of local midnight and months whose structure changes under plus or minus 180 s.
- Cross-implementation comparison with `vnlunar` and `full_calender` (optional, S4).

## Licensing

The author's JavaScript is the best-known reference, but its license could not be confirmed (the author's pages returned no license text). We therefore implement from the published rules and public astronomical formulas, and never copy or translate the original code. Published rules and facts are not code, so using them is not copying.

## Known limits

- Edge cases within about a minute of local midnight depend on the convention; 13 months in 6 years differ from the oracle (see ADR 0002).
- Delta T extrapolation uncertainty grows toward 2199.
- No official calendar source has been used as an anchor yet (D6).
