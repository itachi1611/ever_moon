# LeapMonthToggle

The "Mất vào tháng N nhuận" switch on the add/edit form, shown only when the entered death year has a leap month with the selected number (ADR 0001).

## Rules
- Visibility comes from `AnniversaryResolver.canBeLeapMonth(deathYear, lunarMonth)`. Changing the year or month so it no longer applies hides the row and clears the flag.
- Container: `today-container` with `on-today-container` text and `on-today-container-variant` for the explanation, `corner-medium`, padding `space-16`, so it stands out as an extra question.
- Title in `title-small`, explanation in `body-medium`: "Năm này có hai tháng 4. Bật nếu người mất trong tháng nhuận."
- Material 3 switch (52 x 32), off by default; the whole row toggles it and carries the switch semantics.

## States
Switch: Off, On, Pressed, Focused, Disabled (while the form is saving). Hidden, not disabled, when the rule does not apply.
