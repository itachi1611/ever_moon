# AnniversaryCard

One anniversary in the upcoming list: a lunar date badge, the person's name, the lunar and solar dates, and the countdown.

## Anatomy
- Date badge (`date-badge-width` x `date-badge-height`, `corner-medium`): lunar day in `title-large`, "tháng N" in `label-medium`. Add "nhuận" when the anniversary falls in a leap month this year.
- Name in `title-medium` (Lora), one line, ellipsis after two lines at large text sizes.
- Lunar date and solar date with weekday in `body-medium`, `on-surface-variant`.
- Countdown: number in `title-large`, `primary`; "ngày nữa" in `label-medium`.

## States
- Default: `surface-container-low`, 1 dp `outline-variant` border, `corner-medium`, padding `space-16`.
- Today: `today-container` background with no border, name in `on-today-container`, date lines in `on-today-container-variant`, badge in `primary`/`on-primary`, and a "Hôm nay" chip (`corner-full`) instead of the countdown.

## The widget provides
Name, the resolved lunar date for this year (from AnniversaryResolver), the solar date, days left. The card is read-only on the home list (plan 0005 D15): no tap action, no swipe; edit and delete happen in the calendar. Its semantics label reads name, lunar date, solar date and countdown in one sentence.
