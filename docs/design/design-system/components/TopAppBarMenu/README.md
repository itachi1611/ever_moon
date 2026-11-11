# TopAppBarMenu

Top app bar of every top-level screen (list, calendar, settings): the menu button followed by the screen title. Detail screens (add, edit) use a back button instead.

## Rules
- Menu button: 48 dp touch target, `menu` icon in `on-surface`, accessible label "Mở menu" / "Open menu". It sits 12 dp further out than the 20 dp content margin so the icon lines up with the content.
- Title in `headline-small` (Lora). An optional summary line under it in `body-medium`, `on-surface-variant` (for example "4 người · 1 ngày giỗ hôm nay").

## States
Menu button: Default, Pressed, Focused.
