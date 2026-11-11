# NavigationDrawer

The Material 3 modal navigation drawer, the app's only navigation (plan 0005 D13). Three destinations: Ngày giỗ, Lịch, Cài đặt. Terms and privacy are not in the drawer; they live in Settings.

## Rules
- Opened from the menu button (48 dp touch target, `menu` icon, label "Mở menu") at the start of the top app bar of each top-level screen. Closes on scrim tap, back gesture, or after choosing a destination.
- Width `navigation-drawer-width` (316 dp), background `surface-container-low`, corner `corner-large` on the end side only, scrim `scrim` at 32 %.
- Header: the E8 app mark (40 dp, corner 10) with "Evermoon" in `title-large` (Lora), then a "today" card on `surface-container-high` (corner `corner-large`): a lunar day badge in `primary` / `on-primary`, the label "HÔM NAY", the lunar date in `title-medium` and the solar date in `body-medium`. The lunar date comes from `LunarCalendarService`.
- Destination height `drawer-item` (56 dp), full-pill indicator in `secondary-container`; selected icon and label `on-secondary-container`, label weight 600; others `on-surface-variant`.
- A trailing badge (for example "1 hôm nay") uses `label-large`; keep it to a short count.
- Flutter: `NavigationDrawer` with `NavigationDrawerDestination`, `selectedIndex` from the router; never push routes from the drawer, use `context.go`.

## States
Destination: Default, Pressed, Focused, Selected (`secondary-container`). The today card is not interactive.
