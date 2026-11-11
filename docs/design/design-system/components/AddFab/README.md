# AddFab

The extended FAB "Thêm" on the upcoming list: the one primary action of that screen.

## Rules
- Height `fab` (56 dp), `corner-large`, shadow `elevation-level-3` (`elevation-level-4` when hovered or focused), background `primary`, content `on-primary` (the M3 primary FAB color style; set `backgroundColor`/`foregroundColor` from the scheme, because Flutter's default is primary-container, whose label contrast with this palette is below 4.5:1); icon plus label in `label-large`.
- Sits 16 dp from the end edge and 16 dp above the bottom inset (M3 FAB margin), on the list and on the calendar; shrinks to an icon-only FAB while the list scrolls down.

## States
Default; Pressed (state layer 10 %, elevation level 4); Focused (level 4 plus focus ring). Never disabled: it is hidden instead when adding is impossible.
