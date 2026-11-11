# ConfirmDialog

The Material 3 basic dialog used to confirm deleting an anniversary.

## Rules
- Background `surface-container-high`, `corner-extra-large`, padding `space-24`, over `scrim` at 32%. Elevation level 3 is shown by the surface-container-high color; no extra shadow.
- Title in `title-large` (Lora) naming the person: "Xoá ngày giỗ của Bà nội?"; body in `body-medium`, `on-surface-variant`, saying what happens.
- Actions are text buttons, right-aligned: "Giữ lại" (`primary`) then "Xoá" (`error`). Dismissing the dialog keeps the record.

## States
Buttons: Default, Pressed, Focused. Xoá shows Loading while the soft delete runs; both buttons are Disabled during that time and the dialog cannot be dismissed.
