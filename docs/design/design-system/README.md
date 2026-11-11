# Evermoon

Evermoon reminds a Vietnamese family of its death anniversaries (giỗ), which follow the lunar calendar, on the right day each year. This system is the visual language of the Android app (Flutter, Material 3). It is built from Fox's Material Theme Builder export (primary `#5354AD`) and the Material 3 type, shape and spacing scales, with two bundled typefaces.

The Flutter code is the source of truth for values: `lib/common/app_themes.dart` (color schemes and text theme), `lib/common/app_themes.dart` (holiday colors), `lib/common/app_dimensions.dart` (spacing, corners, sizes) and `lib/common/app_config.dart` (font families). Token names here match the Material 3 role names used there.

## Voice and content

The app is about remembering people who have died. Write calmly and respectfully.

- Vietnamese is the primary language; every label must also fit in English.
- Name things the way families say them: "Ngày giỗ", "âm lịch", "mất vào tháng nhuận", "mùng 1", "rằm".
- Lunar date first, solar date second: "10 tháng 4 âm lịch", then "Thứ Sáu, 06/11/2026".
- Countdown in plain words: "còn 12 ngày", and "Hôm nay" on the day itself.
- Deleting: say what happens without drama. "Xoá ngày giỗ của Bà nội?" / "Ngày giỗ và lời nhắc sẽ không còn hiện trong ứng dụng."
- No exclamation marks, no celebration, no emoji.
- Dates in mockups are illustrative; the app computes real dates with its lunar engine.

## Naming and aliases

Token names are the Material 3 role names, because they are the field names of Flutter's `ColorScheme` and `TextTheme`: a token named here is the same name in code, with no mapping layer. The team naming convention `[system].[category].[variant].[state]` is listed as an alias only: names map to M3 roles, and every value follows Material 3.

| Convention alias             | Token                                                                       | Flutter                                                |
|------------------------------|-----------------------------------------------------------------------------|--------------------------------------------------------|
| `color.brand.primary`        | `primary`                                                                   | `colorScheme.primary`                                  |
| `color.brand.secondary`      | `secondary`                                                                 | `colorScheme.secondary`                                |
| `color.feedback.success`     | `feedback-success` / `on-feedback-success`                                  | `context.notifyColorScheme.success` / `.onSuccess`     |
| `color.feedback.warning`     | `feedback-warning` / `on-feedback-warning`                                  | `context.notifyColorScheme.warning` / `.onWarning`     |
| `color.feedback.info`        | `feedback-info` / `on-feedback-info`                                        | `context.notifyColorScheme.info` / `.onInfo`           |
| `color.feedback.error`       | `error` (validation, Delete); `feedback-error` (notices)                    | `colorScheme.error`; `context.notifyColorScheme.error` |
| `color.neutral.background`   | `surface`                                                                   | `colorScheme.surface`                                  |
| `color.neutral.surface`      | `surface-container-low` (cards), `surface-container-high` (dialogs, sheets) | `colorScheme.surfaceContainerLow` / `High`             |
| `color.neutral.border`       | `outline-variant` (decorative), `outline` (fields)                          | `colorScheme.outlineVariant` / `outline`               |
| `color.text.primary`         | `on-surface`                                                                | `colorScheme.onSurface`                                |
| `color.text.secondary`       | `on-surface-variant`                                                        | `colorScheme.onSurfaceVariant`                         |
| `color.calendar.anniversary` | `anniversary-mark`                                                          | `colorScheme.primary`                                  |
| `color.calendar.holiday`     | `holiday-mark`, `holiday-container`, `on-holiday-container`                 | `context.calendarColors`                               |

| Convention alias        | Token             | Size / line | Font           |
|-------------------------|-------------------|-------------|----------------|
| `typography.heading.xl` | `headline-medium` | 28 / 36     | Lora           |
| `typography.heading.lg` | `headline-small`  | 24 / 32     | Lora           |
| `typography.heading.md` | `title-large`     | 22 / 28     | Lora           |
| `typography.heading.sm` | `title-medium`    | 16 / 24     | Lora           |
| `typography.body.xl`    | `body-large`      | 16 / 24     | Be Vietnam Pro |
| `typography.body.lg`    | `body-medium`     | 14 / 20     | Be Vietnam Pro |
| `typography.body.md`    | `body-small`      | 12 / 16     | Be Vietnam Pro |
| `typography.label.lg`   | `label-large`     | 14 / 20     | Be Vietnam Pro |
| `typography.caption.sm` | `label-medium`    | 12 / 16     | Be Vietnam Pro |

## Color

Light and Dark come from the Theme Builder export at standard contrast. The export also has medium and high contrast schemes; the app ships all six and Android picks them with the system contrast setting.

- `surface` is the page; cards sit on `surface-container-low` with an `outline-variant` border.
- Text is `on-surface`; secondary lines (dates, helper text) are `on-surface-variant`.
- `primary` is for the one main action on a screen (the add FAB, Save) and for anniversary marks.
- An anniversary that falls today uses `today-container` (tertiary-container) with `on-today-container` text and `on-today-container-variant` for secondary lines, plus the "Hôm nay" chip. Both text colors are the tertiary "fixed" roles, so they read on the beige in light and dark. Never signal "today" by color alone.
- `error` is only for validation messages and Delete.
- Notices (snackbar, flushbar) use the `feedback-*` pairs: success, warning, info and error, each a container plus its `on-` color. They live in the `NotifyColorExtension` theme extension (`context.notifyColorScheme`).
- `holiday-mark` (red) marks mùng 1, rằm and Tết on the calendar; `anniversary-mark` (primary) marks anniversaries. Holiday items use `holiday-container`. These three have no ColorScheme role; in Flutter they live in the `CalendarColorExtension` theme extension (`context.calendarColors`).
- Body text meets 4.5:1 on its background in both themes (checked: `on-surface-variant` on `surface` 8.9:1 light, 10.9:1 dark).

