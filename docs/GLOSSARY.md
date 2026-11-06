# Glossary

Domain vocabulary only. This file records meanings, not requirements. Vietnamese terms are kept so code, docs and conversations stay consistent.

| Term | Meaning |
|---|---|
| Lunar date (âm lịch) | A date in the Vietnamese lunar calendar: day, month and year. |
| Giỗ | Death anniversary, held yearly on the lunar date of the death. The core event type of Evermoon. |
| Tiên thường | An offering some families hold the day before the main anniversary. Not supported in v1: the app reminds on the exact anniversary day only. |
| Leap month (tháng nhuận) | An extra month added in some lunar years that repeats a month number. In the reference algorithm it is the first month without a major solar term (trung khí). |
| Regular month (tháng thường) | The non-leap month with a given number. Default month for anniversaries (see ADR 0001). |
| Sóc | The new moon. The lunar day 1 (mùng 1) is the day containing the new moon, computed in UTC+7. |
| Trung khí | A major solar term (principal term). A month containing none is the leap month. |
| Đông chí | The winter solstice. The lunar month containing it is month 11 in the reference algorithm. |
| Mùng 1 | The first day of each lunar month. A system event that users can toggle. |
| Rằm | The 15th day of each lunar month. A system event that users can toggle. |
| Tết | The lunar new year and other traditional festivals. System events that users can toggle. |
| System event | A built-in lunar event (mùng 1, rằm, Tết festivals) that users toggle but do not create. |
| `diedInLeapMonth` | Flag on an anniversary: the person died in a leap month. Meaningful only when the death year is known (see ADR 0001). |
