# SegmentedButton

Single-choice segmented button used in Settings for language (Tiếng Việt / English) and theme (Hệ thống / Sáng / Tối).

## Rules
- Height `button` (40 dp), outline 1 dp `outline`, corner `corner-full`, equal-width segments.
- Selected segment: `secondary-container` with `on-secondary-container` label, weight 600. Unselected: transparent, `on-surface`.
- Language names are always written in their own language, not translated.
- A change applies at once through `AppCubit` and is stored; there is no Save button.
- Flutter: `SegmentedButton<T>` with `showSelectedIcon: false`.

## States
Segment: Default, Pressed, Focused, Selected. Never disabled.
