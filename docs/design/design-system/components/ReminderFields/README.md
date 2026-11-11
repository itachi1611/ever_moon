# ReminderFields

The reminder block of the add and edit form (plan 0005, D9): a switch, the days-before choice, the reminder time and a one-line summary.

## Rules
- Card `surface-container-low`, corner `corner-large`, 16 dp padding. Title row "Nhắc tôi" in `title-medium` with a switch.
- When the switch is off, everything below is hidden (not just disabled) and the stored values are kept.
- Days before: filter chips Đúng ngày / 1 ngày / 3 ngày / 7 ngày, one selected (`secondary-container`), height `chip`, touch target 48.
- Reminder time: an outlined field (`text-field` height, `corner-extra-small` like every text field) with a clock icon, label "Giờ nhắc", value in `title-medium`; opens the M3 time picker. Default 07:00.
- Summary in `body-medium`, `on-surface-variant`: "Nhắc lúc 07:00, 3 ngày trước (Thứ Ba, 03/11)." The date comes from the resolver, never typed.

## States
Switch: Off (fields hidden), On. Chips: Default, Pressed, Selected. Time field: Default, Pressed, Focused (2 dp `primary` outline while the time picker is open). Whole block Disabled while saving.
