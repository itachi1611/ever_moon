# ViewSwitch

The Năm / Tháng / Tuần switch at the top of the calendar: a Material 3 segmented button with three single-select segments.

## Rules
- The same M3 outlined segmented button as SegmentedButton: height `button` (40 dp), 1 dp `outline` border, `corner-full`, equal segments split by 1 dp `outline` dividers; selected segment `secondary-container` with `on-secondary-container` text (weight 600), others `on-surface`. No check icon (`showSelectedIcon: false`), so the labels never shift.
- Labels in `label-large`. Each segment is at least 48 dp tall.
- The chosen view is remembered per session.

## States
Segment: Default, Pressed, Focused, Selected.
