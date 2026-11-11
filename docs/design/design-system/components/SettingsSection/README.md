# SettingsSection

A titled group of settings rows on a `surface-container-low` card. Rows are a switch row, a value row that opens a picker (sound), or a link row (terms, privacy).

## Rules
- Section title in `title-small`, `primary`, 16 dp above the card.
- Card: `surface-container-low`, corner `corner-large`; rows 56 dp (72 dp with a supporting line), 16 dp side padding, 1 dp `outline-variant` dividers inset 16 dp.
- Switch row: label in `body-large`, M3 switch (`switch-width` × `switch-height`) labelled by the row text.
- Value row: label left, current value in `body-medium` `on-surface-variant`, chevron; opens a bottom sheet with radio options.
- Settings sections in v1: Chung (language, theme), Thông báo (sound, vibrate), Rằm, mùng 1 và lễ Tết (three switches), Thông tin (terms, privacy, version). Reminder time and days before live on each event, not here.

## States
Rows: Default, Pressed (whole row), Focused, Disabled (38 %, e.g. sound and vibrate when notifications are blocked by the system, with a line explaining why). Switches: Off, On.
