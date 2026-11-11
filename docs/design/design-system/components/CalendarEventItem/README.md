# CalendarEventItem

One event in the day list under the month view and inside a day row of the week view. Two kinds:

- **Anniversary** (user data): `surface-container-low` card, `outline-variant` border, a `anniversary-mark` dot, the name in `title-medium` (Lora), the reminder summary in `body-medium`, and a "Ngày giỗ" tag. Swipe left (right-to-left) reveals **Sửa** on the trailing side in `primary`; it opens the edit form. Swipe right (left-to-right) reveals **Xoá** on the leading side in `error`; it opens the ConfirmDialog before deleting. Reveal width 96 dp; a drag under 48 dp springs back.
- **Holiday** (system event: mùng 1, rằm, Tết): `holiday-container` card with `on-holiday-container` text, a `holiday-mark` dot and a "Ngày lễ" tag. Not swipeable and not editable.

## Rules
- Purple marks anniversaries and red marks holidays everywhere: grid dots, lunar numbers 1 and 15, list items, year tiles. Color is never the only signal: items carry a text tag, the grid has a legend.
- Swipe actions must also be reachable without a gesture: in Flutter use `Dismissible` or a `Slidable`-style row plus `Semantics(customSemanticsActions: {Sửa, Xoá})`, so TalkBack users can edit and delete.
- The home list is read-only; edit and delete live in the calendar.
- The year view has no item actions: tapping a month tile opens that month. Tiles keep a fixed height with three reserved lines (month, anniversary count, holiday count) so the grid stays aligned when a line is empty; only named festivals count as holidays there, not every mùng 1 and rằm.

## States
Anniversary: Default, Pressed, Dragged (state layer 16 % while swiping), Revealed (Sửa or Xoá visible), Deleting (Loading on the confirm button). Holiday: Default only.
