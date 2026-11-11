# Plan 0005: Anniversary screens (upcoming list, add/edit, calendar tab)

Status: Design phase (2026-11-06; revised 2026-11-11 after the prototype review). Visual design is made first as a Claude Design canvas (snapshot in `docs/design/canvas-drawer/`, index in `docs/design/README.md`); Flutter implementation starts after Fox approves the design. Requirements owner: Fox. Tracker: pending.

## Outcome

Fox can open the app, see his anniversaries ordered by the next occurrence with a countdown, add, edit or delete one, see them on a calendar by year, month or week, and change language, theme and notification preferences in Settings. This replaces the template Home tab. Scheduling the notifications themselves (A4) comes in a later plan; this plan stores the reminder settings they will use.

## Scope

In:
- Upcoming list (Home tab): every live anniversary, sorted by `AnniversaryResolver.nextOccurrence`, showing name, lunar date, solar date with weekday, and days left. Today's anniversaries are highlighted.
- Empty state with a clear first action.
- Add and edit form: name (required), lunar day 1 to 30 and month 1 to 12 (required), death year (optional, never required), "died in the leap month" toggle shown only when `canBeLeapMonth` is true, reminder on/off, remind days before (0, 1, 3 or 7; 0 means on the day), reminder time (default 07:00), address (optional), note (optional). Every event repeats yearly on its lunar date; there is no one-off event and no repeat option.
- Add entry points: the FAB and the empty-state button on the list, and a FAB on the calendar; all open the same empty form (D12).
- Delete with confirmation; soft delete through the repository.
- Calendar tab with a Year / Month / Week switch: year shows 12 month tiles with the anniversary count; month shows a solar grid with the lunar day under each date, mùng 1 and rằm marked, anniversary days dotted, and the month's anniversaries below; week shows seven day rows with lunar dates and anniversaries. Merged into this plan by Fox on 2026-11-06.
- Three destinations: Ngày giỗ, Lịch, Cài đặt, in a modal navigation drawer (`docs/design/canvas-drawer/`, style A) opened from a menu button in the top app bar. The drawer header shows the E8 mark, the app name and a "today" card with the lunar date. No Terms/Privacy section in the drawer; those links live in Settings. The bottom-bar design is kept for reference only.
- The upcoming list (home) is read-only: no edit or delete there.
- Calendar, month view: tap a day to list its events under the grid. Anniversaries swipe right-to-left to reveal Sửa (edit form) and left-to-right to reveal Xoá (confirm dialog, then soft delete). Holidays are not editable. Week view: same items inside each day row. Year view: no item actions; tapping a month opens the month view.
- Calendar marks: anniversaries in `primary` (purple dot); mùng 1, rằm and Tết festivals in `holiday-mark` (red dot, red lunar number on 1 and 15), with a legend. Holiday items in the day list use `holiday-container`. Year tiles show the anniversary count and, only when the month has a named festival, the festival count; plain mùng 1 and rằm are not counted. Tiles have a fixed height with reserved lines so the grid stays aligned.
- Settings page: language (Tiếng Việt / English, applied immediately), theme (System / Light / Dark), notification permission state with a way to grant it (D18), notification sound and vibrate, on/off toggles for mùng 1, rằm and Tết, and an About section (terms, privacy, version). Reminder time and days before are set per event, not here.
- First launch: splash (Android 12+ SplashScreen API: surface background, the adaptive icon in a 160 dp circle, no text; the icon animates as an AnimatedVectorDrawable of at most 1000 ms, still under reduced motion), three intro screens (one picture, a few-word title and one short line each: lunar dates, reminders, holidays; skippable), then a screen that explains notifications before the system permission dialog, then the empty list. Later launches go splash → upcoming list. Design: `docs/design/canvas-drawer/`, page "Flow: Mở app".
- Vietnamese first, English second (ARB keys in both).

