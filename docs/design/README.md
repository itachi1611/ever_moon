# Design

Reference copies of the Evermoon design work. The live versions are claude.ai artifacts (private to Fox); the files here are snapshots so the repo can be read without them. When an artifact changes, refresh its folder here.

| Folder                      | Live artifact                                                                                                         | Content                                                                                                                                                                                                                     |
|-----------------------------|-----------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Archive (not in the repo) | [Evermoon - Archive](https://claude.ai/artifact/39ApKCniceucNsHaRtTSRU) | The rejected bottom-bar design and the launcher icon concept rounds, kept only as a claude.ai artifact. |
| `canvas-drawer/`            | [Evermoon - Drawer](https://claude.ai/artifact/Pq8coHhsqucU35MKdPkG4U)                                                | The design being built. Pages: Foundations, Flow: Mở app, Flow: Ngày giỗ, Flow: Lịch, Flow: Cài đặt (each light and dark, plus 360 dp checks), Archive (drawer styles B and C). Screen index below.                         |
| `design-system/`            | [Evermoon design system](https://claude.ai/artifact/9Qdv5AXSe6fDrSGsnMjhip)                                           | `tokens.json` (colors, type, spacing, shape, elevation), `README.md`, component specs and previews, logo notes. Fonts are not copied: they live in `assets/fonts/`.                                                         |
| `icon/`                     | —                                                                                                                     | Masters of the launcher icon E8 (torn lunar calendar page with a reversed crescent, chosen 2026-11-11): app icon (prod, dev), mark, monochrome, 512 px previews.             |
| `tools/` | — | Python 3 scripts, run from the repo root (`python3 docs/design/tools/audit.py`). `audit.py` lists anything in `canvas-drawer/` that is off the design system; `normalize.py` re-applies M3 spacing, corners, type and color tokens; `calendar.py`, `onboarding.py` and `drawer_header.py` regenerate those artboards. They write to `canvas-drawer/`; publish the result to the live canvas afterwards. |

## Files

- `*.dc.html` are canvas artboard sources (390 × 844 phone frames, inline styles, `{{value}}` holes filled by the script at the bottom of each file). They need the canvas runtime to render, so view them through the live artifact; read the files for exact values (colors, spacing, copy). A file named `XDark` is the dark version of `X`.
- `canvas.json` holds the board positions, titles and notes of each canvas.
- All names and dates shown are illustrative placeholders, not computed lunar dates.

## Open decisions

- Navigation: decided 2026-11-11, the app uses the drawer (`canvas-drawer/`). The bottom-bar design lives only in the Archive artifact.

## Screen index (canvas-drawer)

| Page           | Screen (light / dark)                         | What it shows                                                                                                |
|----------------|-----------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| Flow: Mở app   | `Splash` / `SplashDark`                       | Android 12+ splash: icon only, animated (pop in, crescent turns in)                                          |
|                | `Intro1`, `Intro2`, `Intro3` / `…Dark`        | First-run intro: lunar dates, reminders, holidays; Bỏ qua skips                                              |
|                | `IntroNotify` / `IntroNotifyDark`             | "Bật thông báo" before the system permission dialog                                                          |
| Flow: Ngày giỗ | `Main` / `ListDark`, `Main360`                | Upcoming list (read-only), today card, FAB                                                                   |
|                | `DrawerOpen` / `DrawerOpenDark`               | Navigation drawer: E8 mark, today's lunar date, three destinations                                           |
|                | `ListEmpty` / `ListEmptyDark`                 | First run with no data                                                                                       |
|                | `FormNew` / `FormDark`                        | Add: lunar day and month, optional year, leap toggle, reminder (days before, time), address, note            |
|                | `FormEdit` / `FormEditDark`                   | Edit with a validation error and Delete                                                                      |
|                | `DeleteDialog` / `DeleteDialogDark`           | Delete confirmation                                                                                          |
| Flow: Lịch     | `CalendarMonth` / `…Dark`, `CalendarMonth360` | Month grid with purple (anniversary) and red (holiday) marks; tap a day; swipe left to edit, right to delete |
|                | `CalendarWeek` / `…Dark`                      | Week rows with the same swipeable items                                                                      |
|                | `CalendarYear` / `…Dark`                      | Year tiles (anniversary and festival counts); tap opens the month                                            |
| Flow: Cài đặt  | `Settings` / `SettingsDark`                   | Language, theme, sound, vibrate, holiday toggles, about                                                      |
| Foundations    | `Tokens`                                      | Quick visual check of the tokens                                                                             |

To get pictures for offline reading, export the canvas pages (Share › Export) into `docs/design/exports/`.
