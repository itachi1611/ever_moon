# LunarDayCell

One day in the month grid of the calendar: the solar date with the lunar day under it.

## Rules
- Solar date in `body-large`; lunar day in `label-small`, `outline`. On mùng 1 show "1/N" (N = lunar month).
- Mùng 1 and rằm: lunar day in `holiday-mark` and bold, so they read without color.
- Under the numbers, up to two 6 dp dots: `anniversary-mark` for an anniversary, `holiday-mark` for mùng 1, rằm or a Tết festival.
- The selected day (not today) gets a 2 dp `primary` outline; its events are listed under the grid.
- Today: the whole cell filled with `primary` (`corner-medium`), numbers and dots in `on-primary`.
- Sundays: solar date in `primary`.
- Each cell is at least 48 dp tall and is one tap target that lists that day's anniversaries.

## States
Default, Pressed, Focused, Selected (2 dp `primary` outline), Today (filled `primary`). Days outside the month are empty and not tappable.