Out:
- Scheduling notifications (A4, next plan). This plan asks for the notification permission (U7 explanation screen, U6 Settings row, D18) and stores the per-event reminder settings and the Settings preferences.
- Delivering system-event reminders (mùng 1, rằm, Tết): the Settings toggles are stored here, A4 schedules them.
- One-off (non-repeating) events, share card, login, groups.

## Decisions

| ID  | Decision                                                                                                                                                                                                                                     | State                               |
|-----|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------|
| D1  | Visual design is produced as a Claude Design artifact before any widget code                                                                                                                                                                 | Decided by Fox                      |
| D2  | The design brief lives in `docs/design/`; the approved design link and any exported spec are recorded there too                                                                                                                              | Decided                             |
| D3  | Each page owns a Cubit with sealed Equatable states (`Loading`, `Empty`, `Loaded`, `Failure`); data comes from `anniversaryRepository.watchAll()`                                                                                            | Decided                             |
| D4  | The form validates in the Cubit; the leap toggle visibility comes from `AnniversaryResolver.canBeLeapMonth`                                                                                                                                  | Decided                             |
| D5  | Routes: `anniversaryNew` and `anniversaryEdit/:id`, added to `Routers` first, then `router_config.dart`                                                                                                                                      | Decided                             |
| D6  | Colors, spacing and type come from the approved design, added to `AppColors`, `AppDimensions` and the theme; no hardcoded values in widgets                                                                                                  | Decided                             |
| D7  | Theme: Fox's Material Theme Builder colors (primary #5354AD, six schemes); M3 type, shape and spacing scales; Lora for display, headline and title, Be Vietnam Pro for body and label; fonts bundled in `assets/fonts` (no runtime download) | Decided by Fox 2026-11-06           |
| D8  | Calendar tab is part of this plan (slice U5), not a later plan                                                                                                                                                                               | Decided by Fox 2026-11-06           |
| D9  | Reminders are per event: on/off, days before (0, 1, 3, 7) and time of day. Replaces the earlier "exact day only" rule for v1                                                                                                                 | Decided by Fox 2026-11-11           |
| D10 | Events always repeat yearly; no repeat option, so the death year stays optional                                                                                                                                                              | Decided by Fox 2026-11-11           |
| D11 | Events gain an optional address; note stays optional                                                                                                                                                                                         | Decided by Fox 2026-11-11           |
| D12 | Add from the list and from the calendar; both open an empty form (no pre-filled lunar day or month)                                                                                                                                         | Decided by Fox 2026-11-11           |
| D13 | Navigation: modal drawer (style A), not the bottom bar                                                                                                                                                                                       | Decided by Fox 2026-11-11           |
| D15 | Edit and delete happen from the calendar (month and week views) by swipe; the home list is read-only; year view opens a month                                                                                                                | Decided by Fox 2026-11-11           |
| D16 | Holidays (mùng 1, rằm, Tết) are marked in red, anniversaries in purple; year tiles count named festivals only                                                                                                                                | Decided by Fox 2026-11-11           |
| D18 | Onboarding shown once (flag in `AppPreference`); the notification permission is asked from the explanation screen, never on cold start without context. Settings also shows a Notifications row with the permission state; tapping it asks again, or opens the system app settings when Android no longer shows the dialog, because reminders are the reason the app exists | Decided by Fox 2026-11-11           |
| D17 | Swipe actions also exposed as accessibility actions (Sửa, Xoá) so they work without a gesture                                                                                                                                                | Decided by Fox 2026-11-11           |
| D14 | Settings holds language, theme, sound, vibrate, system-event toggles and About; the drawer or tab bar has no separate legal section                                                                                                          | Decided by Fox 2026-11-11           |

## Acceptance criteria