## Typography

Two bundled families, so text renders offline with every Vietnamese diacritic:

- **Lora** (`--font-display`) for Display, Headline and Title roles: screen titles, the person's name on a card, dialog titles. It gives names the weight of an inscription.
- **Be Vietnam Pro** (`--font-body`) for Body and Label roles: dates, form text, buttons, navigation.

Sizes follow the Material 3 type scale exactly. Users who need larger text raise the system font size; every screen must reflow, never clip, at 200%.

## Shape and spacing

- Material 3 4 dp grid: `space-4`, `space-8`, `space-12`, `space-16`, `space-24`, `space-32`. Every padding, margin and gap is one of these; component sizes follow the M3 component specs. Screen margin on phones (compact width) is `space-16`.
- Material 3 corners: text fields `corner-extra-small`, chips `corner-small`, cards `corner-medium`, FAB `corner-large`, dialogs `corner-extra-large`, buttons and switches `corner-full`.
- Every tappable element is at least `touch-target` (48 dp).

## Layout and safe areas

- Every screen sits in a `SafeArea` for the status bar, display cutouts and the gesture bar. Nothing tappable is placed in a system inset.
- Scrolling content runs edge to edge under the gesture bar, with bottom padding = bottom inset + the height of anything pinned over it (FAB 56 + 16, or the Save bar). The last item can always scroll clear.
- Pinned controls (FAB, Save bar) sit above the bottom inset: the FAB keeps the M3 16 dp margin from the end edge and from the bottom inset.
- The keyboard pushes the form up (`resizeToAvoidBottomInset`); the focused field stays visible.
- Resizing: bars and cards fill the width and hug their content height; lists fill the remaining height and scroll; the drawer is fixed at 316 dp; calendar columns are equal fractions of the width. Every screen is checked at 360 dp wide and at 200 % text size.

## States

Interactive components use Material 3 state layers (decided by Fox on 2026-11-11), which Flutter draws by default. A state layer is the component's content color (`on-*`) laid over it at a fixed opacity, so it works in light and dark.

| State    | Visual                                                                                          | Behavior                                                |
|----------|-------------------------------------------------------------------------------------------------|---------------------------------------------------------|
| Default  | As designed                                                                                     | Accepts input                                           |
| Hovered  | State layer 8 %                                                                                 | Pointer devices only                                    |
| Pressed  | State layer 10 % plus ripple                                                                    | Starts on touch down                                    |
| Focused  | State layer 10 %; text fields get a 2 dp `primary` outline and `primary` label                  | Keyboard or screen-reader focus                         |
| Dragged  | State layer 16 %                                                                                | Swiped calendar items                                   |
| Selected | `secondary-container` fill (segments, drawer item, chips)                                       |                                                         |
| Disabled | Content at 38 % opacity, container at 12 % `on-surface`; no state layer                         | Ignores taps; still announced as "disabled"             |
| Loading  | Label and icon hidden, a 20 dp circular indicator in the content color; same size as the button | Taps ignored until the save finishes (no double submit) |

Each component card lists which of these states it has.

## Elevation

Material 3 shows depth mainly with color, not shadow: the higher a surface, the higher its `surface-container` step (low for cards and the navigation drawer, high for dialogs and the drawer's today card). Shadows (`elevation-level-0` to `elevation-level-5`) appear only where the M3 component has one:

| Level | dp | Evermoon uses it for                                                        |
|-------|----|-----------------------------------------------------------------------------|
| 0     | 0  | Anniversary cards (outlined), app bar at rest                               |
| 1     | 1  | Modal bottom sheets, the modal navigation drawer                            |
| 2     | 3  | App bar while the list scrolls under it (color change to surface-container) |
| 3     | 6  | The add FAB, dialogs, snackbars                                             |
| 4     | 8  | FAB hovered or focused                                                      |
| 5     | 12 | Not used                                                                    |

In Flutter, keep the M3 component defaults; custom surfaces use `AppElevation` and `AppShadows.level3`.

## Iconography

Material Icons (outlined) from Flutter. The app icon is the E8 mark (see the Logos group). A crescent moon marks the anniversaries destination; a calendar marks the calendar destination; a gear marks settings. Icons are 24 dp and take the color of their label.

## Layout of the app

Three destinations: Ngày giỗ (upcoming list), Lịch (calendar with a Năm / Tháng / Tuần switch), Cài đặt. They are reached through a modal NavigationDrawer opened from the menu button in TopAppBarMenu (plan 0005 D13). There is no bottom navigation bar. The add action is a FAB on the list and on the calendar (the calendar pre-fills the selected day). Forms open as full screens with a bottom Save button; the reminder block is ReminderFields. Settings is a list of SettingsSection cards with SegmentedButton for language and theme.

## Components

See the component cards: AnniversaryCard, LeapMonthToggle, ReminderFields, LunarDayCell, ViewSwitch, NavigationDrawer, TopAppBarMenu, AddFab, ConfirmDialog, EmptyState, SegmentedButton, SettingsSection, CalendarEventItem. Each card says what the Flutter widget must provide.