- UI-1: The list is ordered by next occurrence; ties by name. Each row shows lunar date, solar date with weekday, and days left ("Hôm nay" for today).
- UI-2: An empty database shows the empty state with an "add" action.
- UI-3: Saving a valid form creates or updates the record and returns to the list, which updates without a manual refresh.
- UI-4: The form rejects an empty name, a day outside 1 to 30 and a month outside 1 to 12, with messages from ARB.
- UI-5: The leap toggle appears only when the death year has a leap month with the selected number; changing year or month away from that case hides it and clears the flag.
- UI-6: Delete asks for confirmation and removes the record from the list.
- UI-7: Every user-visible string comes from `S.of(context)` in both `vi` and `en`.
- UI-8: Widget tests cover the list (empty and loaded), the form validation and the leap toggle rule, with a fake repository and a fake lunar calendar.
- UI-10: The form stores days before and reminder time with the event; turning the reminder off hides both; address and note may be empty.
- UI-11: "Add" on the calendar opens the same empty form as "Add" on the list (D12).
- UI-16: Settings shows whether notifications are allowed; tapping the row asks for the permission, or opens the system app settings when the dialog can no longer be shown (D18).
- UI-12: Switching language or theme in Settings applies to the whole app at once and survives a restart (stored through `AppCubit`).
- UI-13: In the month view, swiping an anniversary left opens edit and swiping right asks to confirm delete; holiday items do not move. TalkBack offers the same two actions.
- UI-14: Month grid shows a purple dot for anniversaries and a red dot plus red lunar number for mùng 1, rằm and Tết; the year grid keeps every tile the same height.
- UI-15: On first launch the intro appears once; Bỏ qua and Bắt đầu both lead to the notification screen; Cho phép triggers the system dialog, Để sau does not; the next launch opens the list directly.
- UI-9: The calendar switches between year, month and week; each view navigates to the previous and next period; anniversaries appear on the dates the resolver returns; lunar days come from `LunarCalendarService`.
- ST-8 (U2a): A fresh database is at schema version 2; a new anniversary defaults to reminder on, 0 days before, 07:00 (minute 420) and no address.
- ST-9 (U2a): Opening a version 1 database migrates it to version 2 and keeps every row and field; migrated rows get 0 days before, 07:00 and no address.
- ST-10 (U2a): The repository creates, updates and reads back days before, reminder time and address.
- ST-11 (U2a): The table rejects days before outside 0 to 30 and a reminder minute outside 0 to 1439.

## Slices

| Slice | Content                                                                                                                                                                 | Status                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
|-------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| U0    | Design brief and Claude Design artifact; Fox reviews and approves                                                                                                       | In progress                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| U1    | Theme tokens from the design (`AppColors`, `AppDimensions`, text styles)                                                                                                | Done 2026-11-06: Fox's six color schemes and the two bundled fonts in `app_themes.dart` (Montserrat removed; Lora static instances cut from the official variable font, Vietnamese coverage checked); M3 spacing, corner and component sizes in `app_dimensions.dart`; design system artifact "Evermoon" (https://claude.ai/artifact/9Qdv5AXSe6fDrSGsnMjhip) mirrors the same tokens; `fvm flutter analyze` clean, `test/common/app_themes_test.dart` passes |
| U2    | Upcoming list page, Cubit, states, empty state, widget tests                                                                                                            | Done 2026-11-11: `lib/pages/anniversary_list/` replaces the template Home (deleted with `empty_widget`); read-only cards per the design system; countdowns refresh at local midnight and on resume; `AnniversaryResolver.nextHolding` (AR-8). UI-1, UI-7, UI-8 met; UI-2 partly: the add button and FAB appear once U3/U4 pass `onAdd`. Not yet run on a device (U4). `fvm flutter analyze` clean, tests pass |
| U2a   | Schema v2: add `remindDaysBefore` (0 to 30), `remindMinuteOfDay` (0 to 1439, default 420) and `address` to `Anniversaries`, with a Drift migration and repository tests | Done 2026-11-11: schema v2 with step-by-step migration (`drift_schemas/`, `app_database.steps.dart`), model and repository fields, ST-8 to ST-11 plus the generated migration tests; drift and drift_dev moved to 2.35.x. `fvm flutter analyze` clean, 48 tests pass                                                                                                                                                                                         |
| U3    | Add/edit page, Cubit, validation, leap toggle, reminder fields, address, delete, widget tests                                                                           | Done 2026-11-11: `lib/pages/anniversary_form/` (draft, Cubit, page, widgets) and the shared delete dialog; the Cubit rejects lead times other than 0/1/3/7 and clears the leap answer whenever it cannot apply; no reminder summary when the lead time reaches before today. UI-3 to UI-7, UI-10 met on the page with fakes; reaching the form from the app comes with U4. `fvm flutter analyze` clean, 87 tests pass |
| U4    | Routes, drawer shell (three destinations, header with today's lunar date), ARB keys, run on device                                                                      | Done 2026-11-11 except the device run: modal `NavigationDrawer` (mark, today card, today count badge) replaces the bottom bar; `ShellScope` gives each page a menu button; route `anniversaryNew` (`/home/new`) opens the form from the FAB and the empty state, so UI-2 is now met. The Lịch destination and the edit route (`anniversaryEdit`, under the calendar per D15) arrive with the calendar in U5. No test drives the real router (the global repository needs the device database), so navigation is checked on the device run. Not run on a device yet: no Android device was connected and the Mac had under 5 GB free. `fvm flutter analyze` clean, 93 tests pass |
| U5    | Calendar: year, month and week views, day event list, swipe edit/delete with confirm, holiday marks, add (empty form, D12), Cubit, widget tests                         | Done 2026-11-11: `lib/pages/calendar/` (pure `CalendarBuilder`, Cubit, year/month/week views), `LunarHoliday` and `LunarFestival` in `lib/services/lunar/lunar_holidays.dart`, drawer destination Lịch, routes `calendarNew` and `anniversaryEdit`; swipe left edits, swipe right confirms and deletes, the same two as TalkBack actions (D17); an ARB key test (no duplicate keys, same keys in vi and en). UI-9, UI-11, UI-13, UI-14 met with fakes; "today" refreshes on resume; the lunar number is red on every holiday (mùng 1, rằm and festivals), a reading of UI-14 for Fox to confirm. Day 1 of a leap month shows "1/N" like the regular month (the spoken label says "nhuận"). Not run on a device. `fvm flutter analyze` clean, 117 tests pass |
| U7    | Splash (native SplashScreen theme for dev and prod, no extra package), intro pages, notification explanation and permission request, first-run flag, widget tests       | Not started                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| U6    | Settings page: language, theme, sound, vibrate, system-event toggles, About; preferences in `AppCubit` / `AppPreference`                                                | Not started                                                                                                                                                                                                                                                                                                                                                                                                                                                  |

## Verification

```bash
fvm dart run build_runner build
fvm flutter gen-l10n
fvm flutter analyze
fvm flutter test
fvm flutter run --flavor dev -t lib/main_dev.dart
```

Claude runs these on Fox's Mac (access granted 2026-11-06) and Fox checks the screens on the device.

## Risks

- Festival list (U5): Tết Nguyên Đán 1/1, Nguyên Tiêu 15/1, Hàn Thực 3/3, Đoan Ngọ 5/5, Trung Nguyên 15/7, Trung Thu 15/8, Táo Quân 23/12, taken from the fixed-date Tết days in viettimes.vn "Mỗi năm người Việt có bao nhiêu ngày Tết?". Thanh Minh (solar term) and the minor ones in that article (Khai Hạ, Trùng Cửu, Trùng Thập, Hạ Nguyên) and Giỗ Tổ Hùng Vương are not included. Fox confirms with the family; the list lives only in `LunarFestival`.

- The table accepts 0 to 30 days before; only the form limits the choice to 0, 1, 3 and 7 (D9). U3 must not offer other values, and the Cubit must reject them.
- U2a changes the schema of a table that may already hold Fox's test data: the migration must keep existing rows (defaults: remind on the day at 07:00, no address).
- The design may suggest features outside this plan (sharing). Those stay out of scope and go to later plans.
- The month view needs a lunar date for every visible day (up to 42 per month); the engine caches by lunar year, so this stays cheap, but measure on the Pixel 5.
- `nextOccurrence` computes on first use per lunar year; with 10 to 30 records this is small, but measure the list's first build on the Pixel 5.
